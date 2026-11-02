{pkgs, ...}: {
  home.packages = [
    pkgs.discord

    # Mod1+Shift+d in the personal i3 profile (features/i3-profile.nix):
    # start Discord if it isn't running, then jump to its workspace.
    (pkgs.writeShellApplication {
      name = "start-discord";
      runtimeInputs = [pkgs.procps pkgs.discord];
      bashOptions = [];
      text = ''
        pgrep Discord || (discord &)
        i3-msg workspace "9:Discord"
      '';
    })
  ];
}
