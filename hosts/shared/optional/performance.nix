{
  # maybe slight speedup in wifi
  networking.networkmanager.wifi.powersave = false;

  # zram:
  # todo

  # swappiness to SWAP decrease
  # dirty bytes for less writing dropoff external media
  boot.kernel.sysctl = {
    "vm.swappiness" = 30;
    "vm.dirty_bytes" = 335544320;
    "vm.dirty_background_bytes" = 167772160;
  };

  # change cpu governor to max on power
  powerManagement.cpuFreqGovernor = "powersave";
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
  };
  # idk if leave this
  services.auto-cpufreq.enable = true;

  # /tmp on tmpfs (ram)
  boot.tmp.useTmpfs = true;
}
