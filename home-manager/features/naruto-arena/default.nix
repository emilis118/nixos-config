{pkgs, ...}: let
  # naruto-arena.site in its own window. There is nothing to install — the
  # game is a Next.js app on their server — so the whole "package" is electron
  # pointed at the main process in ./main.js.
  packageJson = pkgs.writeText "package.json" (builtins.toJSON {
    name = "naruto-arena";
    version = "1.0.0";
    main = "main.js";
  });

  appDir = pkgs.runCommand "naruto-arena-app" {} ''
    mkdir -p $out
    cp ${./main.js} $out/main.js
    cp ${packageJson} $out/package.json
  '';

  naruto-arena = pkgs.writeShellScriptBin "naruto-arena" ''
    # --class pins WM_CLASS: chromium otherwise derives it from argv[0], which
    # here is "electron" and would be shared with every other electron app, so
    # the i3 assign in features/i3-profile.nix could not match. Confirm with
    # `xprop WM_CLASS` if the window ever stops landing on the game workspace.
    exec ${pkgs.electron}/bin/electron ${appDir} --class=naruto-arena "$@"
  '';
in {
  home.packages = [naruto-arena];

  # rofi's drun mode (alt+d) lists desktop entries, so this is the bit that
  # makes it launchable from there; the `naruto-arena` command still works on
  # its own. No bundled icon — using a stock Papirus one keeps their artwork
  # out of this repo.
  xdg.desktopEntries.naruto-arena = {
    name = "Naruto Arena";
    genericName = "Browser game";
    exec = "naruto-arena";
    icon = "applications-games";
    terminal = false;
    categories = ["Game"];
    # what you'd type in rofi to find it
    settings.Keywords = "naruto;arena;game;";
  };
}
