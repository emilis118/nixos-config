{pkgs, ...}: let
  # Fuzzy-find any file or folder under $HOME in a rofi window, fzf style.
  #
  #   Enter      open in thunar: a folder opens itself, a file opens its
  #              folder with the file selected
  #   Alt+Enter  open with the default app (xdg-open), e.g. a pdf in the viewer
  #   Alt+c      copy the full path to the clipboard
  #
  # The list comes from fd, so .gitignore'd stuff (node_modules, build dirs,
  # ...) and dot-files/dirs stay out of it, and --one-file-system keeps it from
  # wandering into network mounts (dfs, sshfs, gvfs) and hanging on them.
  # rofi reads the list asynchronously, so the window is up straight away even
  # if fd is still walking.
  rofiFiles = pkgs.writeShellApplication {
    name = "rofi-files";
    runtimeInputs = with pkgs; [fd rofi xdg-utils xclip libnotify coreutils gnused];
    bashOptions = [];
    text = ''
      list() {
        # folders first: with an empty query that's what you see on top.
        # Shown as ~/..., the trailing / from fd marks folders.
        {
          fd . "$HOME" --one-file-system --type d --color never
          fd . "$HOME" --one-file-system --type f --type l --color never
        } | sed "s|^$HOME|~|"
      }

      # dmenu custom keys exit with 10+n (kb-custom-1 -> 10, ...)
      choice=$(list | rofi -dmenu -i -p files \
        -matching fuzzy -sort -sorting-method fzf \
        -no-custom -async-pre-read 50 \
        -kb-custom-1 "Alt+Return,Alt+KP_Enter" \
        -kb-custom-2 "Alt+c" \
        -mesg "enter: thunar   alt+enter: open   alt+c: copy path")
      code=$?
      [ -n "$choice" ] || exit 0

      path="$HOME''${choice#\~}"
      path="''${path%/}"

      case $code in
        0)
          # thunar given a file opens its folder with that file selected
          setsid -f thunar "$path" >/dev/null 2>&1 </dev/null
          ;;
        10)
          setsid -f xdg-open "$path" >/dev/null 2>&1 </dev/null
          ;;
        11)
          printf '%s' "$path" | xclip -selection clipboard
          notify-send -a files "path copied" "$path" 2>/dev/null
          ;;
      esac
    '';
  };
in {
  home.packages = [rofiFiles pkgs.fd];

  # s(earch). The window is rofi's own, so it already sits in the middle.
  xsession.windowManager.i3.config.keybindings."Mod1+s" = "exec --no-startup-id rofi-files";

  # also reachable by typing "files" in the alt+d launcher
  xdg.desktopEntries.rofi-files = {
    name = "Find files";
    exec = "rofi-files";
    icon = "system-search";
  };
}
