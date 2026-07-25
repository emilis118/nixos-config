# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{pkgs, ...}: {
  # Enable networking
  networking.networkmanager.enable = true;

  # bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # programs.zsh.enable = true;
  environment.systemPackages = with pkgs; [
    pamixer
  ];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us,lt";
    variant = "";
    # Win+Space cycles us -> lt. xkeyboard-config has no Win+Shift chord for
    # group switching (grep `grp:` in xkeyboard-config's rules/base.lst), and
    # a bare Win toggle would fight i3's Mod4 bindings, so Win+Space — the
    # Windows-native shortcut — is the closest conflict-free equivalent.
    # terminate:ctrl_alt_bksp is the NixOS default for this option; setting
    # it here replaces the default outright, so it has to be repeated.
    options = "terminate:ctrl_alt_bksp,grp:win_space_toggle";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}
