{
  imports = [./roles/personal.nix];

  polybarModules.gpu = true;

  xsession.windowManager.i3.config.startup = [
    {
      command = "xrandr --output DP-0 --mode 2560x1440 --rate 164.83";
      always = true;
    }
  ];
}
