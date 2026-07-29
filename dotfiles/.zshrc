# If not running interactively, don't do anything
[[ -o interactive ]] || return

# Start ssh-agent if not already running
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    eval "$(ssh-agent -s)"
fi

alias ll="ls -al"
alias ls='ls --color=auto'
alias grep='grep --color=auto'
# cat with syntax highlighting. Left as a separate alias rather than
# shadowing cat, which still has to behave itself in pipes and heredocs.
alias c='bat'
PS1='[%n@%m %1~]%# '
alias act="source ./env/bin/activate"
alias shutdown="shutdown -h now"
# hostname, user and key all come from the `lab` block in ~/.ssh/config
# (home-manager/features/cli/ssh.nix)
alias lab="ssh lab"

export PATH="$PATH:$HOME/.local/scripts/"
bindkey -s '^f' "tmux-sessionizer\n"
