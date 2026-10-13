{
  # enable flakes
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Without this the store only ever grows: every rebuild adds a generation
  # and nothing removes the old ones.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Hard-link identical files in the store. Costs some IO during the run,
  # saves a lot of disk on a config with four similar systems' worth of
  # closures.
  nix.optimise.automatic = true;

  # Keep big local builds (the storytold *craft Rust workspaces, anything
  # not in the binary cache) from taking the whole machine down. Out of the
  # box it's max-jobs = nproc and every job using every core: on the 20-thread
  # / 16 GB work_pc that is up to 400 rustc processes, no swap, and the kernel
  # OOM killer picking the X session.
  #
  # 1. Fewer things at once: two derivations in parallel, 8 cores each.
  nix.settings = {
    max-jobs = 2;
    cores = 8;
  };

  # 2. Compressed swap in RAM as a buffer (the hosts have no swap partition,
  #    apart from the laptops' hibernate one).
  zramSwap.enable = true;

  # 3. A memory ceiling on the daemon's cgroup, which every build runs in.
  #    Past MemoryHigh the builds are throttled and pushed to swap; at
  #    MemoryMax the OOM killer only looks inside this cgroup, so a build
  #    fails instead of the desktop dying. OOMPolicy = continue keeps the
  #    daemon itself (and the other builds) alive when that happens.
  systemd.services.nix-daemon.serviceConfig = {
    MemoryHigh = "70%";
    MemoryMax = "85%";
    OOMPolicy = "continue";
    OOMScoreAdjust = 500;
  };
}
