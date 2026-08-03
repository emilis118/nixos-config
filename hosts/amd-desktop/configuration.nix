# Second gaming desktop: Ryzen 9 3900X + GTX 1070. Meant to end up the same as
# `desktop`; the differences are the CPU vendor (microcode/kvm module live in
# hardware-configuration.nix) and the isolated core below.
#
# Cut down to a first-boot build for now: enough for i3 + the isolated core,
# and not much else, so the first rebuild isn't a multi-gigabyte download.
# Everything held back is commented and tagged FIRST_GO — `grep -rn FIRST_GO`
# over the repo lists all of it, here and in home-manager/amd-desktop.nix.
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
    # FIRST_GO: steam pulls proton-ge and the 32-bit graphics stack, which is
    # the single biggest download in the whole config.
    # ./../shared/optional/steam.nix
    # FIRST_GO: local DNS server. Nothing depends on it; without it the machine
    # just uses DHCP's resolver.
    # ./../shared/optional/blocky.nix
    # FIRST_GO: openrazer kernel module + daemon, only needed for the peripherals.
    # ./../shared/optional/razer.nix
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

  # FIRST_GO: no proprietary NVIDIA driver yet — it is a large download and it
  # builds a kernel module against the running kernel. Without it X falls back
  # to nouveau, which drives a GTX 1070 well enough for i3 and a browser (no
  # reclocking, so it stays at low clocks, and no CUDA/Vulkan worth using).
  # Uncomment this block, rebuild, reboot, and it takes over.
  #
  # services.xserver.videoDrivers = ["nvidia"];
  #
  # hardware.nvidia = {
  #   modesetting.enable = true;
  #   powerManagement.enable = false;
  #   powerManagement.finegrained = false;
  #   # GTX 1070 is Pascal: the open kernel modules need Turing or newer, so
  #   # this stays on the proprietary ones.
  #   open = false;
  #   nvidiaSettings = true;
  #   # 580 is the last branch that supports Pascal — the current `stable`
  #   # (590+) has dropped it, so pin the legacy branch like `desktop` does.
  #   package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  # };

  # No sops on this machine: it has no age key in .sops.yaml yet, and turning
  # this on before it does makes activation fail. Uncomment once SOPS-SETUP.md
  # step 2 has been run here and the key is a recipient of secrets/common.yaml.
  # secrets.enable = true;

  # NordLynx stays off with it — nordvpn.nix asserts secrets.enable, because
  # the WireGuard private key is read from sops. Re-enable both together:
  #
  #   nordvpn.enable = true;
  #   # blocky is this host's resolver (networking.nameservers = 127.0.0.1), so
  #   # don't let wg-quick swap in Nord's DNS and bypass the blocklists.
  #   nordvpn.dns = [];

  # FIRST_GO: goes back with the NVIDIA block above — these only mean anything
  # to the proprietary driver. Persists its compiled-shader cache: on NVIDIA
  # these vars govern the on-disk ISA cache for BOTH OpenGL and Vulkan. By
  # default the cache is size-limited and the driver's cleanup pass evicts
  # entries, so a big shader set like CS2's gets trimmed between sessions and
  # has to be rebuilt on every launch (the slow "Building Vulkan shaders"
  # screen). SKIP_CLEANUP keeps entries, and the larger size gives them room to
  # live. Set at session scope (not just Steam launch options) so Steam's
  # separate background shader-processing pass benefits too.
  #
  # environment.sessionVariables = {
  #   __GL_SHADER_DISK_CACHE = "1";
  #   __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
  #   __GL_SHADER_DISK_CACHE_SIZE = "12000000000"; # ~12 GB
  # };
  system.stateVersion = "24.11"; # Did you read the comment?
}
