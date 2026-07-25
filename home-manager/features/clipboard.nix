{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.clipboard;

  # Standalone picker for the keybinding and the terminal: its own rofi
  # window. The HM module only exports CM_LAUNCHER as a session variable,
  # which an sddm -> i3 session doesn't reliably pick up, so set it here.
  clipPick = pkgs.writeShellScriptBin "clip" ''
    export PATH=${makeBinPath [pkgs.rofi pkgs.clipmenu pkgs.coreutils]}:$PATH
    export CM_LAUNCHER=rofi
    export CM_HISTLENGTH=${toString cfg.histLength}
    exec clipmenu -i -p clipboard "$@"
  '';

  # ...and the same thing as a tab inside the main rofi window. clipmenu
  # speaks rofi's script protocol natively (CM_LAUNCHER=rofi-script): no
  # arguments lists the clips, and being re-invoked with one re-copies it.
  rofiClip = pkgs.writeShellScriptBin "rofi-clipboard" ''
    export PATH=${makeBinPath [pkgs.clipmenu pkgs.coreutils]}:$PATH
    export CM_LAUNCHER=rofi-script

    empty="(nothing copied yet this boot)"

    # Before the first clip there is no line_cache and clipmenu exits with an
    # error, which would show up as a broken-looking tab. Say so instead.
    # Path mirrors clipmenu's own: $CM_DIR/clipmenu.<major>.$USER/line_cache.
    cache="''${CM_DIR:-''${XDG_RUNTIME_DIR:-''${TMPDIR:-/tmp}}}/clipmenu.${versions.major pkgs.clipmenu.version}.$USER/line_cache"
    if [ ! -s "$cache" ]; then
      [ -z "''${1:-}" ] && echo "$empty"
      exit 0
    fi

    [ "''${1:-}" != "$empty" ] || exit 0

    exec clipmenu "$@"
  '';
in {
  # X11 has two clipboards and no history: whatever you copied dies with the
  # program you copied it from, and a stray middle-click pastes something
  # else entirely. clipmenud watches both selections and keeps the last
  # `maxClips` entries, so nothing is lost and you can pick from the list.
  options.clipboard = {
    enable = mkEnableOption "clipboard history (clipmenu, picked through rofi)" // {default = true;};

    maxClips = mkOption {
      type = types.int;
      default = 400;
      description = "How many entries to keep. They live in $XDG_RUNTIME_DIR, so a reboot clears them.";
    };

    selections = mkOption {
      type = types.str;
      default = "clipboard";
      example = "clipboard primary";
      description = ''
        Which X selections to record. "clipboard" is the Ctrl+C one. Adding
        "primary" also records every mouse selection, which gives you a
        complete history at the cost of a much noisier list.
      '';
    };

    histLength = mkOption {
      type = types.int;
      default = 20;
      description = "Rows the standalone `clip` window shows at once (it still scrolls).";
    };
  };

  config = mkIf cfg.enable {
    services.clipmenu = {
      enable = true;
      launcher = "rofi";
    };

    # The nixpkgs clipmenud wrapper hard-sets its own PATH, so this list only
    # adds tunables; it doesn't fight the module's PATH entry.
    systemd.user.services.clipmenu.Service.Environment = [
      "CM_MAX_CLIPS=${toString cfg.maxClips}"
      "CM_SELECTIONS=${cfg.selections}"
      "CM_LAUNCHER=rofi"
    ];

    home.packages = [
      clipPick
      rofiClip
      pkgs.xclip # -selection clipboard, what the scripts here use
      pkgs.xsel # what clipmenu itself uses
    ];

    # adds the "clip" tab to the main rofi window (see rofi.nix)
    rofiModes.clipboard = mkDefault true;

    # ...and a launcher entry for the standalone window
    xdg.desktopEntries.clipboard = {
      name = "Clipboard history";
      exec = "clip";
      icon = "edit-paste";
      categories = ["Utility"];
    };
  };
}
