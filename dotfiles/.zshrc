# If not running interactively, don't do anything
[[ -o interactive ]] || return

# Start ssh-agent if not already running
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    eval "$(ssh-agent -s)"
fi

alias ll="ls -al"
alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[%n@%m %1~]%# '
alias act="source ./env/bin/activate"
alias shutdown="shutdown -h now"

export PATH="$PATH:$HOME/.local/scripts/"
bindkey -s '^f' "tmux-sessionizer\n"
