{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    # alias
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;
    # extraLuaConfig = ''
    #   -- ${builtins.readFile ./something.lua}
    # '';
    
    plugins = with pkgs.vimPlugins; [
        # regular:
        # config-name
        # or
        # with config:
        # {plugin = config-name; config = ""; type = "lua";}
        {
            plugin = catppucin-nvim;
            type = "lua";
            config = "colorscheme catppucin";
        }
        # harpoon requirements:
        plenary-nvim
        telescope-nvim
        {
            plugin = harpoon2; 
            type = "lua";
            config = builtins.readFile ./../../../dotfiles/nvim/after/plugin/harpoon.lua;
        }

        (nvim-treesitter.withPlugins (p: [
            p.tree-sitter.nix
            p.tree-sitter.vim
            p.tree-sitter.bash
            p.tree-sitter.lua
            p.tree-sitter.python
            p.tree-sitter.json
# add others later
        ]))
    ];
  };

  # packages to have
  home.packages = with pkgs; [
    xclip
    ripgrep
    fd
    gcc
  ];
}
