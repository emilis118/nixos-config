#!/usr/bin/env python3
"""Poll Outlook (IMAP + OAuth) for [Public Marketplace] mails and notify via
dunst about brand-new topics (replies ignored), with price + snippet extracted
from the body. Triggering the notification action opens the ad ("Visit Topic"
link, or Outlook Web).

Run via the `marketplace-check` wrapper (installed by the home-manager module);
first run on a machine does an interactive device-code login."""

import email
import html
import imaplib
import json
import os
import re
import subprocess
import sys
import threading
from email.header import decode_header, make_header
from pathlib import Path

import msal

STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "marketplace-notifications"
CONFIG_FILE = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "marketplace-notifications/config.json"
TOKEN_CACHE_FILE = STATE_DIR / "token_cache.json"
SEEN_FILE = STATE_DIR / "seen.json"

IMAP_HOST = "outlook.office365.com"
SCOPES = ["https://outlook.office.com/IMAP.AccessAsUser.All"]
TAG = "[Public Marketplace]"
FOLDER = "Marketplace"
FETCH_COUNT = 50
FALLBACK_URL = "https://outlook.office.com/mail/"

REPLY_RE = re.compile(r"^(re|fwd?|atsak\w*)\s*:\s*", re.IGNORECASE)
TAG_RE = re.compile(re.escape(TAG), re.IGNORECASE)
PRICE_RE = re.compile(
    r"(?:€\s*\d+(?:[.,'\s]?\d{3})*(?:[.,]\d{1,2})?"
    r"|\d+(?:[.,'\s]?\d{3})*(?:[.,]\d{1,2})?\s*(?:€|euros?\b|eur\b|chf\b))",
    re.IGNORECASE,
)
MD_IMAGE_RE = re.compile(r"!\[[^\]]*\]\([^)]*\)")
URL_RE = re.compile(r"https?://[^\s<>\"')\]]+")
HTML_TAG_RE = re.compile(r"<(script|style)[^>]*>.*?</\1>|<[^>]+>", re.IGNORECASE | re.DOTALL)
ANCHOR_RE = re.compile(r'<a\s[^>]*href="([^"]+)"[^>]*>(.*?)</a>', re.IGNORECASE | re.DOTALL)


def load_config():
    # Default: Mozilla Thunderbird's public client — widely consented in org
    # tenants for IMAP OAuth. Override via config.json if desired.
    config = {"client_id": "9e5f94bc-e8a4-4e73-b8be-63364c29d753", "authority": "common"}
    if CONFIG_FILE.exists():
        config.update(json.loads(CONFIG_FILE.read_text()))
    return config


def get_token(config):
    """Returns (access_token, username) for IMAP XOAUTH2."""
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    cache = msal.SerializableTokenCache()
    if TOKEN_CACHE_FILE.exists():
        cache.deserialize(TOKEN_CACHE_FILE.read_text())

    app = msal.PublicClientApplication(
        config["client_id"],
        authority=f"https://login.microsoftonline.com/{config.get('authority', 'common')}",
        token_cache=cache,
    )

    result = None
    accounts = app.get_accounts()
    if accounts:
        result = app.acquire_token_silent(SCOPES, account=accounts[0])

    if not result:
        if not sys.stdin.isatty():
            # Running from the timer: can't do the interactive device flow.
            # Tell the user instead of hanging until systemd kills us.
            subprocess.run(
                ["dunstify", "-a", "marketplace", "-u", "critical",
                 "Marketplace login expired",
                 "Run marketplace-check in a terminal to log in again"],
                check=False,
            )
            sys.exit("Silent token refresh failed and no terminal for device flow.")
        flow = app.initiate_device_flow(scopes=SCOPES)
        if "user_code" not in flow:
            sys.exit(f"Failed to start device flow: {flow}")
        print(flow["message"], flush=True)  # "go to https://microsoft.com/devicelogin ..."
        result = app.acquire_token_by_device_flow(flow)

    if "access_token" not in result:
        sys.exit(f"Auth failed: {result.get('error_description', result)}")

    if cache.has_state_changed:
        TOKEN_CACHE_FILE.write_text(cache.serialize())
        TOKEN_CACHE_FILE.chmod(0o600)

    username = app.get_accounts()[0]["username"]
    return result["access_token"], username


def decode_hdr(value):
    return str(make_header(decode_header(value))) if value else ""


def connect(token, username):
    imap = imaplib.IMAP4_SSL(IMAP_HOST)
    auth_string = f"user={username}\x01auth=Bearer {token}\x01\x01"
    try:
        imap.authenticate("XOAUTH2", lambda _: auth_string.encode())
    except imaplib.IMAP4.error as e:
        sys.exit(f"IMAP auth failed (IMAP may be disabled in your tenant): {e}")
    status, _ = imap.select(f'"{FOLDER}"', readonly=True)
    if status != "OK":
        sys.exit(f'Could not open IMAP folder "{FOLDER}"')
    return imap


def search_candidates(imap):
    """Returns matching messages oldest-first as [{'id', 'subject', 'sender'}, ...]."""
    _, data = imap.search(None, "SUBJECT", '"Public Marketplace"')
    ids = data[0].split()[-FETCH_COUNT:]

    messages = []
    for msg_id in ids:
        _, msg_data = imap.fetch(msg_id, "(BODY.PEEK[HEADER.FIELDS (SUBJECT FROM)])")
        hdr = email.message_from_bytes(msg_data[0][1])
        subject = decode_hdr(hdr["Subject"])
        if TAG.lower() not in subject.lower():
            continue
        messages.append({"id": msg_id, "subject": subject, "sender": decode_hdr(hdr["From"])})
    return messages


