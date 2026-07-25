# nixos-config

NixOS + home-manager flake for four machines, all x86_64, all running X11 + i3.

| host          | hostname     | what it is                                    |
| ------------- | ------------ | --------------------------------------------- |
| `desktop`     | `desktop`    | NVIDIA gaming desktop (Steam, CS2, blocky DNS) |
| `laptop`      | `laptop`     | personal laptop                               |
| `work_pc`     | `pcte276928` | CERN desktop, two monitors, `/mnt/lab` sshfs  |
| `work_laptop` | `lapte277203`| CERN laptop, fingerprint reader, `/mnt/lab`   |

## Rebuilding

```sh
# with nh (installed by features/cli), from anywhere
nh os switch ~/00_projects/nixos-config -H <host>

# or plain nixos-rebuild, from the repo root
sudo nixos-rebuild switch --flake .#<host>
```

Check a change without applying it:

```sh
nix flake check          # evaluates all four hosts + checks formatting
nix fmt                  # alejandra over the tree
sudo nixos-rebuild build --flake .#<host>
```

## Layout

```
flake.nix                     inputs, overlays, mkHost (one line per host)
hosts/
  <host>/configuration.nix    only what is unique to that machine
  <host>/hardware-configuration.nix
  shared/global/              imported by every host (boot, nix, locale, fonts, zsh, i3, thunar)
  shared/optional/            opt-in per host (steam, razer, blocky, laptop, cern-lab, performance)
  shared/users/emilis/        the user account
home-manager/
  <host>.nix                  per-host home profile; mostly toggles + startup commands
  global/                     imported by every profile
  features/                   one file per program/feature
  features/cli/               shell-side features (zsh, neovim, tmux, git, ...)
dotfiles/
  .zshrc .zprofile .tmux.conf read into the nix config with builtins.readFile
  rofi/ wallpaper/            assets referenced from the nix store
```

Anything under `hosts/shared/optional/` or `home-manager/features/` is opt-in:
a host gets it by importing it. Cross-cutting toggles use options instead of
imports, so a profile reads as a list of switches:

- `i3Profile.{personal,work,laptopKeys}` — workspace names, window
  assignments and extra keybindings (`home-manager/features/i3-profile.nix`)
- `polybarModules.{gpu,battery,backlight,lhc,marketplace,vpn,dnd}` — which
  polybar modules a host shows (`home-manager/features/polybar.nix`)
- `rofiModes.{remote,passwords}` — extra rofi tabs (`home-manager/features/rofi.nix`)
- `secrets.enable` / `secrets.sshKeys` — sops-nix (`hosts/shared/global/secrets.nix`)
- `nordvpn.enable` + `endpoint`/`publicKey` — WireGuard VPN (`hosts/shared/global/nordvpn.nix`)

## Secrets

Encrypted with [sops-nix](https://github.com/Mic92/sops-nix) into
`secrets/*.yaml`, which are committed; the age keys that open them are not.
`.sops.yaml` holds one slot for the admin key and one per machine.

- `secrets/common.yaml` — ssh private keys, the NordLynx key. Read by NixOS at
  activation on every host.
- `secrets/passwords.yaml` — the password store behind `pw` and the rofi **pw**
  tab. Admin key only; no machine can read it.

Bootstrapping needs key material that can't be committed — the checklist for
that is in `SOPS-SETUP.md` (gitignored).

## VPN

NordVPN over plain WireGuard (NordLynx), no Nord client. `vpn up|down|toggle|
status`, the shield in polybar (left-click toggles, right-click opens a menu),
or the launcher. `nordvpn-pick [country]` prints a current server to paste into
the host config. Off at boot unless `nordvpn.autoStart = true`.

## Clipboard

X11 gives you two selections and no history. `clipmenud` records every copy
(`clipboard.maxClips`, default 400, cleared on reboot):

- **mod+p** or `clip` — history in its own rofi window
- rofi **clip** tab — the same list inside the launcher; picking an entry
  restores it to *both* PRIMARY and CLIPBOARD, which also un-desyncs them

Alacritty copies on selection (`save_to_clipboard`), so the terminal needs no
copy keystroke — that's the habit that makes Ctrl+Shift+C open Firefox's
inspector. Ctrl+Shift+C/V still work, as do Ctrl+Insert/Shift+Insert. In
Firefox, plain **Ctrl+C** copies; flip `disableDevtools` in
`home-manager/features/firefox.nix` if you'd rather lose devtools than have
the inspector pop up.

`pw` pauses clipmenud around its copy, so passwords never reach the history.

## Cheat sheets

**mod+/** (or the rofi **cheat** tab, or `cheat` in a terminal). Curated
entries live in `home-manager/features/cheatsheet/data.nix` — shell operators
and redirection, parameter expansion, tests, vim, this neovim config's own
keymaps, zsh, nix, tmux, i3, and the commands this repo adds. Picking a row
copies its example.

Your own entries go in `~/.local/share/cheatsheet/mine.tsv`, outside the nix
store, so they need no rebuild: `cheat add "syntax" "what it does"`,
`cheat edit`, or the *add an entry of your own* row at the bottom of the rofi
tab.

## Do not disturb

`dnd toggle`, **mod+shift+n**, or the bell in polybar: pauses dunst, blocks
blocky's `social` group where blocky runs, and stops the marketplace poller.
Clears itself at login.

## Neovim

`nvim` is built with [nixvim](https://github.com/nix-community/nixvim) in
`home-manager/features/cli/neovim.nix` — plugins, LSP and keymaps are all in
that file, there is no lua to keep in sync outside the flake. `nnvim` is
[nixy](https://github.com/anotherhadi/nixy)'s nvf-based config, kept around as
a second opinion.

## Adding a host

1. `hosts/<name>/configuration.nix` + `hardware-configuration.nix`
2. `home-manager/<name>.nix`
3. add `"<name>"` to the `hosts` list in `flake.nix`
