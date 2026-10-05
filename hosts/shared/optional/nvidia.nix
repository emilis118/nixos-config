{config, ...}: {
  # The two gaming desktops (desktop, amd-desktop). Both cards are pre-Turing
  # (amd-desktop's is a GTX 1070, Pascal), which decides the two settings that
  # matter: the open kernel modules need Turing or newer, and 580 is the last
  # driver branch that supports Pascal — the current `stable` (590+) has
  # dropped it.

  # Enable OpenGL
  hardware.graphics.enable = true;

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };

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
}
