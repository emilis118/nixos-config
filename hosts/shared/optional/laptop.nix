{pkgs, ...}: {
  # Bits every laptop in this config wants. Anything that depends on the
  # specific machine (boot.resumeDevice, fingerprint reader, GPU) stays in
  # the host's configuration.nix.
  imports = [./performance.nix];

  # trackpad
  services.libinput.enable = true;

  # Lid close suspends immediately, then hibernates to disk after 30 min so
  # a closed laptop doesn't drain the battery. Lid close while docked
  # (external monitor attached) is still ignored for clamshell use.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend-then-hibernate";
  };
  systemd.sleep.settings.Sleep.HibernateDelaySec = "30min";
  # the hibernate image lives in the swap partition; each host points
  # boot.resumeDevice at its own swap UUID

  hardware.enableAllFirmware = true;

  services.xserver.videoDrivers = ["modesetting"]; # or "intel"

  # auto-apply saved xrandr profiles on monitor hotplug
  # (save one per docking spot with `autorandr --save <name>`)
  services.autorandr.enable = true;

  # power management
  services.tlp.enable = true;
  services.thermald.enable = true;

  environment.systemPackages = with pkgs; [
    # laptop diagnostics / power tooling
    lm_sensors
    powertop
    intel-gpu-tools
    htop
  ];
}
