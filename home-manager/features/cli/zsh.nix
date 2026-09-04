{
  pkgs,
  lib,
  ...
}: {
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

  # home-manager's tealdeer module schedules `tldr --update` on an
  # OnCalendar=weekly timer with Persistent=true. This machine is almost
  # never on when the weekly trigger comes due, so systemd runs the
  # catch-up immediately at session start - before DNS is up - and the
  # unit dies with "failed to lookup address information". It then sits
  # in `failed` until the next boot, which is what lights up the red
  # counter in polybar's failed-units module.
  #
  # So wait for the network to actually be reachable before updating, and
  # treat "still offline" as nothing-to-do rather than a failure: a laptop
  # with no network isn't a broken cache update. A real error from tldr
  # itself still propagates and still shows up in polybar.
  systemd.user.services.tldr-update.Service.ExecStart = lib.mkForce (
    pkgs.writeShellScript "tldr-update-when-online" ''
      # ~5 min of grace; each probe covers DNS + TCP + TLS, which is
      # exactly what the cache download needs.
      for _ in $(seq 60); do
        if ${pkgs.curl}/bin/curl -sSf --max-time 5 -o /dev/null \
            https://github.com 2>/dev/null; then
          exec ${pkgs.tealdeer}/bin/tldr --update
        fi
        sleep 5
      done

      echo "no network after 5 minutes; skipping tldr cache update"
    ''
  );
}
