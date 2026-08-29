{
  # …

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "emilis118";
        email = "uleu2em@gmail.com";
      };

      # zdiff3 puts the common ancestor in the conflict block, so you can see
      # what each side actually changed instead of guessing from two variants.
      merge.conflictstyle = "zdiff3";

      # Records how a conflict was resolved and replays it if the same one
      # comes back — which it does on every commit of a long rebase.
      rerere = {
        enabled = true;
        autoUpdate = true;
      };

      # `git mergetool` opens diffview's 3-way view in nvim (the nixvim
      # wrapper on PATH, see features/cli/neovim.nix). No "run mergetool?"
      # prompt, and no .orig files left behind afterwards.
      merge.tool = "diffview";
      mergetool = {
        prompt = false;
        keepBackup = false;
        diffview.cmd = ''nvim -n -c DiffviewOpen "$MERGED"'';
      };
    };
  };

  # …
}
