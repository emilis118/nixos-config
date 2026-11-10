# What both CERN machines (work_pc, work_laptop) get on top of ./global: the
# i3 session, the lab/remote tooling and the office apps. A host imports this
# and adds only what sets it apart — monitor layout, polybar toggles, an extra
# app or two.
{pkgs, ...}: {
  imports = [
    ../global
    ../features/qemu.nix
    ../features/wallpaper.nix
    ../features/i3.nix
    ../features/remote.nix
    ../features/onlyoffice.nix
    ../features/mattermost.nix
    ../features/flameshot.nix
    ../features/whatsapp.nix
    ../features/thunderbird.nix
    ../features/cern-dfs.nix
    ../features/bambu-studio.nix
    ../features/crafts.nix
  ];

  # workspace names / window assignments live in features/i3-profile.nix
  i3Profile.work = true;

  home.packages = [
    # psql for the lab databases (was `nix-shell -p postgresql` each time)
    pkgs.postgresql

    # `lab-sync`, run from a project directory: copy it to the folder of the
    # same name on the lab share (/mnt/lab, see hosts/shared/optional/
    # cern-lab.nix). Replaces `cp -r ./* /mnt/lab/<name>`: same result — top-
    # level dotfiles such as .git stay behind, nothing on the far side is
    # deleted — but only files that changed cross the sshfs link.
    # `lab-sync other_name` overrides the destination folder; -n previews.
    (pkgs.writeShellApplication {
      name = "lab-sync";
      runtimeInputs = [pkgs.rsync pkgs.coreutils];
      text = ''
        dry=()
        if [ "''${1:-}" = "-n" ]; then
          dry=(--dry-run)
          shift
        fi
        dest="/mnt/lab/''${1:-$(basename "$PWD")}"
        if [ ! -d "$dest" ]; then
          echo "lab-sync: $dest does not exist (is /mnt/lab mounted? wrong directory?)" >&2
          exit 1
        fi
        # -rt, not -a: the share is sshfs as another user, so owners and
        # permissions can't be carried over and would only produce errors.
        rsync -rtv "''${dry[@]}" --exclude='/.*' ./ "$dest/"
      '';
    })
  ];

  # off while the beam is down (LS3); flip when the LHC is back
  polybarModules.lhc = false;
}
