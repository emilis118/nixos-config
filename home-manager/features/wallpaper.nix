{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellScriptBin "random-wallpaper"
      ''
        shopt -s nullglob

        wallpaper_dir="/etc/nixos/dotfiles/wallpaper"

        files=("$wallpaper_dir"/*.jpg)
        count=''${#files[@]}

        if (( count == 0 )); then
          echo "No JPG files found in $wallpaper_dir"
          exit 1
        fi

        feh --bg-scale "''${files[RANDOM % count]}"
      '')
  ];
}
# pkgs.stdenv.mkDerivation {
#   pname = "wallpapers";
#   version = "1.0";
#
#   src = ./.;
#
#   installPhase = ''
#     mkdir -p $out/share/wallpapers
#     cp *.jpg $out/share/wallpapers/
#
#     mkdir -p $out/bin
#     cp random.sh $out/bin/random-wallpaper
#     chmod +x $out/bin/random-wallpaper
#   '';
# }

