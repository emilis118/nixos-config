# If not running interactively, don't do anything
[[ -o interactive ]] || return

alias ll="ls -al"
alias ls='ls --color=auto'
alias grep='grep --color=auto'
# cat with syntax highlighting. Left as a separate alias rather than
# shadowing cat, which still has to behave itself in pipes and heredocs.
alias c='bat'
alias act="source ./env/bin/activate"
alias shutdown="shutdown -h now"
# hostname, user and key all come from the `lab` block in ~/.ssh/config
# (home-manager/features/cli/ssh.nix)
alias lab="ssh lab"

# Ctrl+F: pick a project and just cd into it. Has to be a widget rather
# than a script, since a child process can't change this shell's directory.
project-cd-widget() {
  local dir
  dir=$(project-pick)
  [[ -n $dir ]] && cd "$dir"
  zle reset-prompt
}
zle -N project-cd-widget
bindkey '^f' project-cd-widget

# Ctrl+Shift+F: tmux-sessionizer. Terminals send ^F for both Ctrl+F and
# Ctrl+Shift+F, so alacritty is told to send ESC F (Alt+Shift+F) for the
# shifted chord instead (features/cli/alacritty.nix). That also passes
# through tmux untouched.
bindkey -s '^[F' "tmux-sessionizer\n"
# ...and by name, for terminals that aren't alacritty (ssh, the tty)
alias ts="tmux-sessionizer"

# git, the four that make up nearly every session
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
