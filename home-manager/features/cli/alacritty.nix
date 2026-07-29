{pkgs, ...}: {
  programs.alacritty = {
    enable = true;
    settings = {
      window = {opacity = 0.8;};

      # Selecting text puts it straight into the CLIPBOARD selection, not
      # just X11's PRIMARY. That means no copy keystroke in the terminal at
      # all — which is what stops the Ctrl+Shift+C reflex that opens
      # Firefox's inspector everywhere else. Ctrl+Shift+C still works.
      selection.save_to_clipboard = true;

      keyboard.bindings = [
        # The bindings every other toolkit uses for copy/paste, kept
        # alongside alacritty's defaults so either hand position works.
        # Ctrl+C can't be rebound here — it has to stay SIGINT.
        {
          key = "Insert";
          mods = "Control";
          action = "Copy";
        }
        {
          key = "Insert";
          mods = "Shift";
          action = "Paste";
        }
      ];
      font = {
        size = 13.0;
        normal = {
          family = "JetBrains Mono Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "JetBrains Mono Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "JetBrains Mono Nerd Font";
          style = "Italic";
        };
      };
    };
  };
  # The 0.8 opacity above needs a compositor. On the i3 hosts that is picom,
  # switched on in features/i3.nix — not here, because this file is also
  # imported by the Plasma Wayland host, which composites on its own and has
  # no X11 session for picom to attach to.
}
