{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.theme;
in {
  # The one palette the i3 session shares: polybar's bar and module scripts,
  # dunst's frames, every rofi window, the claude popup. Each consumer imports
  # this module and reads config.theme.palette instead of repeating the hex
  # values, so a colour is changed in one place.
  #
  # The Docky bar (features/polybar-docky.nix) is the exception by design: it
  # takes its colours from pywal at runtime and hands them to the same scripts
  # and rofi themes through POLYBAR_* / ROFI_* environment variables. What is
  # here is what everything falls back on when those are unset.
  options.theme = {
    palette = lib.mapAttrs (name: default:
      lib.mkOption {
        type = lib.types.str;
        inherit default;
        description = "Palette colour `${name}`, as #RRGGBB.";
      }) {
      bg = "#282A2E";
      bgAlt = "#373B41";
      fg = "#C5C8C6";
      primary = "#F0C674"; # the yellow: icons, borders, the selected row
      secondary = "#8ABEB7";
      alert = "#A54242";
      good = "#8C9440"; # "all fine" in the bar scripts (vpn up, no failed units)
      onPrimary = "#282A2E"; # text drawn on a primary-coloured background
      disabled = "#707880";
    };

    rofiThemes = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = ''
        dotfiles/rofi/*.rasi with the palette filled in. The files there are
        written against @bg@, @primary@, ... placeholders — the env(ROFI_*,
        default) fallbacks — so that the one palette above is the only copy
        of the values. Consumers use "''${config.theme.rofiThemes}/<name>.rasi".
      '';
    };
  };

  config.theme.rofiThemes = let
    subst =
      lib.concatMapStringsSep " "
      (name: "-e 's|@${name}@|${cfg.palette.${name}}|g'")
      (lib.attrNames cfg.palette);
  in
    pkgs.runCommand "rofi-themes" {} ''
      mkdir -p $out
      for f in ${../../dotfiles/rofi}/*.rasi; do
        sed ${subst} "$f" > "$out/$(basename "$f")"
      done
      # a placeholder with no palette entry would reach rofi as a parse error
      # (only env() defaults are checked: the header comments mention @name@)
      if grep -n 'env([^)]*@' $out/*.rasi; then
        echo "unknown palette placeholder in the lines above" >&2
        exit 1
      fi
    '';
}
