// Electron main process for the naruto-arena.site wrapper. The game is a
// Next.js app on their server, so this window is a client and nothing more —
// there is no offline mode to add.
const {app, BrowserWindow, session, shell} = require("electron");

const GAME_URL = "https://naruto-arena.site/ingame";

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

// Hitting alt+d twice should focus the window that's already up rather than
// start a second client on the same account.
if (!app.requestSingleInstanceLock()) {
  app.quit();
}

let win = null;

function createWindow() {
  session.defaultSession.webRequest.onBeforeRequest({urls: BLOCKED}, (_details, callback) =>
    callback({cancel: true}),
  );

  win = new BrowserWindow({
    width: 1280,
    height: 860,
    autoHideMenuBar: true, // alt still reveals it; F11 and ctrl+r come from there
    backgroundColor: "#000000", // no white flash while the app boots
    webPreferences: {
      // remote code we don't control — keep node out of its reach
      nodeIntegration: false,
      contextIsolation: true,
    },
  });

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
