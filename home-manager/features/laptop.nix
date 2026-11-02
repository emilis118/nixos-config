# The home-manager side of a laptop, mirroring hosts/shared/optional/laptop.nix
# on the system side: the polybar modules a battery-powered machine wants and
# the brightness keys. Only toggles — the options themselves are declared in
# features/polybar.nix and features/i3-profile.nix, which the roles import.
{
  polybarModules = {
    battery = true;
    backlight = true;
  };

  i3Profile.laptopKeys = true;
}
