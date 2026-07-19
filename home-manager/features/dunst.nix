{
  # Notification daemon. Colors and shapes mirror the rofi theme
  # (dotfiles/rofi/theme.rasi), which in turn matches polybar.
  services.dunst = {
    enable = true;

    settings = {
      global = {
        font = "JetBrainsMono Nerd Font 12";
        # rofi bg / fg
        background = "#282A2E";
        foreground = "#C5C8C6";
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
        frame_color = "#707880"; # rofi disabled
        timeout = 5;
      };

      urgency_normal = {
        frame_color = "#F0C674"; # rofi primary
        timeout = 10;
      };

      urgency_critical = {
        frame_color = "#A54242"; # rofi alert
        timeout = 0; # sticky until dismissed
      };
    };
  };
}
