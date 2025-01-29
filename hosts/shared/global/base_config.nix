# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
# enable flakes
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

# Enable networking
    networking.networkmanager.enable = true;
# Enable the X11 windowing system.
    services.xserver.enable = true;
    services.xserver.windowManager.i3.enable = true;
    services.xserver.windowManager.i3.configFile = /home/emilis/dotfiles/i3/config;
    programs.zsh.enable = true;
# Enable the GNOME Desktop Environment.
    # services.xserver.displayManager.gdm.enable = true;
    # services.xserver.desktopManager.gnome.enable = true;

# Configure keymap in X11
    services.xserver.xkb = {
        layout = "us";
        variant = "";
    };

# Enable CUPS to print documents.
    services.printing.enable = true;

# Enable sound with pipewire.
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
    };

# Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    system.stateVersion = "24.11"; # Did you read the comment?

}
