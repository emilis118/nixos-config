{
  # Needed because zsh is the login shell (users/emilis sets shell = pkgs.zsh);
  # the actual interactive config (plugins, completion, aliases from
  # dotfiles/.zshrc) lives in home-manager/features/cli/zsh.nix.
  programs.zsh = {
    enable = true;
    # home-manager runs compinit; avoid doing it twice in /etc/zshrc
    enableCompletion = false;
  };
}
