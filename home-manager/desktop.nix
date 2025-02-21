{
  imports = [
    ./global # default.nix
    ./features/discord.nix
    ./features/postman.nix
  ];

  nixpkgs.config.allowUnfree = true;
}
