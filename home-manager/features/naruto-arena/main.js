// Electron main process for the naruto-arena.site wrapper. The game is a
// Next.js app on their server, so this window is a client and nothing more —
// there is no offline mode to add.
const {app, BrowserWindow, screen, session, shell} = require("electron");
const fs = require("fs");
const path = require("path");

const GAME_URL = "https://naruto-arena.site/ingame";

// The stage is a fixed 770x560 pinned to the top left of the viewport (their
// ._level0, which their js hard-sets to 770px) and nothing on the page
// reflows, so a bigger window only adds black padding around the game.
const WIDTH = 770;
const HEIGHT = 560;
const GAP = 10; // between two windows sitting side by side

// Ad and analytics hosts the page pulls in. Cancelling them at the session
// level is the one thing a plain browser tab can't do without an extension;
// the game itself never talks to any of them.
const BLOCKED = [
  "*://*.googlesyndication.com/*",
  "*://*.googletagmanager.com/*",
  "*://*.google-analytics.com/*",
  "*://*.doubleclick.net/*",
  "*://waust.at/*",
];

// One cookie jar per profile — that's what running two accounts at once used
// to need two different browsers for. `default` keeps the userData directory
// it has always had so an existing login survives; named profiles nest under
// it as profiles/<name>.
const USER_DATA_ROOT = app.getPath("userData");

const profile = (() => {
  const flag = process.argv.find((arg) => arg.startsWith("--profile="));
  const name = flag ? flag.slice("--profile=".length) : "default";
  // the name becomes a path component, so keep it boring
  return /^[A-Za-z0-9._-]+$/.test(name) ? name : "default";
})();

if (profile !== "default") {
  app.setPath("userData", path.join(USER_DATA_ROOT, "profiles", profile));
}

// Electron keys the single-instance lock on the userData directory, so this
// still stops alt+d from opening a second client on the same account, while
// leaving a different profile free to run alongside it.
if (!app.requestSingleInstanceLock()) {
  app.quit();
}

let win = null;

// i3 honours the position a floating window asks for (see the for_window rule
// in features/i3-profile.nix), so each profile can claim a slot and two of
// them land next to each other instead of stacked in the middle of the
// screen. Order is `default` first, then the named profiles alphabetically,
// so an account always comes back to the same side.
function slot() {
  if (profile === "default") return 0;
  const dir = path.join(USER_DATA_ROOT, "profiles");
  fs.mkdirSync(dir, {recursive: true});
  return fs.readdirSync(dir).sort().indexOf(profile) + 1;
}

function position() {
  const {workArea} = screen.getPrimaryDisplay();
  const pairLeft = workArea.x + Math.round((workArea.width - (2 * WIDTH + GAP)) / 2);
  return {
    // a third profile has nowhere left to go; park it against the right edge
    x: Math.max(
      workArea.x,
      Math.min(pairLeft + slot() * (WIDTH + GAP), workArea.x + workArea.width - WIDTH),
    ),
    y: Math.max(workArea.y, workArea.y + Math.round((workArea.height - HEIGHT) / 2)),
  };
}

function createWindow() {
  session.defaultSession.webRequest.onBeforeRequest({urls: BLOCKED}, (_details, callback) =>
    callback({cancel: true}),
  );

  win = new BrowserWindow({
    ...position(),
    width: WIDTH,
    height: HEIGHT,
    useContentSize: true, // WIDTH/HEIGHT are the page, not the page plus frame
    autoHideMenuBar: true, // alt still reveals it; F11 and ctrl+r come from there
    backgroundColor: "#000000", // no white flash while the app boots
    webPreferences: {
      // remote code we don't control — keep node out of its reach
      nodeIntegration: false,
      contextIsolation: true,
    },
  });

  // The page's title is identical for every profile, and i3's titlebar is the
  // only place two clients can be told apart, so keep ours instead.
  win.on("page-title-updated", (event) => event.preventDefault());
  win.setTitle(profile === "default" ? "Naruto Arena" : `Naruto Arena (${profile})`);

  win.loadURL(GAME_URL);

  // target=_blank links (forum, discord invite) belong in firefox, not in a
  // second chrome-less window with no way back.
  win.webContents.setWindowOpenHandler(({url}) => {
    shell.openExternal(url);
    return {action: "deny"};
  });
}

app.on("second-instance", () => {
  if (!win) return;
  if (win.isMinimized()) win.restore();
  win.focus();
});

app.whenReady().then(createWindow);
app.on("window-all-closed", () => app.quit());
