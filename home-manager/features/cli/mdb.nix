{
  pkgs,
  lib,
  ...
}:
with lib; let
  # GitHub-ish stylesheet, inlined into the generated file by
  # `--embed-resources` so the HTML stays a single self-contained artifact
  # (safe to scp or drop in /tmp without the CSS tagging along).
  style = pkgs.writeText "mdb.css" ''
    :root {
      color-scheme: light dark;
      --bg: #ffffff;
      --fg: #1f2328;
      --muted: #59636e;
      --border: #d1d9e0;
      --code-bg: #f6f8fa;
      --link: #0969da;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #0d1117;
        --fg: #e6edf3;
        --muted: #9198a1;
        --border: #3d444d;
        --code-bg: #161b22;
        --link: #4493f8;
      }
    }
    body {
      background: var(--bg);
      color: var(--fg);
      font-family: -apple-system, "Segoe UI", "Noto Sans", Helvetica, Arial, sans-serif;
      font-size: 16px;
      line-height: 1.6;
      margin: 0 auto;
      max-width: 900px;
      padding: 2rem 1.25rem 6rem;
    }
    h1, h2 { border-bottom: 1px solid var(--border); padding-bottom: .3em; }
    h1, h2, h3, h4 { line-height: 1.25; margin: 1.5em 0 .6em; }
    a { color: var(--link); text-decoration: none; }
    a:hover { text-decoration: underline; }
    code {
      background: var(--code-bg);
      border-radius: 6px;
      font-family: ui-monospace, "JetBrainsMono Nerd Font", monospace;
      font-size: .875em;
      padding: .2em .4em;
    }
    pre {
      background: var(--code-bg);
      border-radius: 6px;
      overflow-x: auto;
      padding: 1rem;
    }
    pre code { background: none; padding: 0; }
    blockquote {
      border-left: .25em solid var(--border);
      color: var(--muted);
      margin: 0;
      padding: 0 1em;
    }
    table { border-collapse: collapse; display: block; overflow-x: auto; }
    th, td { border: 1px solid var(--border); padding: .4rem .8rem; }
    tr:nth-child(2n) { background: var(--code-bg); }
    img { max-width: 100%; }
    hr { background: var(--border); border: 0; height: 1px; }
  '';

  mdb = pkgs.writeShellScriptBin "mdb" ''
    set -euo pipefail
    export PATH=${makeBinPath [pkgs.pandoc pkgs.coreutils pkgs.xdg-utils]}:$PATH

    if [ "$#" -eq 0 ] && [ -t 0 ]; then
      echo "usage: mdb <file.md> [...]   # or: cmd | mdb" >&2
      exit 1
    fi

    out_dir="$(mktemp -d -t mdb.XXXXXX)"

    render() {
      # --embed-resources inlines the CSS and any local images; --resource-path
      # points at the source file's directory so relative image links resolve
      # the same way they do on GitHub, not relative to the current shell.
      pandoc \
        --from=gfm \
        --to=html5 \
        --standalone \
        --embed-resources \
        --css="${style}" \
        --metadata=title="$2" \
        --resource-path="$3" \
        --output="$4" \
        "$1"
    }

    if [ "$#" -eq 0 ]; then
      target="$out_dir/stdin.html"
      render - "stdin" "$PWD" "$target"
      xdg-open "$target" >/dev/null 2>&1 &
      exit 0
    fi

    for src in "$@"; do
      if [ ! -f "$src" ]; then
        echo "mdb: no such file: $src" >&2
        exit 1
      fi
      target="$out_dir/$(basename "''${src%.*}").html"
      render "$src" "$(basename "$src")" "$(dirname "$src")" "$target"
      xdg-open "$target" >/dev/null 2>&1 &
    done
  '';
in {
  # `mdb file.md` renders markdown to a self-contained HTML file and opens it
  # in the default browser — the counterpart to `md` (glow, in glow.nix) for
  # when you want images, wide tables and real links instead of a TUI.
  home.packages = [mdb];
}
