{pkgs, ...}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    # gray ghost-text suggestion from history, accept with right arrow
    autosuggestion.enable = true;
    # valid commands turn green as you type, typos red
    syntaxHighlighting.enable = true;

    plugins = [
      {
        # fuzzy-searchable tab completion menu with option descriptions
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
    ];

    initContent = ''
      ${builtins.readFile ../../../dotfiles/.zshrc}

      # fzf-tab: show completion group headers, let fzf own the menu,
      # and preview directory contents when completing cd
      zstyle ':completion:*:descriptions' format '[%d]'
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color ''${(Q)realpath}'
    '';
  };

  # Ctrl+R fuzzy history search, Ctrl+T fuzzy file picker, Alt+C fuzzy cd
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # `tldr <cmd>`: practical usage examples instead of full man pages
  programs.tealdeer = {
    enable = true;
    settings.updates.auto_update = true;
  };
}
