# If not running interactively, don't do anything
[[ -o interactive ]] || return

# Start ssh-agent if not already running
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    eval "$(ssh-agent -s)"
fi

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[%n@%m %1~]%# '
alias i3cfg="nvim ~/.config/i3/config"
alias jabra="bluetoothctl connect 50:C2:E2:37:22:84"
alias pacman="sudo pacman"
alias act="source ./env/bin/activate"
alias shutdown="shutdown -h now"

export PATH="$PATH:$HOME/.local/scripts/"
bindkey -s '^f' "tmux-sessionizer\n"
