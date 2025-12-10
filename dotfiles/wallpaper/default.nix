{pkgs}:
pkgs.stdenv.mkDerivation {
  pname = "wallpapers";
  version = "1.0";

  src = ./.;

  installPhase = ''
    mkdir -p $out/share/wallpapers
    cp *.jpg $out/share/wallpapers/

    mkdir -p $out/bin
    cp random.sh $out/bin/random-wallpaper
    chmod +x $out/bin/random-wallpaper
  '';
}
