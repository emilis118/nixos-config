{
  pkgs,
  config,
  ...
}: let
  # Second, independent Claude Code profile (personal account). Claude Code
  # keeps everything (login credentials, .claude.json, settings, history,
  # memory) under $CLAUDE_CONFIG_DIR, so pointing it elsewhere gives a fully
  # separate profile. Plain `claude` keeps using ~/.claude as before.
  claudePersonal = pkgs.writeShellScriptBin "claude-p" ''
    export CLAUDE_CONFIG_DIR="${config.home.homeDirectory}/.claude-personal"
    exec ${pkgs.claude-code}/bin/claude "$@"
  '';
in {
  home.packages = [pkgs.claude-code claudePersonal];
}
