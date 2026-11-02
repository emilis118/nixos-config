{config, ...}: let
  palette = config.theme.palette;
in {
  imports = [./theme.nix];

  # Notification daemon. Colours come from the shared palette, so the frames
  # match rofi and polybar; the shapes mirror the rofi theme.
  services.dunst = {
    enable = true;

    settings = {
      global = {
        font = "JetBrainsMono Nerd Font 12";
        background = palette.bg;
        foreground = palette.fg;
        frame_width = 2;
        corner_radius = 4;
        separator_color = "frame";

        # top-right, clear of the polybar
        origin = "top-right";
        offset = "10x40";
        width = 350;

        padding = 8;
        horizontal_padding = 10;
        gap_size = 4;

        icon_theme = "Papirus-Dark";
        enable_recursive_icon_lookup = true;
        min_icon_size = 24;
        max_icon_size = 48;

        # left-click closes, right-click opens the notification's action
        mouse_left_click = "close_current";
        mouse_right_click = "do_action";
        dmenu = "rofi -dmenu -p notification";
      };

      urgency_low = {
        frame_color = palette.disabled;
        timeout = 5;
      };

      urgency_normal = {
        frame_color = palette.primary;
        timeout = 10;
      };

      urgency_critical = {
        frame_color = palette.alert;
        timeout = 0; # sticky until dismissed
      };
    };
  };
}
