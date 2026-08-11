{
  imports = [
    ./global # default.nix
    ./features/discord.nix
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

  # Copied from `desktop`, whose monitor this is — check `xrandr` on this
  # machine and set the real output name and mode. A mode this output doesn't
  # have makes xrandr exit with an error at i3 startup; the session still comes
  # up, just at whatever mode X picked.
  xsession.windowManager.i3.config.startup = [
    {
      command = "xrandr --output DP-0 --mode 2560x1440 --rate 164.83";
      always = true;
    }
  ];
}
