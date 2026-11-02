{pkgs, ...}: {
  # Bits every laptop in this config wants. Anything that depends on the
  # specific machine (boot.resumeDevice, fingerprint reader, GPU) stays in
  # the host's configuration.nix.

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

  # power management: full performance on AC, powersave on battery
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
    };
  };
  services.thermald.enable = true;

  # maybe slight speedup in wifi
  networking.networkmanager.wifi.powersave = false;

  # Swap less eagerly (zram is global, hosts/shared/global/nix.nix), and cap
  # dirty memory so copies to slow external media don't stall in bursts.
  boot.kernel.sysctl = {
    "vm.swappiness" = 30;
    "vm.dirty_bytes" = 335544320;
    "vm.dirty_background_bytes" = 167772160;
  };

  # /tmp on tmpfs (ram)
  boot.tmp.useTmpfs = true;

  environment.systemPackages = with pkgs; [
    # laptop diagnostics / power tooling
    lm_sensors
    powertop
    intel-gpu-tools
    htop
  ];
}
