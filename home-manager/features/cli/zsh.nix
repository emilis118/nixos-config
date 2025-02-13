{pkgs, ...}:

{

    programs.zsh = {
        autocd = true;
        autosuggestion.enable = true;

        initExtra = builtins.readFile ./../../../dotfiles/.zshrc;

    };

}
