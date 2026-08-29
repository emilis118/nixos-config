{
  pkgs,
  inputs,
  ...
}: let
  # The whole neovim setup, in nix. This replaced the older
  # programs.neovim + readFile dotfiles/nvim/*.lua arrangement, so the lua
  # lives here and there is nothing to keep in sync outside the flake.
  nvim = inputs.nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system}.makeNixvimWithModule {
    inherit pkgs;
    module = {
      # lua/emilis/set.lua
      opts = {
        nu = true;
        relativenumber = true;

        tabstop = 4;
        softtabstop = 4;
        shiftwidth = 4;
        expandtab = true;

        smartindent = true;

        wrap = false;

        swapfile = false;
        backup = false;
        undodir.__raw = ''os.getenv("HOME") .. "/.vim/undodir"'';
        undofile = true;

        hlsearch = false;
        incsearch = true;

        termguicolors = true;

        scrolloff = 8;
        signcolumn = "yes";

        updatetime = 50;
      };
      extraConfigLua = ''
        vim.opt.isfname:append("@-@")
      '';

      globals.mapleader = " ";

      # lua/emilis/remap.lua + the plugin keymaps from after/plugin/*.lua
      keymaps = [
        {
          mode = "n";
          key = "<leader>pv";
          action.__raw = "vim.cmd.Ex";
        }

        # judina pazymeta teksta aukstyn zemyn, imeta i if blocks
        {
          mode = "v";
          key = "J";
          action = ":m '>+1<CR>gv=gv";
        }
        {
          mode = "v";
          key = "K";
          action = ":m '<-2<CR>gv=gv";
        }

        # kai perkeli eilute aukstyn lieka cursor vietoj
        {
          mode = "n";
          key = "J";
          action = "mzJ`z";
        }
        # half page jumps sucentruoja
        {
          mode = "n";
          key = "<C-d>";
          action = "<C-d>zz";
        }
        {
          mode = "n";
          key = "<C-u>";
          action = "<C-u>zz";
        }
        # kai searchini ir sokineji padaro vaizda viduryje
        {
          mode = "n";
          key = "n";
          action = "nzzzv";
        }
        {
          mode = "n";
          key = "N";
          action = "Nzzzv";
        }

        # greatest remap ever
        # nukopijuota teksta paste ant pazymeto teksto ir islaiko clipboarda
        {
          mode = "x";
          key = "<leader>p";
          action = ''"_dP'';
        }

        # i system clipboarda nukopijuoja, istraukia is Vim
        {
          mode = ["n" "v"];
          key = "<leader>y";
          action = ''"+y'';
        }
        {
          mode = "n";
          key = "<leader>Y";
          action = ''"+Y'';
        }

        {
          mode = ["n" "v"];
          key = "<leader>d";
          action = ''"_d'';
        }

        {
          mode = "i";
          key = "<C-c>";
          action = "<Esc>";
        }

        {
          mode = "n";
          key = "Q";
          action = "<nop>";
        }
        {
          mode = "n";
          key = "<C-f>";
          action = "<cmd>silent !tmux neww tmux-sessionizer<CR>";
        }

        {
          mode = "n";
          key = "<C-k>";
          action = "<cmd>cnext<CR>zz";
        }
        {
          mode = "n";
          key = "<C-j>";
          action = "<cmd>cprev<CR>zz";
        }
        {
          mode = "n";
          key = "<leader>k";
          action = "<cmd>lnext<CR>zz";
        }
        {
          mode = "n";
          key = "<leader>j";
          action = "<cmd>lprev<CR>zz";
        }

        {
          mode = "n";
          key = "<leader>s";
          action = '':%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>'';
        }
        {
          mode = "n";
          key = "<leader>x";
          action = "<cmd>!chmod +x %<CR>";
          options.silent = true;
        }

        {
          mode = "n";
          key = "<leader>mr";
          action = "<cmd>CellularAutomaton make_it_rain<CR>";
        }

        {
          mode = "n";
          key = "<leader><leader>";
          action.__raw = ''
            function()
                vim.cmd("so")
            end
          '';
        }

        # after/plugin/lsp.lua
        {
          mode = "n";
          key = "gd";
          action.__raw = "vim.lsp.buf.definition";
          options.desc = "Go to Definition";
        }
        {
          mode = "n";
          key = "K";
          action.__raw = "vim.lsp.buf.hover";
          options.desc = "Hover Documentation";
        }
        {
          mode = "n";
          key = "<leader>rn";
          action.__raw = "vim.lsp.buf.rename";
          options.desc = "Rename Symbol";
        }
        {
          mode = "n";
          key = "<leader>ca";
          action.__raw = "vim.lsp.buf.code_action";
          options.desc = "Code Action";
        }
        {
          mode = "n";
          key = "gr";
          action.__raw = "require('telescope.builtin').lsp_references";
        }
        {
          mode = "n";
          key = "<leader>f";
          action.__raw = ''
            function()
              require("conform").format()
            end
          '';
          options.desc = "Format file";
        }

        # after/plugin/telescope.lua
        {
          mode = "n";
          key = "<leader>pf";
          action.__raw = "require('telescope.builtin').find_files";
        }
        {
          mode = "n";
          key = "<C-p>";
          action.__raw = "require('telescope.builtin').git_files";
        }
        {
          mode = "n";
          key = "<leader>ps";
          action.__raw = ''
            function()
                require('telescope.builtin').grep_string({ search = vim.fn.input("Grep > ")})
            end
          '';
        }

        # after/plugin/harpoon.lua
        {
          mode = "n";
          key = "<leader>a";
          action.__raw = ''function() require("harpoon"):list():add() end'';
        }
        {
          mode = "n";
          key = "<C-e>";
          action.__raw = ''function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end'';
        }
        {
          mode = "n";
          key = "<C-h>";
          action.__raw = ''function() require("harpoon"):list():select(1) end'';
        }
        {
          mode = "n";
          key = "<C-t>";
          action.__raw = ''function() require("harpoon"):list():select(2) end'';
        }
        {
          mode = "n";
          key = "<C-n>";
          action.__raw = ''function() require("harpoon"):list():select(3) end'';
        }
        {
          mode = "n";
          key = "<C-s>";
          action.__raw = ''function() require("harpoon"):list():select(4) end'';
        }
        # Toggle previous & next buffers stored within Harpoon list
        {
          mode = "n";
          key = "<M-.>";
          action.__raw = ''function() require("harpoon"):list():prev() end'';
        }
        {
          mode = "n";
          key = "<M-,>";
          action.__raw = ''function() require("harpoon"):list():next() end'';
        }
      ];

      colorschemes.catppuccin.enable = true;

      plugins = {
        transparent.enable = true;

        # LSP servers as in after/plugin/lsp.lua; nixvim wires the
        # cmp_nvim_lsp capabilities itself when cmp is enabled
        lsp = {
          enable = true;
          servers = {
            lua_ls.enable = true;
            clangd.enable = true;
            rust_analyzer = {
              enable = true;
              installCargo = false;
              installRustc = false;
            };
            pyright.enable = true;
            nixd.enable = true;
            marksman.enable = true;
          };
        };

        cmp = {
          enable = true;
          settings = {
            sources = [{name = "nvim_lsp";}];
            mapping = {
              "<Tab>" = "cmp.mapping.select_next_item()";
              "<S-Tab>" = "cmp.mapping.select_prev_item()";
              "<CR>" = "cmp.mapping.confirm({ select = true })";
            };
          };
        };

        conform-nvim = {
          enable = true;
          settings = {
            formatters_by_ft = {
              nix = ["alejandra"];
              python3 = ["autopep8"];
            };
            format_on_save = {
              timeout_ms = 1000;
            };
          };
        };

        # 3-way merge UI + diff/file-history browser. Set as git's mergetool
        # in features/cli/git.nix, so `git mergetool` lands here.
        diffview.enable = true;

        telescope.enable = true;
        # telescope pulls this in anyway; explicit to silence the
        # nixvim deprecation warning about implicit enabling
        web-devicons.enable = true;
        harpoon.enable = true;

        treesitter = {
          enable = true;
          # same grammars as nvim-treesitter.withPlugins in neovim.nix
          grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
            nix
            vim
            bash
            lua
            python
            json
            latex
          ];
        };

        # Latex
        vimtex = {
          enable = true;
          # tectonic instead of texlive, like the main setup
          texlivePackage = null;
          settings = {
            view_method = "zathura";
            compiler_method = "tectonic";
          };
        };
      };

      extraPlugins = [pkgs.vimPlugins.texpresso-vim];

      extraPackages = with pkgs; [
        nodejs # for some LSP servers
        python3 # for python
        alejandra # nix formatter
        python314Packages.autopep8
        # for neovim
        xclip
        ripgrep
        fd
        gcc # for treesitter
      ];
    };
  };
in {
  home.packages = with pkgs; [
    nvim

    # vi/vim/vimdiff aliases, as programs.neovim's viAlias/vimAlias/
    # vimdiffAlias used to provide
    (runCommand "nvim-aliases" {} ''
      mkdir -p $out/bin
      ln -s ${nvim}/bin/nvim $out/bin/vi
      ln -s ${nvim}/bin/nvim $out/bin/vim
    '')
    (writeShellScriptBin "vimdiff" ''exec ${nvim}/bin/nvim -d "$@"'')

    # nixy's neovim (github:anotherhadi/nixy) under a separate name, as a
    # second opinion — it doesn't touch the setup above
    (runCommand "nnvim" {} ''
      mkdir -p $out/bin
      ln -s ${nixy-nvim}/bin/nvim $out/bin/nnvim
    '')

    # nixvim wraps its own python3 for the plugins; this is the plain
    # interpreter on PATH, as the previous programs.neovim setup provided
    python3

    # PDF viewer for vimtex (view_method = "zathura")
    zathura
  ];
}
