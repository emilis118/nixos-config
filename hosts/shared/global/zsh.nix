{
    programs.zsh = {
        enable = true;
        autosuggestions.enable = true;
        shellInit = builtins.readFile ../../../dotfiles/.zshrc;
        };
}
