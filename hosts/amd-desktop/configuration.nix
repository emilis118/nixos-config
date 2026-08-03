# Second gaming desktop: Ryzen 9 3900X + GTX 1070. Same software as
# `desktop`; the differences are the CPU vendor (microcode/kvm module live in
# hardware-configuration.nix) and the isolated core below.
{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./../shared/global # auto picks default.nix
    ./../shared/optional/i3.nix # sddm + i3 session
    ./../shared/optional/blocky.nix
    ./../shared/optional/steam.nix
    ./../shared/optional/razer.nix
  ];

  # Networking
  networking.hostName = "amd-desktop";

  # Keep physical core 10 out of the scheduler's reach: nothing lands on it
  # unless pinned there explicitly (`taskset -c 10 ...`, or a systemd unit with
  # CPUAffinity=10). isolcpus is the boot-time form and is what keeps the core
  # clean from early boot — cgroup cpusets can only push work off a core once
  # userspace is up.
  #
  # Both threads, not just CPU 10: this is a 12c/24t part and
  # /sys/devices/system/cpu/cpu10/topology/thread_siblings_list reads "10,22",
  # so 22 is the same physical core. Isolating 10 alone would leave ordinary
  # work running on 22, sharing that core's L1/L2 and front end — which defeats
  # the point, and matters here because this core logs cache MCEs.
  #
  # nohz_full/rcu_nocbs take the periodic tick and the RCU callback work off it
  # as well; irqaffinity is the default IRQ mask, because isolcpus on its own
  # does not stop device interrupts from being steered onto an isolated CPU.
  # Drivers with managed per-CPU interrupts (NVMe queues, and similar) ignore
  # that mask, so it thins the interrupt load rather than eliminating it.
  boot.kernelParams = [
    "isolcpus=10,22"
    "nohz_full=10,22"
    "rcu_nocbs=10,22"
    "irqaffinity=0-9,11-21,23"
  ];

  # Decode and persist machine-check events, so the cache errors on core 10 can
  # be read back as "corrected vs uncorrected, and how often" (`ras-mc-ctl
  # --errors` / `--summary`) instead of being scraped out of dmesg. rasdaemon
  # is the maintained tool for this; mcelog is dead on current kernels.
  hardware.rasdaemon.enable = true;

  # Enable OpenGL
  hardware.graphics.enable = true;

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    # GTX 1070 is Pascal: the open kernel modules need Turing or newer, so
    # this stays on the proprietary ones.
    open = false;
    nvidiaSettings = true;
    # 580 is the last branch that supports Pascal — the current `stable`
    # (590+) has dropped it, so pin the legacy branch like `desktop` does.
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };

  # secrets.enable = true;

  # NordLynx. Off at boot (nordvpn.autoStart stays false) — `vpn up`, the
  # polybar shield, or mod+d → vpn-menu brings it up.
  nordvpn.enable = true;
  # blocky is this host's resolver (networking.nameservers = 127.0.0.1), so
  # don't let wg-quick swap in Nord's DNS and bypass the blocklists.
  nordvpn.dns = [];

  # Persist the NVIDIA driver's compiled-shader cache. On NVIDIA these vars
  # govern the on-disk ISA cache for BOTH OpenGL and Vulkan. By default the
  # cache is size-limited and the driver's cleanup pass evicts entries, so a
  # big shader set like CS2's gets trimmed between sessions and has to be
  # rebuilt on every launch (the slow "Building Vulkan shaders" screen).
  # SKIP_CLEANUP keeps entries, and the larger size gives them room to live.
  # Set at session scope (not just Steam launch options) so Steam's separate
  # background shader-processing pass benefits too.
  environment.sessionVariables = {
    __GL_SHADER_DISK_CACHE = "1";
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
    __GL_SHADER_DISK_CACHE_SIZE = "12000000000"; # ~12 GB
  };
  system.stateVersion = "24.11"; # Did you read the comment?
}
