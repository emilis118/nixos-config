# TEMP-IEVA — temporary: this whole file goes when ieva no longer uses
# amd-desktop. See the TEMP-IEVA block in hosts/amd-desktop/configuration.nix
# for the full removal list.
#
# mkHost in flake.nix looks up ./<host>-<user>.nix, so this name is required;
# the profile itself is identical to the `desktop` one, so re-import that
# rather than keeping two copies of the same package list in sync.
{...}: {
  imports = [./desktop-ieva.nix];
}
