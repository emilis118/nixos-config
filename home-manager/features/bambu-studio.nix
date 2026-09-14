{pkgs, ...}: let
  # nixpkgs' bambu-studio is marked unfree (the dlopen'd network plugin is an
  # AGPL violation, nixpkgs#415821), so Hydra never builds it and it is never
  # in cache.nixos.org. Building it locally pegs all 14 cores on CGAL/OpenVDB
  # translation units at several GB each and swaps this 16 GB laptop to death.
  # Upstream's own AppImage is the same program as a 230 MB download.
  #
  # To bump: pick the newest non-prerelease from
  # https://github.com/bambulab/BambuStudio/releases, then
  #   nix store prefetch-file --hash-type sha256 <url>
  version = "02.08.02.61";
  src = pkgs.fetchurl {
    url = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/BambuStudio_ubuntu24.04-v${version}-20260820225108.AppImage";
    hash = "sha256-1QGxA/rFQkUT7A6Na8FF+zBxneLH2U1zINcjdAyBp/0=";
  };

  contents = pkgs.appimageTools.extract {
    pname = "bambu-studio";
    inherit version src;
  };

  bambu-studio = pkgs.appimageTools.wrapType2 {
    pname = "bambu-studio";
    inherit version src;

    # The AppImage bundles only ffmpeg and expects an Ubuntu 24.04 system for
    # the rest; these are the NEEDED/dlopen'd libs the default FHS env misses.
    extraPkgs = p: [
      p.webkitgtk_4_1 # libwebkit2gtk-4.1 + libjavascriptcoregtk-4.1 (login/store panes)
      p.glib-networking # GIO TLS backend; see GIO_EXTRA_MODULES below
      p.libsecret # printer/account credentials
      # printer camera feed
      p.gst_all_1.gst-plugins-good
      p.gst_all_1.gst-plugins-bad
      p.gst_all_1.gst-libav
    ];

    nativeBuildInputs = [pkgs.makeWrapper];

    extraInstallCommands = ''
      # bwrap inherits the environment and bind-mounts /nix, so setting these
      # on the outer script is enough; store paths resolve inside the sandbox.
      wrapProgram $out/bin/bambu-studio \
        `# GLib searches for GIO modules under the *store path* of the glib it` \
        `# was built against, so it never scans the FHS /usr/lib/gio/modules.` \
        `# Without this the gnutls backend is invisible, g_tls_backend_get_default` \
        `# falls back to the dummy one, and the login pane renders the bare text` \
        `# "TLS support is not available".` \
        --set GIO_EXTRA_MODULES ${pkgs.glib-networking}/lib/gio/modules \
        `# Bambu otherwise pops a modal on every start asking permission to use` \
        `# /etc/pki/tls/certs/ca-bundle.crt and telling you to set SSL_CERT_FILE.` \
        --set SSL_CERT_FILE ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
        --set CURL_CA_BUNDLE ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt


      install -Dm444 ${contents}/BambuStudio.desktop \
        $out/share/applications/BambuStudio.desktop
      substituteInPlace $out/share/applications/BambuStudio.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=bambu-studio'
      for size in 32x32 128x128 192x192; do
        install -Dm444 ${contents}/usr/share/icons/hicolor/$size/apps/BambuStudio.png \
          $out/share/icons/hicolor/$size/apps/BambuStudio.png
      done
    '';
  };
in {
  home.packages = [bambu-studio];
}
