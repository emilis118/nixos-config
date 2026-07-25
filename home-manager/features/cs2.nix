{...}: {
  # MangoHud performance overlay. Toggle in-game with Shift+F12 (default).
  # Using programs.mangohud instead of a bare package install so the config
  # below ships declaratively. gamescope renders it via its --mangoapp flag
  # (see the Steam launch options note at the bottom of this file).
  programs.mangohud = {
    enable = true;
    settings = {
      fps_limit = 0;
      cpu_stats = true;
      cpu_temp = true;
      gpu_stats = true;
      gpu_temp = true;
      ram = true;
      vram = true;
      frametime = true;
      frame_timing = true;
      # Small, top-left, semi-transparent so it stays out of the way.
      position = "top-left";
      font_size = 20;
      background_alpha = 0.4;
      toggle_hud = "Shift_R+F12";
    };
  };

  # rofi launcher: appears in the "apps" tab as "Counter-Strike 2".
  # `steam -applaunch 730` starts CS2 through Steam, which applies whatever
  # launch options are configured for the game in Steam (the gamescope +
  # mangohud wrapper - see below). i3 routes it to workspace 3 via the
  # `assign [class="cs2"]` rule in desktop.nix.
  # xdg.desktopEntries.cs2 = {
  #   name = "Counter-Strike 2";
  #   exec = "steam -applaunch 730";
  #   icon = "steam";
  #   categories = ["Game"];
  # };

  # ---------------------------------------------------------------------------
  # ONE-TIME MANUAL STEP (Steam substitutes %command% at launch, so this can't
  # live in the .desktop exec - it must go in Steam's per-game field):
  #
  #   Steam -> CS2 -> gear/Properties -> General -> Launch Options, paste:
  #
  #   SDL_VIDEODRIVER=x11 SDL_AUDIODRIVER=pipewire MANGOHUD=1 \
  #     gamemoderun %command% -novid -nojoy -high +fps_max 400
  #
  # NO gamescope: nested gamescope on the NVIDIA proprietary driver under X11
  #   runs headless here (game has audio + GPU load but never maps a visible
  #   window), so CS2 wouldn't show up. Without gamescope, CS2 opens as a
  #   normal window (class "cs2") that i3 routes to workspace 3 via the
  #   `assign [class="cs2"]` rule in desktop.nix - the setup that worked before.
  #
  # env: SDL_VIDEODRIVER=x11 keeps SDL off Wayland on this X11/i3 session;
  #   SDL_AUDIODRIVER=pipewire routes audio via pipewire; MANGOHUD=1 enables
  #   the overlay (its in-game Vulkan layer reads the programs.mangohud config
  #   above). (Old PROTON_NO_FSYNC/ESYNC dropped - CS2 is native, no Proton.)
  #
  # 4:3 STRETCHED: set Aspect Ratio 4:3 + a 4:3 resolution and Fullscreen in
  #   CS2's own Video settings. The stretch to fill the 16:9 panel is done by
  #   the NVIDIA driver's flat-panel scaling (set "Force Full GPU scaling" once
  #   in nvidia-settings -> X Server Display Config -> Advanced, if bars show).
  # gamemoderun applies the gamemode CPU/scheduler tweaks enabled in steam.nix.
  # CS2 args (after %command%): -novid skips the intro, -nojoy disables the
  #   joystick subsystem (minor perf/startup win), -high raises priority,
  #   +fps_max 400 caps the engine.
  # ---------------------------------------------------------------------------
}
