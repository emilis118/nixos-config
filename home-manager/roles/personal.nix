# What every personal machine (desktop, amd-desktop, laptop) gets on top of
# ./global: the i3 session, games and chat. A host imports this and adds only
# what sets it apart — polybar toggles, an xrandr line, the odd extra app.
{
  imports = [
    ../global
    ../features/discord.nix
    ../features/whatsapp.nix
    ../features/postman.nix
    ../features/qemu.nix
    ../features/cli/ani-cli.nix
    ../features/cs2.nix
    ../features/minecraft.nix
    ../features/naruto-arena
    ../features/rs.nix
    ../features/sound.nix
    ../features/wallpaper.nix
    ../features/i3.nix
    ../features/flameshot.nix
    ../features/onlyoffice.nix
  ];

  # workspace names / window assignments live in features/i3-profile.nix
  i3Profile.personal = true;
}
