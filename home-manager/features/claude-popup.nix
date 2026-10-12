{
  config,
  pkgs,
  lib,
  ...
}: let
  # i3 window class the popup is matched on, both by the for_window rule
  # below and by the toggle check in the script
  class = "claude-popup";

  # Toggle: the first press opens a floating alacritty running claude in the
  # middle of the screen, the next press kills it (from anywhere - the window
  # doesn't need focus). Leaving claude (Ctrl+D, or /exit) also closes it,
  # since alacritty -e exits with its command.
  #
  # Every popup is a fresh session. It runs in its own empty directory rather
  # than $HOME, so claude doesn't pick up whatever project you happened to be
  # in, and only asks the "trust this folder" question once. `claude -c`
  # inside it picks the previous popup conversation back up.
  claudePopup = pkgs.writeShellApplication {
    name = "claude-popup";
    runtimeInputs = [pkgs.jq pkgs.coreutils];
    text = ''
      if i3-msg -t get_tree \
        | jq -e --arg c ${class} '.. | objects | select(.window_properties?.class == $c)' >/dev/null; then
        i3-msg "[class=\"^${class}$\"] kill" >/dev/null
        exit 0
      fi

      dir="${config.xdg.stateHome}/claude-popup"
      mkdir -p "$dir"
      cd "$dir"

      # Background matches rofi's (dotfiles/rofi/theme.rasi) and is near
      # opaque, so the popup reads as a launcher over the windows behind it
      # rather than another 0.8-opacity terminal.
      exec ${pkgs.alacritty}/bin/alacritty \
        --class ${class},${class} \
        --title "claude" \
        -o 'window.opacity=0.95' \
        -o 'window.padding.x=12' \
        -o 'window.padding.y=10' \
        -o 'colors.primary.background="#282A2E"' \
        -e ${pkgs.claude-code}/bin/claude
    '';
  };
in {
  home.packages = [claudePopup];

  xsession.windowManager.i3 = {
    config.keybindings."Mod1+a" = "exec --no-startup-id claude-popup"; # a(sk)

    # mkAfter: has to come after i3-profile's `[class=".*"] border none`, or
    # that rule would win the border. sticky keeps it on screen when you
    # switch workspace underneath it.
    extraConfig = lib.mkAfter ''
      for_window [class="^${class}$"] floating enable, sticky enable, border pixel 2, resize set 60 ppt 60 ppt, move position center, focus
    '';
  };
}
