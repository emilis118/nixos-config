{
  pkgs,
  lib,
  ...
}: let
  # ani-cli scrapes sites that change without warning, so a pinned copy is
  # broken more often than not. Fetch master on every launch instead.
  #
  # The fetch has to happen at runtime, not at eval time: a flake can only
  # fetch sources that are pinned by hash, so anything resolved during the
  # build is exactly as stale as the pin. What Nix provides here is the
  # dependency closure the script needs, plus the last-resort fallbacks.
  ani-cli-master = pkgs.writeShellApplication {
    name = "ani-cli";
    runtimeInputs = with pkgs; [
      openssl # for the `openssl` binary the decrypt path uses
      gnugrep
      gnused
      curl
      fzf
      ffmpeg
      aria2
    ];
    text = ''
      # mpv goes on the *end* of PATH so a user-configured mpv still wins
      export PATH="$PATH:${lib.makeBinPath [pkgs.mpv]}"

      url=https://raw.githubusercontent.com/pystardust/ani-cli/master/ani-cli
      cache="''${XDG_CACHE_HOME:-$HOME/.cache}/ani-cli"
      script="$cache/ani-cli-master"
      mkdir -p "$cache"

      if curl -fsSL --max-time 15 -o "$script.new" "$url" \
        && [ -s "$script.new" ] \
        && head -n 1 "$script.new" | grep -q '^#!'; then
        mv "$script.new" "$script"
        chmod +x "$script"
      else
        rm -f "$script.new"
        if [ -f "$script" ]; then
          echo "ani-cli: could not reach GitHub, using last fetched copy" >&2
        else
          # nothing fetched yet (first run offline) — use the pinned nixpkgs one
          echo "ani-cli: could not reach GitHub, using nixpkgs ${pkgs.ani-cli.version}" >&2
          exec ${lib.getExe pkgs.ani-cli} "$@"
        fi
      fi

      exec ${lib.getExe pkgs.bash} "$script" "$@"
    '';
  };
in {
  home.packages = [
    ani-cli-master
    pkgs.ani-skip
    pkgs.mov-cli
  ];

  programs.zsh.shellAliases.ani = "ani-cli";
}
