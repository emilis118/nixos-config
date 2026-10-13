{pkgs, ...}: let
  inherit (pkgs) lib;

  # The storytold "*craft" office/CAD apps (github.com/storytold): Rust + egui
  # clean-room reimplementations, not in nixpkgs. They share one workspace
  # layout (apps/<name>, apps/<name>-cli, packaging/linux, assets/app-icon),
  # so a single builder covers all of them; see ~/00_projects/photoshop for
  # the photocraft one this follows.
  #
  # To bump one: put the new commit in `rev`, set `hash` and `cargoHash` to
  # lib.fakeHash, rebuild and copy the hashes from the two errors.

  # winit / wgpu dlopen these at runtime instead of linking them.
  runtimeLibs = with pkgs; [
    wayland
    libxkbcommon
    libx11
    libxcursor
    libxi
    libxrandr
    libxcb
    vulkan-loader
    libGL
  ];

  mkCraft = {
    pname,
    version,
    rev,
    hash,
    cargoHash,
    description,
    nativeBuildInputs ? [],
    buildInputs ? [],
    extraInstall ? "",
    extraAttrs ? {},
  }:
    pkgs.rustPlatform.buildRustPackage {
      inherit pname version cargoHash buildInputs;

      src = pkgs.fetchFromGitHub {
        owner = "storytold";
        repo = pname;
        inherit rev hash;
      };

      # same two binaries packaging/linux/package.sh ships
      cargoBuildFlags = ["-p" pname "-p" "${pname}-cli"];

      # The workspace test suites are large and some tests need a GPU.
      doCheck = false;

      nativeBuildInputs = [pkgs.makeWrapper] ++ nativeBuildInputs;

      postInstall =
        ''
          install -Dm644 packaging/linux/ai.storyteller.${pname}.desktop -t $out/share/applications
          install -Dm644 packaging/linux/ai.storyteller.${pname}.mime.xml $out/share/mime/packages/ai.storyteller.${pname}.xml
          mkdir -p $out/share/icons
          cp -r assets/app-icon/hicolor $out/share/icons/
        ''
        + extraInstall;

      postFixup = ''
        wrapProgram $out/bin/${pname} \
          --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs}
      '';

      meta = {
        inherit description;
        homepage = "https://github.com/storytold/${pname}";
        license = with lib.licenses; [mit asl20];
        mainProgram = pname;
        platforms = lib.platforms.linux;
      };
    }
    // extraAttrs;

  # pdfcraft's OCR models, normally fetched by `cargo xtask models` at
  # packaging time. The app looks for them in <bin>/../share/pdfcraft/models;
  # hashes are the ones pinned in the repo's ATTRIBUTION.toml.
  ocrModel = name: hash:
    pkgs.fetchurl {
      url = "https://ocrs-models.s3-accelerate.amazonaws.com/${name}.rten";
      inherit hash;
    };
  ocrDetection = ocrModel "text-detection" "sha256-8Vz7Vr0CxL9HiiA0OYZQSh8B4WZcKzoK1mNA8FSxtco=";
  ocrRecognition = ocrModel "text-recognition" "sha256-5ISGbUzOQDF1vY0AsSj+sIq0LiCN4w5CzZiJ2PFzWm4=";

  crafts = [
    (mkCraft {
      pname = "deckcraft";
      version = "0.6.0-unstable-2026-10-12";
      rev = "0ec0cc5e815caea982a7deec51bc437f3ba187ad";
      hash = "sha256-R0V1ijmDeqp3gIxracpPCPOuMPwBU/fuDg5hp38Q+xY=";
      cargoHash = "sha256-RSKO0THT7OFPqxurjIRyDOHAvWgLSxlwPNlp97e/xtI=";
      description = "Create and present slide decks";
      # audio playback for embedded media (alsa-sys)
      nativeBuildInputs = [pkgs.pkg-config];
      buildInputs = [pkgs.alsa-lib];
    })
    (mkCraft {
      pname = "wordcraft";
      version = "0.6.0-unstable-2026-10-12";
      rev = "411ce31de716e3fadf460839f2e89c899a43ae4d";
      hash = "sha256-cvX/MrRZSevLs37/DZovHrHcEeF/IwhxrIdHu9rHszw=";
      cargoHash = "sha256-qmRZElxcrldwF9W/zlzSCovAQuoIRJ3r+ExeQ3MNOqc=";
      description = "Write and design documents; open and save Word files";
    })
    (mkCraft {
      pname = "gridcraft";
      version = "0.6.0-unstable-2026-10-12";
      rev = "b3acae6b7782ea236d0fb87a0121fd1ba2e14c2b";
      hash = "sha256-eMyva7oMaRgQbGkwz3HrtFXicBKm3p17WJU4bTVslJE=";
      cargoHash = "sha256-P6MZ87aZylYSF1aUNayEiCqVxorb643OLV1ylCxo0K0=";
      description = "Calculate, analyse and chart data in workbooks";
    })
    (mkCraft {
      pname = "cadcraft";
      version = "0.6.1-unstable-2026-10-12";
      rev = "4cb9e8a535b2fc51799dc454099c644c235c3efd";
      hash = "sha256-5P5aZTykMLNpQX8+6D8Hpd4qPQsnZwQQpPVhk2G3xVE=";
      cargoHash = "sha256-PPoc+p0SfJQYJGvFqJmLaJe4uYdR5Xv7dHg6gxD6Lbc=";
      description = "Draft, dimension and plot 2D drawings; open DXF and DWG files";
    })
    (mkCraft {
      pname = "pdfcraft";
      version = "0.7.0-unstable-2026-10-12";
      rev = "2839152af172a03b4ccd7d669e1bc265001b04aa";
      hash = "sha256-E0FKjFRxC2az9NSR2nexyxPnoJXDj7fPkKZQaEnuWjY=";
      cargoHash = "sha256-nsOkFjGd5YJk2It0jf1pRd0jPLsm5zrfOVafKnPcG3E=";
      description = "Read, organize, combine, split and secure PDFs";
      # aws-lc-sys (TLS for signature timestamping / revocation checks)
      nativeBuildInputs = [pkgs.cmake pkgs.perl];
      # cmake is only for aws-lc-sys, not the top-level configure phase
      extraAttrs.dontUseCmakeConfigure = true;
      extraInstall = ''
        install -Dm644 ${ocrDetection} $out/share/pdfcraft/models/text-detection.rten
        install -Dm644 ${ocrRecognition} $out/share/pdfcraft/models/text-recognition.rten
      '';
    })
  ];
in {
  home.packages = crafts;
}
