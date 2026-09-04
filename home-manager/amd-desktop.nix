{
  imports = [
    ./global # default.nix
    ./features/discord.nix
    ./features/whatsapp.nix
    ./features/postman.nix
    ./features/qemu.nix
    ./features/cli/ani-cli.nix
    ./features/cs2.nix
    ./features/minecraft.nix
    ./features/naruto-arena
    ./features/rs.nix
    ./features/sound.nix
    ./features/wallpaper.nix
    ./features/i3.nix
    ./features/flameshot.nix
  ];

  polybarModules.gpu = true;

  # workspace names / window assignments live in features/i3-profile.nix
  i3Profile.personal = true;

  # Output name verified with `xrandr` on this machine: the panel is on DP-4,
  # not DP-0, which is why this line used to fail at i3 startup and leave the
  # session at 59.95Hz. A mode the output doesn't have makes xrandr exit with an
  # error the same way.
  xsession.windowManager.i3.config.startup = [
    {
      command = "xrandr --output DP-4 --mode 2560x1440 --rate 164.83";
      always = true;
    }
  ];
}
