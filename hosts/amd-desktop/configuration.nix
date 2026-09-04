# Second gaming desktop: Ryzen 9 3900X + GTX 1070. Same software as `desktop`;
# the differences are the CPU vendor (microcode/kvm module live in
# hardware-configuration.nix), the isolated core below, and sops/VPN being off
# until this machine has an age key.
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

  # This CPU has one bad physical core. rasdaemon decodes every event
  # identically: bank 1 (Instruction Fetch Unit), "IC data array parity",
  # Ext Err Code 3, level L1, mem-tx instruction fetch — a stuck-bad L1
  # instruction cache array. All of it lands on cpu=0x0a and cpu=0x16, and
  # /sys/devices/system/cpu/cpu10/topology/thread_siblings_list reads "10,22",
  # so it is the two SMT threads of that one core and nothing else on the part.
  #
  # These params keep the scheduler off both threads from early boot. They are
  # NOT sufficient on their own, and are kept as the boot-window layer and as
  # the fallback if offline-broken-core (below) ever fails to run: an isolated
  # CPU is idle, not silent. It still runs its idle task, its per-CPU kthreads,
  # the timer tick and the MCE poll itself, and every one of those is an
  # instruction fetch through the failing array. A session running with exactly
  # this isolation still logged 1559 corrected errors at roughly one per
  # second, 98% of them with the MCi overflow bit set — meaning they arrived
  # faster than the bank could record them, so the true rate was higher still.
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

  # What actually stops the errors: take both threads offline. The x86 hotplug
  # path parks an offlined CPU in play_dead(), which MWAITs it into the deepest
  # available C-state — the core stops fetching instructions altogether, so the
  # broken array is never read, and the kernel tears down that CPU's MCE poll
  # timer along with it. Cost is one physical core (11c/22t usable), which
  # isolcpus had already given up anyway.
  #
  # This has to be a unit rather than a kernel parameter: nothing offlines a
  # specific CPU at boot. maxcpus=/possible_cpus= only truncate the top of the
  # range, and this core is 10 and 22 out of 0-23, so truncation would cost
  # half the chip to reach it.
  # Runs in the earliest boot phase a unit can occupy. It does not get to run
  # early enough to catch everything, and that limit is the kernel's, not
  # systemd's: with `-o short-monotonic` the kernel brings the cores up at
  # 1.178s, the two boot MCEs are logged at 1.222467s, and `Run /init as init
  # process` is at 1.222633s. The errors land 44ms after CPU bringup and 0.17ms
  # before userspace exists at all, so no unit — not even one in the initrd,
  # whose systemd queues its first job at 1.2227s — can preempt them. Two
  # corrected events per boot is the floor here. (`mce=nobootlog` would stop
  # them being *logged*, but this core's boot-time bank contents are the last
  # remaining signal that it is degrading, so it is deliberately not set.)
  #
  # What the early ordering does buy is the rest of the window: it used to run
  # at multi-user.target, ~32s in, which is after the display manager and the
  # session it starts. Anything scheduled in those 32s could only be kept off
  # the core by isolcpus, and isolcpus is exactly the layer already shown to be
  # insufficient.
  systemd.services.offline-broken-core = {
    description = "Offline the failing physical core (CPU 10/22, bad L1i)";
    wantedBy = ["sysinit.target"];
    before = ["sysinit.target" "shutdown.target"];
    # DefaultDependencies would order this after sysinit.target — i.e. after
    # the thing it needs to precede — so the implicit deps come off and the
    # shutdown ones go back on by hand. sysfs needs no ordering of its own:
    # PID 1 mounts it in mount_setup() before it loads any unit.
    unitConfig.DefaultDependencies = false;
    conflicts = ["shutdown.target"];
    serviceConfig = {
      Type = "oneshot";
      # The CPUs must stay offline for the lifetime of the boot, not just for
      # the lifetime of the (immediately-exiting) ExecStart.
      RemainAfterExit = true;
    };
    # No ExecStop counterpart on purpose: bringing the core back for shutdown
    # would buy nothing and would resume the error stream.
    script = ''
      for cpu in 10 22; do
        node=/sys/devices/system/cpu/cpu$cpu/online
        if [ ! -e "$node" ]; then
          echo "cpu$cpu: $node missing, cannot offline" >&2
          exit 1
        fi
        echo 0 > "$node"
        # Offlining can be refused (the kernel returns EBUSY for a CPU it still
        # needs); a silent no-op here would leave the core running and look
        # like success, so read the state back rather than trusting the write.
        # `read` rather than `cat`: this stage of boot is no place to depend on
        # an external binary when a builtin does it.
        read -r state < "$node"
        if [ "$state" != "0" ]; then
          echo "cpu$cpu: still online after write" >&2
          exit 1
        fi
        echo "cpu$cpu: offline"
      done
    '';
  };

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

  # No sops on this machine: it has no age key in .sops.yaml yet, and turning
  # this on before it does makes activation fail. Uncomment once SOPS-SETUP.md
  # step 2 has been run here and the key is a recipient of secrets/common.yaml.
  secrets.enable = true;

  # NordLynx stays off with it — nordvpn.nix asserts secrets.enable, because
  # the WireGuard private key is read from sops. Re-enable both together:
  #
  nordvpn.enable = true;
  #   # blocky is this host's resolver (networking.nameservers = 127.0.0.1), so
  #   # don't let wg-quick swap in Nord's DNS and bypass the blocklists.
  nordvpn.dns = [];

  # Persist the NVIDIA driver's compiled-shader cache. On NVIDIA these vars
  # govern the on-disk ISA cache for BOTH OpenGL and Vulkan. By default the
  # cache is size-limited and the driver's cleanup pass evicts entries, so a
  # big shader set like CS2's gets trimmed between sessions and has to be
  # rebuilt on every launch (the slow "Building Vulkan shaders" screen).
  # SKIP_CLEANUP keeps entries, and the larger size gives them room to live.
  # Set at session scope (not just Steam launch options) so Steam's separate
  # background shader-processing pass benefits too.
  #
  # These are the cache that actually works on this driver. Steam's own
  # fossilize pre-caching pass is a separate, worse thing and is turned OFF in
  # the Steam client - see the shader note in home-manager/features/cs2.nix.
  environment.sessionVariables = {
    __GL_SHADER_DISK_CACHE = "1";
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
    __GL_SHADER_DISK_CACHE_SIZE = "12000000000"; # ~12 GB
  };
  system.stateVersion = "24.11"; # Did you read the comment?
}
