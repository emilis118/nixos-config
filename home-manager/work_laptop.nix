# Single internal display: same workspace layout as work_pc but without
# pinning workspaces to external outputs (HDMI-2/DP-3). When docked, external
# monitors are picked up automatically.
{
  imports = [
    ./roles/work.nix
    ./features/laptop.nix
  ];

  xsession.windowManager.i3.config.startup = [
    {command = "i3-msg 'workspace $ws10; exec firefox -new-window outlook.office.com/mail/'";}
  ];
}
