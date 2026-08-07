{
  imports = [
    ./global # default.nix
    ./features/qemu.nix
    ./features/wallpaper.nix
    ./features/i3.nix
    ./features/remote.nix
    ./features/onlyoffice.nix
    ./features/mattermost.nix
    ./features/flameshot.nix
    ./features/whatsapp.nix
    ./features/thunderbird.nix
    ./features/cern-dfs.nix
  ];

  # Single internal display: same workspace layout as work_pc but without
  # pinning workspaces to external outputs (HDMI-2/DP-3). When docked,
  # external monitors are picked up automatically.
  # Workspace names / window assignments live in features/i3-profile.nix.
  i3Profile = {
    work = true;
    laptopKeys = true;
  };

  xsession.windowManager.i3.config.startup = [
    {command = "i3-msg 'workspace $ws10; exec firefox -new-window outlook.office.com/mail/'";}
  ];

  polybarModules = {
    # off while the beam is down (LS3); flip when the LHC is back
    lhc = false;
    battery = true;
    backlight = true;
  };
}
