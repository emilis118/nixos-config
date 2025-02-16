{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    baseIndex = 1;

    extraConfig = builtins.readFile ../../../dotfiles/.tmux.conf;

    plugins = with pkgs; [
      tmuxPlugins.resurrect
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
        '';
      }
    ];
  };

  home.packages = [
    (
      pkgs.writeShellScriptBin "tmux-sessionizer"
      ''
        #!/usr/bin/env bash

        if [[ $# -eq 1 ]]; then
            selected=$1
        else
            selected=$(find ~/00_projects ~/01_learning -mindepth 1 -maxdepth 1 -type d | fzf)
        fi

        if [[ -z $selected ]]; then
            exit 0
        fi

        selected_name=$(basename "$selected" | tr . _)
        tmux_running=$(pgrep tmux)

        if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
            tmux new-session -s $selected_name -c $selected
            exit 0
        fi

        if ! tmux has-session -t=$selected_name 2> /dev/null; then
            tmux new-session -ds $selected_name -c $selected
        fi

        if [[ -z $TMUX ]]; then
            tmux attach -t $selected_name
        else
            tmux switch-client -t $selected_name
        fi
      ''
    )

    pkgs.fzf
  ];
}
