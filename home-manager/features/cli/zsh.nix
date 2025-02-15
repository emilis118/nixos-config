{pkgs, ...}:

{

    programs.zsh = {
        enable = true;
        autocd = true;
        autosuggestion.enable = true;

        initExtra = builtins.readFile ./../../../dotfiles/.zshrc;

    };

}
