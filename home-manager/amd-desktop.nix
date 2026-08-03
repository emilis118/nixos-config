{
  imports = [
    ./global # default.nix
    ./features/discord.nix
    ./features/postman.nix
    ./features/qemu.nix
    ./features/cli/ani-cli.nix
    ./features/cs2.nix
    ./features/minecraft.nix
    ./features/rs.nix
    ./features/sound.nix
    ./features/wallpaper.nix
    ./features/i3.nix
    ./features/flameshot.nix
  ];

  polybarModules.gpu = true;

  # workspace names / window assignments live in features/i3-profile.nix
  i3Profile.personal = true;

  # Copied from `desktop`; adjust the output name and mode to this machine's
  # monitor (`xrandr` lists both) — DP-0 at 164.83 Hz is the other box's.
  xsession.windowManager.i3.config.startup = [
    {
      command = "xrandr --output DP-0 --mode 2560x1440 --rate 164.83";
      always = true;
    }
  ];
}
