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
    # The project list + fzf picker, shared by tmux-sessionizer (Ctrl+Shift+F)
    # and the plain cd widget in .zshrc (Ctrl+F). Prints the chosen dir.
    # Searches every numbered top-level folder in ~ (00_projects,
    # 01_learning, 02_whatever, ...), so a new one is picked up on its own.
    (
      pkgs.writeShellApplication {
        name = "project-pick";
        bashOptions = [];
        text = ''
          shopt -s nullglob
          roots=(~/[0-9][0-9]_*/)
          [[ ''${#roots[@]} -eq 0 ]] && exit 0
          find "''${roots[@]}" -mindepth 1 -maxdepth 1 -type d | fzf
        '';
      }
    )

    (
      pkgs.writeShellApplication {
        name = "tmux-sessionizer";
        bashOptions = [];
        text = ''
          if [[ $# -eq 1 ]]; then
              selected=$1
          else
              selected=$(project-pick)
          fi

          if [[ -z "$selected" ]]; then
              exit 0
          fi

          selected_name=$(basename "$selected" | tr . _)
          tmux_running=$(pgrep tmux)

          if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
              tmux new-session -s "$selected_name" -c "$selected"
              exit 0
          fi

          if ! tmux has-session -t="$selected_name" 2> /dev/null; then
              tmux new-session -ds "$selected_name" -c "$selected"
          fi

          if [[ -z $TMUX ]]; then
              tmux attach -t "$selected_name"
          else
              tmux switch-client -t "$selected_name"
          fi
        '';
      }
    )

    pkgs.fzf
  ];
}
