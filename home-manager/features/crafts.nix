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

  crafts = [
    (mkCraft {
      pname = "cadcraft";
      version = "0.6.1-unstable-2026-10-12";
      rev = "4cb9e8a535b2fc51799dc454099c644c235c3efd";
      hash = "sha256-5P5aZTykMLNpQX8+6D8Hpd4qPQsnZwQQpPVhk2G3xVE=";
      cargoHash = "sha256-PPoc+p0SfJQYJGvFqJmLaJe4uYdR5Xv7dHg6gxD6Lbc=";
      description = "Draft, dimension and plot 2D drawings; open DXF and DWG files";
    })
  ];
in {
  home.packages = crafts;
}
