{...}: {
  # CERN DFS (WebDAV) shortcut in the Thunar/GTK sidebar — same as the
  # davs:// link you used in Nautilus. gvfs prompts for your CERN
  # credentials on connect; nothing is stored in this repo.
  # The davfs2 client itself is enabled in hosts/shared/optional/cern-lab.nix.
  xdg.configFile."gtk-3.0/bookmarks".text = ''
    davs://dfs.cern.ch/dfs/ CERN DFS
  '';
}
