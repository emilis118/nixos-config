{
  # enable flakes
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Without this the store only ever grows: every rebuild adds a generation
  # and nothing removes the old ones.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Hard-link identical files in the store. Costs some IO during the run,
  # saves a lot of disk on a config with four similar systems' worth of
  # closures.
  nix.optimise.automatic = true;
}
