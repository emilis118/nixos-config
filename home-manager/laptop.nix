{
  imports = [
    ./global # default.nix
    ./features/discord.nix
    ./features/postman.nix
    ./features/qemu.nix
    ./features/cli/ani-cli.nix
    ./features/cs2.nix
    ./features/minecraft.nix
    ./features/naruto-arena
    ./features/rs.nix
    ./features/sound.nix
    ./features/wallpaper.nix
    ./features/i3.nix
    ./features/flameshot.nix
  ];

  polybarModules = {
    battery = true;
    backlight = true;
  };

  # Single internal display: same layout as desktop but no xrandr pinning.
  # Workspace names / window assignments live in features/i3-profile.nix.
  i3Profile = {
    personal = true;
    laptopKeys = true;
  };
}
