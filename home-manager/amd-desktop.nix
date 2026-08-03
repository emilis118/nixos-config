# First-boot profile: i3 and the things it needs to be usable, nothing else.
# The rest is commented and tagged FIRST_GO — uncomment as the machine earns
# it. ./global is the shared base (terminal, editor, shell, firefox, rofi,
# dunst) and stays, since without it there is no working desktop to log into.
{
  imports = [
    ./global # default.nix
    ./features/i3.nix
    ./features/sound.nix
    ./features/wallpaper.nix
    # FIRST_GO: everything below is an application, not part of the desktop.
    # ./features/discord.nix
    # ./features/postman.nix
    # ./features/qemu.nix
    # ./features/cli/ani-cli.nix
    # ./features/cs2.nix
    # ./features/minecraft.nix
    # ./features/rs.nix
    # ./features/flameshot.nix
  ];

  # FIRST_GO: the GPU module reads nvidia-smi, which isn't there until the
  # proprietary driver is enabled in the host config.
  # polybarModules.gpu = true;

  # workspace names / window assignments live in features/i3-profile.nix
  i3Profile.personal = true;

  # FIRST_GO: copied from `desktop`, whose monitor this is. Set the real output
  # name and mode from `xrandr` on this machine before turning it back on — a
  # wrong mode line leaves i3 starting on a black screen.
  # xsession.windowManager.i3.config.startup = [
  #   {
  #     command = "xrandr --output DP-0 --mode 2560x1440 --rate 164.83";
  #     always = true;
  #   }
  # ];
}
