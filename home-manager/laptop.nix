# Single internal display: same layout as the desktops but no xrandr pinning.
{
  imports = [
    ./roles/personal.nix
    ./features/laptop.nix
  ];
}
