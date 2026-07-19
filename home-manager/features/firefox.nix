#  firefox.nix
{
  pkgs,
  lib,
  config,
  ...
}: let
  bookmarks = import ./bookmarks.nix;
in {
  programs.firefox.enable = true;
  # keep the pre-26.05 profile location; existing profiles live in ~/.mozilla
  programs.firefox.configPath = ".mozilla/firefox";

  # Enterprise policies: applied globally to every profile, so the existing
  # profile in ~/.mozilla is left untouched (no risk of home-manager
  # generating a new one). Inspect the result in about:policies.
  programs.firefox.policies = {
    # Ad blocking. force_installed also keeps the extension updated and
    # prevents accidental removal; use "normal_installed" instead to allow
    # disabling it from about:addons.
    ExtensionSettings = {
      "uBlock0@raymondhill.net" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        installation_mode = "force_installed";
      };
    };

    # Built-in tracker blocking on top of uBlock
    EnableTrackingProtection = {
      Value = true;
      Cryptomining = true;
      Fingerprinting = true;
    };

    # Same list as the rofi bookmarks tab, placed directly on the bookmarks
    # toolbar (ManagedBookmarks would force them into a folder). Manually
    # added bookmarks are unaffected.
    Bookmarks =
      map (b: {
        Title = b.name;
        URL = b.url;
        Placement = "toolbar";
      })
      bookmarks;
    DisplayBookmarksToolbar = "always";

    DisableTelemetry = true;
    DisableFirefoxStudies = true;
    DisablePocket = true;
    FirefoxHome = {
      SponsoredTopSites = false;
      SponsoredPocket = false;
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = ["firefox.desktop"];
    };
  };
}