def fetch_body(imap, msg_id):
    """Fetch the full message; returns (plain_text, raw_html) — either may be ''."""
    _, msg_data = imap.fetch(msg_id, "(BODY.PEEK[])")
    msg = email.message_from_bytes(msg_data[0][1])

    plain, html_body = None, None
    for part in msg.walk():
        if part.get_content_maintype() == "multipart" or part.get_filename():
            continue
        charset = part.get_content_charset() or "utf-8"
        try:
            text = part.get_payload(decode=True).decode(charset, errors="replace")
        except (LookupError, AttributeError):
            continue
        if part.get_content_type() == "text/plain" and plain is None:
            plain = text
        elif part.get_content_type() == "text/html" and html_body is None:
            html_body = text

    if plain is None and html_body:
        plain = html.unescape(HTML_TAG_RE.sub(" ", html_body))
    return plain or "", html_body or ""


def extract_price(text):
    m = PRICE_RE.search(text)
    return re.sub(r"\s+", " ", m.group(0)).strip() if m else None


def extract_topic_url(text, html_body):
    """The 'Visit Topic' link at the end of every marketplace mail."""
    # HTML mails: the <a> whose anchor text is "Visit Topic"
    for href, inner in ANCHOR_RE.findall(html_body):
        if "visit topic" in HTML_TAG_RE.sub(" ", inner).casefold():
            return html.unescape(href)
    # Plain-text mails: the first URL at or after the "Visit Topic" phrase
    pos = text.casefold().find("visit topic")
    m = URL_RE.search(text, pos if pos != -1 else 0)
    return m.group(0).rstrip(".,;") if m else None


def make_snippet(text, max_len=180):
    text = MD_IMAGE_RE.sub("", text)  # Discourse image markdown is noise
    lines = [
        line.strip()
        for line in text.splitlines()
        if line.strip() and not line.strip().startswith(">")
    ]
    snippet = " ".join(lines)
    snippet = snippet.split("Visit Topic")[0]  # drop the footer
    return re.sub(r"\s+", " ", snippet)[:max_len].strip()


def topic_key(subject):
    """Normalized topic identity: tag and reply prefixes stripped, case-folded."""
    s = TAG_RE.sub("", subject).strip()
    while REPLY_RE.match(s):
        s = REPLY_RE.sub("", s, count=1).strip()
    return re.sub(r"\s+", " ", s).casefold()


def is_reply(subject):
    return bool(REPLY_RE.match(TAG_RE.sub("", subject).strip()))


def notify_topic(title, body, url):
    """Show a clickable notification; if the default action fires, open the ad."""
    result = subprocess.run(
        ["dunstify", "-a", "marketplace", "-u", "normal", "-t", "30000",
         "-A", "default,Open", title, body],
        capture_output=True, text=True,
    )
    if result.stdout.strip() == "default":
        subprocess.run(["xdg-open", url], check=False)


def main():
    notify_empty = "--notify-empty" in sys.argv  # manual/polybar runs
    config = load_config()
    token, username = get_token(config)
    imap = connect(token, username)
    candidates = search_candidates(imap)

    first_run = not SEEN_FILE.exists()
    seen = set(json.loads(SEEN_FILE.read_text())) if not first_run else set()

    new_topics = []
    for msg in candidates:
        key = topic_key(msg["subject"])
        if not key or key in seen:
            continue
        seen.add(key)
        if not is_reply(msg["subject"]):
            new_topics.append(msg)

    # Fetch bodies only for genuinely new topics (skip on first run — no notifications)
    if not first_run:
        for msg in new_topics:
            body_text, body_html = fetch_body(imap, msg["id"])
            msg["price"] = extract_price(body_text) or extract_price(msg["subject"])
            msg["snippet"] = make_snippet(body_text)
            msg["url"] = extract_topic_url(body_text, body_html) or FALLBACK_URL
    imap.logout()

    SEEN_FILE.parent.mkdir(parents=True, exist_ok=True)
    SEEN_FILE.write_text(json.dumps(sorted(seen), indent=2))

    if first_run:
        print(f"First run: recorded {len(seen)} existing topics, no notifications sent.")
        return

    threads = []
    for msg in new_topics:  # oldest-first
        subject = TAG_RE.sub("", msg["subject"]).strip()
        title = f"{subject} — {msg['price']}" if msg["price"] else subject
        body_lines = [msg["snippet"]] if msg["snippet"] else []
        body_lines.append(f"from {msg['sender']}")
        t = threading.Thread(
            target=notify_topic, args=(title, "\n".join(body_lines), msg["url"])
        )
        t.start()
        threads.append(t)
        print(f"notified: {title}")

    # Wait for notifications to be clicked/dismissed/expired so click handlers
    # survive; bounded by the 30s notification timeout.
    for t in threads:
        t.join(timeout=35)

    if not new_topics:
        print("No new topics.")
        if notify_empty:
            subprocess.run(
                ["dunstify", "-a", "marketplace", "-u", "low", "-t", "5000",
                 "Marketplace", "No new topics"],
                check=False,
            )


if __name__ == "__main__":
    main()
