{
  imports = [
    ./global # default.nix
    ./features/discord.nix
    ./features/postman.nix
    ./features/qemu.nix
    ./features/cli/ani-cli.nix
    ./features/cs2.nix
    ./features/minecraft.nix
    ./features/lutris.nix
    ./features/rs.nix
    ./features/sound.nix
    ./features/wallpaper.nix
    ./features/i3.nix
    ./features/flameshot.nix
  ];

  polybarModules.gpu = true;

  # workspace names / window assignments live in features/i3-profile.nix
  i3Profile.personal = true;

  xsession.windowManager.i3.config.startup = [
    {
      command = "xrandr --output DP-0 --mode 2560x1440 --rate 164.83";
      always = true;
    }
  ];
}
