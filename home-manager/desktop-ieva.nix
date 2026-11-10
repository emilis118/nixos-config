# Ieva's profile on `desktop`.
#
# Deliberately does not import ./global — that
# one hardcodes emilis' username, home directory and FLAKE path, and pulls in
# the rofi/dunst/polybar tooling that belongs to the i3 session.
#
# The desktop itself is Plasma 6 (hosts/shared/optional/kde.nix, which brings
# dolphin), Steam is system-wide (optional/steam.nix), and Chrome as the PDF
# and web default is set in hosts/desktop. Only the per-user parts are here.
{
  pkgs,
  lib,
  osConfig,
  inputs,
  ...
}: let
  # same pinned build features/minecraft.nix installs
  prismlauncher = inputs.nixpkgs-prism.legacyPackages.${pkgs.stdenv.hostPlatform.system}.prismlauncher;

  # Separate launchers for each OnlyOffice editor. The package only ships one
  # .desktop file (the start page); --new:<kind> opens a blank document of
  # that kind straight away.
  officeEditor = kind: name: icon:
    pkgs.makeDesktopItem {
      name = "onlyoffice-${kind}";
      desktopName = name;
      exec = "onlyoffice-desktopeditors --new:${kind}";
      inherit icon;
      categories = ["Office"];
    };
  officeEditors = [
    (officeEditor "word" "Document" "x-office-document")
    (officeEditor "cell" "Spreadsheet" "x-office-spreadsheet")
    (officeEditor "slide" "Presentation" "x-office-presentation")
  ];

  # Desktop icons: each entry is the app's own .desktop file, copied into
  # ~/Desktop, where Plasma's desktop shows it. `executable` matters: Plasma
  # only runs a launcher outside the applications directories without an
  # "untrusted program" prompt if the file is executable.
  desktopIcons = {
    "org.kde.dolphin.desktop" = pkgs.kdePackages.dolphin; # file explorer
    "google-chrome.desktop" = pkgs.google-chrome;
    "spotify.desktop" = pkgs.spotify;
    "steam.desktop" = osConfig.programs.steam.package;
    "com.github.dagmoller.whatsapp-electron.desktop" = pkgs.whatsapp-electron;
    "discord.desktop" = pkgs.discord;
    "org.prismlauncher.PrismLauncher.desktop" = prismlauncher;
    "onlyoffice-desktopeditors.desktop" = pkgs.onlyoffice-desktopeditors;
    "onlyoffice-word.desktop" = builtins.elemAt officeEditors 0;
    "onlyoffice-cell.desktop" = builtins.elemAt officeEditors 1;
    "onlyoffice-slide.desktop" = builtins.elemAt officeEditors 2;
  };

  # pinned to the taskbar, left to right
  taskbarApps = [
    "org.kde.dolphin.desktop"
    "google-chrome.desktop"
    "onlyoffice-desktopeditors.desktop"
    "spotify.desktop"
    "com.github.dagmoller.whatsapp-electron.desktop"
    "discord.desktop"
    "steam.desktop"
  ];
in {
  programs.home-manager.enable = true;

  home.username = "ieva";
  home.homeDirectory = "/home/ieva";
  home.stateVersion = "26.05";

  imports = [
    inputs.plasma-manager.homeModules.plasma-manager
    ./features/minecraft.nix # prismlauncher
    ./features/onlyoffice.nix
    ./features/whatsapp.nix
    ./features/cs2.nix # MangoHud overlay; the Steam launch options in it are a manual step
  ];

  home.packages =
    [
      pkgs.google-chrome
      pkgs.spotify
      pkgs.discord
      pkgs.fluent-icon-theme # Windows 11-style icons, see workspace below
    ]
    # in the app menu too, not just on the desktop
    ++ officeEditors;

  home.file = lib.mapAttrs' (file: pkg:
    lib.nameValuePair "Desktop/${file}" {
      source = "${pkg}/share/applications/${file}";
      executable = true;
    })
  desktopIcons;

  # Make Plasma feel like Windows 11. plasma-manager writes these keys into
  # Plasma's own config files on every switch and leaves every other key
  # alone (overrideConfig stays false), so anything Ieva changes in System
  # Settings that isn't listed here sticks.
  programs.plasma = {
    enable = true;

    workspace = {
      colorScheme = "BreezeLight";
      iconTheme = "Fluent";
      cursor.theme = "Breeze_Light"; # white arrow, like Windows
      # single click selects, double click opens
      clickItemTo = "select";
    };

    # Windows-style taskbar: start menu and pinned apps on the left (the task
    # list fills the middle), tray and clock on the right, the show-desktop
    # sliver at the far end. Declaring panels
    # makes plasma-manager rebuild them at login whenever this list changes;
    # it does so by deleting plasma-org.kde.plasma.desktop-appletsrc, so any
    # widgets added by hand on the panel or desktop go with it then. The
    # icons in ~/Desktop are files and survive that.
    panels = [
      {
        location = "bottom";
        height = 48;
        floating = false;
        widgets = [
          "org.kde.plasma.kickoff"
          {
            iconTasks.launchers = map (app: "applications:${app}") taskbarApps;
          }
          "org.kde.plasma.systemtray" # shows the keyboard layout too
          {
            digitalClock.date = {
              enable = true;
              position = "belowTime";
            };
          }
          "org.kde.plasma.showdesktop"
        ];
      }
    ];

    # US, Lithuanian, French. Win+Space cycles, the same chord as the system
    # default in hosts/desktop (Plasma's own Meta+Alt+K works too).
    input.keyboard = {
      layouts = [
        {layout = "us";}
        {layout = "lt";}
        {layout = "fr";}
      ];
      options = ["grp:win_space_toggle"];
      numlockOnStartup = "on";
    };
  };
}
