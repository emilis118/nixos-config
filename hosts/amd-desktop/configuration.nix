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

  # Keep CPU 10 out of the scheduler's reach: nothing is placed on it unless
  # it is pinned there explicitly (`taskset -c 10 ...`, or a systemd unit with
  # CPUAffinity=10). isolcpus is the boot-time form and is what actually keeps
  # the core clean from early boot — cgroup cpusets can only push work off a
  # core after userspace is up.
  #
  # 3900X is 12c/24t, so the logical CPUs are 0-23 and CPU 10's SMT sibling is
  # CPU 22 (Linux enumerates thread 0 of every core first). Isolating 10 alone
  # leaves normal work running on 22, sharing the physical core's front end; to
  # hand the whole core over, use "isolcpus=10,22" instead.
  #
  # Two optional companions, if the isolated core is meant for latency-
  # sensitive work rather than just being held in reserve:
  #   nohz_full=10  — stop the periodic scheduler tick on it
  #   rcu_nocbs=10  — move RCU callback processing off it
  boot.kernelParams = ["isolcpus=10"];

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

  secrets.enable = true;

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
