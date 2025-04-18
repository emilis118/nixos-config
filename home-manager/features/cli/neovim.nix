{pkgs, ...}: {
  programs.neovim = {
    enable = true;
    # alias
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;
    extraLuaConfig = ''
      ${builtins.readFile ./../../../dotfiles/nvim/lua/emilis/remap.lua}
      ${builtins.readFile ./../../../dotfiles/nvim/lua/emilis/set.lua}
    '';
    extraPackages = with pkgs; [
      nodejs # for some LSP servers
      python312Full # for python
      pyright
      lua-language-server # lua LSP
      rust-analyzer # for rust LSP
      clang-tools # for c/c++
      nixd # nix lsp
      alejandra # nix formatter
      python312Packages.autopep8
      # for neovim
      xclip
      ripgrep
      fd
      gcc # for treesitter
    ];

    plugins = with pkgs.vimPlugins; [
      # regular:
      # config-name
      # or
      # with config:
      # {plugin = config-name; config = ""; type = "lua";}

      {
        plugin = catppuccin-nvim;
        type = "lua";
        config = "vim.cmd('colorscheme catppuccin')";
      }
      # LSP
      {
        plugin = nvim-lspconfig;
        type = "lua";
        config = builtins.readFile ./../../../dotfiles/nvim/after/plugin/lsp.lua;
      }
      nvim-cmp
      cmp-nvim-lsp
      conform-nvim
      # mason-nvim  # idk if use it or not
      # mason-lspconfig-nvim

      # harpoon requirements:
      plenary-nvim
      {
        plugin = telescope-nvim;
        type = "lua";
        config = builtins.readFile ./../../../dotfiles/nvim/after/plugin/telescope.lua;
      }
      {
        plugin = harpoon2;
        type = "lua";
        config = builtins.readFile ./../../../dotfiles/nvim/after/plugin/harpoon.lua;
      }

      (nvim-treesitter.withPlugins (p: [
        p.tree-sitter-nix
        p.tree-sitter-vim
        p.tree-sitter-bash
        p.tree-sitter-lua
        p.tree-sitter-python
        p.tree-sitter-json
        # add others later
      ]))

      # Latex
      {
        plugin = vimtex;
        type = "lua";
        config = ''          vim.g.vimtex_view_method = "zathura"
                  vim.g.vimtex_compiler_method = "tectonic"'';
      }
      texpresso-vim
    ];
  };

  # packages to have
  home.packages = with pkgs; [
    python312Full # to actually run it

    # for PDF
    zathura
    # for latex
    texpresso
    tectonic
  ];
}
