{inputs, ...}: {
  # The interactive-shell helpers: each one replaces something that was being
  # typed out by hand many times a day.
  imports = [inputs.nix-index-database.homeModules.nix-index];

  # Prompt with the git branch and state (ahead/behind, dirty, staged,
  # untracked) in it, so `git status` is no longer the way to find out where
  # you are. Defaults are fine; ~/.config/starship.toml is not managed, so
  # `programs.starship.settings` here is where tweaks go.
  programs.starship.enable = true;

  # `z nix` jumps to the most-used directory matching "nix" from anywhere;
  # `zi` picks one with fzf. Learns from ordinary cd, nothing to set up.
  programs.zoxide.enable = true;

  # Loads a project's environment on cd and unloads it on the way out,
  # instead of a bare `nix-shell` in every new terminal. One-time setup per
  # project that has a shell.nix:
  #   echo "use nix" > .envrc && direnv allow
  # (`use flake` for a flake.nix). nix-direnv caches the result, so entering
  # is instant after the first time, and pins it as a GC root so the weekly
  # nix.gc doesn't throw the environment away.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # `, psql` runs a program that isn't installed, straight from nixpkgs —
  # what `nix-shell -p postgresql` and then typing the command used to be.
  # The index comes prebuilt from the nix-index-database flake input.
  # nix-index itself also replaces "command not found" with a hint that
  # names the package to use.
  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;
}
