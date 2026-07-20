{pkgs, ...}: {
  programs.steam = {
    enable = true;

    # Open firewall ports for Steam Remote Play (streaming games to/from
    # other devices).
    remotePlay.openFirewall = true;

    # Open firewall ports for Local Network Game Transfers, so Steam can
    # copy already-installed games from another PC on the LAN instead of
    # re-downloading them from the internet.
    localNetworkGameTransfers.openFirewall = true;

    # Extra Proton builds selectable in a game's compatibility settings.
    # Proton-GE has community fixes and codecs that ship ahead of Valve's
    # Proton, and generally improves compatibility for non-native games.
    extraCompatPackages = [pkgs.proton-ge-bin];
  };

  # Gamescope: a micro-compositor useful for running games in an isolated
  # session with upscaling/framerate control. Launch a game with
  # `gamescope -- %command%` in its Steam launch options.
  programs.gamescope.enable = true;

  programs.gamemode.enable = true;
  programs.gamemode.settings = {
    general = {
      renice = 10;
      # Desktop notification when GameMode activates/deactivates.
      notify = 1;
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
