#
# ~/.zprofile
#

# Source the ~/.zshrc if it exists (similar to ~/.bashrc in Bash)
[[ -f ~/.zshrc ]] && source ~/.zshrc

# Check if we're not already in an X session and on tty1
if [[ -z "$DISPLAY" && "$(tty)" == "/dev/tty1" ]]; then
    startx
fi
