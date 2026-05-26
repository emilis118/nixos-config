{
  config,
  pkgs,
  ...
}: let
  bash_ct_src = pkgs.fetchFromGitHub {
    owner = "JB63134";
    repo = "bash_ct";
    rev = "main"; # or pin to a commit hash for full reproducibility
    sha256 = "sha256-05bddikdb50wyzigj226mi3lmhp9wwyzbspxgpyk199cqswwmd92";
  };

  bash_ct = pkgs.writeShellScriptBin "bash_ct" ''
    source ${bash_ct_src}/.bash_ct
  '';
in {
  # environment.systemPackages = [
  #   bash_ct
  # ];
  #
  programs.bash.interactiveShellInit = ''
    # Auto-load bash_ct for interactive shells
    source ${bash_ct_src}/.bash_ct
  '';
}
