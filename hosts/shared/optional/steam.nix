{
  programs.steam.enable = true;
  programs.gamemode.enable = true;
  programs.gamemode.settings = {
    general = {
      renice = 10;
    };

    # Warning: GPU optimisations have the potential to damage hardware
    # gpu = {
    #   apply_gpu_optimisations = "accept-responsibility";
    #   gpu_device = 1;
    #   nv_powermizer_mode = 1;
    #   nv_core_clock_mhz_offset = 150;
    #   nv_mem_clock_mhz_offset = 300;
    # };
  };
}
