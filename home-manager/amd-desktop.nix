{
  imports = [
    ./roles/personal.nix
    ./features/freecad.nix
  ];

  polybarModules.gpu = true;

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
