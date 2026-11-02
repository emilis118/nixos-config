# What both CERN machines (work_pc, work_laptop) get on top of ./global: the
# i3 session, the lab/remote tooling and the office apps. A host imports this
# and adds only what sets it apart — monitor layout, polybar toggles, an extra
# app or two.
{
  imports = [
    ../global
    ../features/qemu.nix
    ../features/wallpaper.nix
    ../features/i3.nix
    ../features/remote.nix
    ../features/onlyoffice.nix
    ../features/mattermost.nix
    ../features/flameshot.nix
    ../features/whatsapp.nix
    ../features/thunderbird.nix
    ../features/cern-dfs.nix
    ../features/bambu-studio.nix
    ../features/crafts.nix
  ];

  # workspace names / window assignments live in features/i3-profile.nix
  i3Profile.work = true;

  # off while the beam is down (LS3); flip when the LHC is back
  polybarModules.lhc = false;
}
