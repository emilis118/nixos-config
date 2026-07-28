# Cheat sheet entries, in the same spirit as bookmarks.nix: plain data, edited
# here, surfaced by features/cheatsheet/default.nix as the rofi "cheat" tab and
# the `cheat` command.
#
#   cat     short group name, shown in brackets and searchable
#   syntax  the thing you're trying to remember
#   desc    one line, no wrapping
#   example something runnable; this is what gets copied on select ("" = copy
#           the syntax instead)
#
# Keep every field on one line — the list is rendered as TSV.
[
  # --- the operators you actually came here for -----------------------------
  {
    cat = "shell";
    syntax = "a | b";
    desc = "pipe: a's stdout becomes b's stdin (stderr not included)";
    example = "ps aux | grep firefox";
  }
  {
    cat = "shell";
    syntax = "a |& b";
    desc = "pipe stdout AND stderr; same as a 2>&1 | b";
    example = "make |& less";
  }
  {
    cat = "shell";
    syntax = "a && b";
    desc = "run b only if a succeeded (exit status 0)";
    example = "mkdir build && cd build";
  }
  {
    cat = "shell";
    syntax = "a || b";
    desc = "run b only if a failed (non-zero exit)";
    example = "ping -c1 host || echo unreachable";
  }
  {
    cat = "shell";
    syntax = "a && b || c";
    desc = "NOT if/else: c also runs when b fails. Use if/then for real branching";
    example = "if a; then b; else c; fi";
  }
  {
    cat = "shell";
    syntax = "a ; b";
    desc = "run b after a, no matter how a ended";
    example = "cd /tmp ; ls";
  }
  {
    cat = "shell";
    syntax = "a &";
    desc = "run a in the background, return the prompt immediately";
    example = "sleep 60 &";
  }
  {
    cat = "shell";
    syntax = "! a";
    desc = "negate the exit status (a fails -> success)";
    example = "if ! grep -q foo file; then echo missing; fi";
  }
  {
    cat = "shell";
    syntax = "(a; b)";
    desc = "subshell: cd and variables inside don't leak out";
    example = "(cd /tmp && ls)";
  }
  {
    cat = "shell";
    syntax = "{ a; b; }";
    desc = "group in the CURRENT shell — note the spaces and trailing ;";
    example = "{ echo a; echo b; } > both.txt";
  }

  # --- redirection ----------------------------------------------------------
  {
    cat = "redir";
    syntax = "> file";
    desc = "stdout to file, truncating it first";
    example = "ls > list.txt";
  }
  {
    cat = "redir";
    syntax = ">> file";
    desc = "stdout appended to file";
    example = "date >> log.txt";
  }
  {
    cat = "redir";
    syntax = "2> file";
    desc = "stderr only (fd 2) to file";
    example = "make 2> errors.txt";
  }
  {
    cat = "redir";
    syntax = "&> file";
    desc = "stdout and stderr to file (bash)";
    example = "make &> build.log";
  }
  {
    cat = "redir";
    syntax = "2>&1";
    desc = "send stderr wherever stdout currently goes — order matters, put it last";
    example = "cmd > out.txt 2>&1";
  }
  {
    cat = "redir";
    syntax = ">/dev/null 2>&1";
    desc = "throw away all output";
    example = "cmd >/dev/null 2>&1";
  }
  {
    cat = "redir";
    syntax = "< file";
    desc = "read stdin from a file";
    example = "wc -l < file.txt";
  }
  {
    cat = "redir";
    syntax = "<<< 'text'";
    desc = "here-string: feed one string as stdin";
    example = "grep foo <<< \"$line\"";
  }
  {
    cat = "redir";
    syntax = "<<EOF ... EOF";
    desc = "heredoc: multi-line stdin. Quote 'EOF' to stop $ expansion";
    example = "cat <<'EOF' > f.txt";
  }
  {
    cat = "redir";
    syntax = "<(cmd)";
    desc = "process substitution: cmd's output as a file argument";
    example = "diff <(sort a) <(sort b)";
  }
  {
    cat = "redir";
    syntax = "| tee file";
    desc = "write to file AND pass through; -a appends";
    example = "make | tee build.log";
  }

  # --- variables and expansion ---------------------------------------------
  {
    cat = "var";
    syntax = "$(cmd)";
    desc = "command substitution — the output becomes text. Prefer over backticks";
    example = "today=$(date +%F)";
  }
  {
    cat = "var";
    syntax = "$((1 + 2))";
    desc = "arithmetic";
    example = "n=$((n + 1))";
  }
  {
    cat = "var";
    syntax = "\"$var\"";
    desc = "ALWAYS quote: unquoted values word-split and glob-expand";
    example = "rm -- \"$file\"";
  }
  {
    cat = "var";
    syntax = "\${var:-default}";
    desc = "use default if var is unset or empty (var unchanged)";
    example = "port=\${PORT:-8080}";
  }
  {
    cat = "var";
    syntax = "\${var:=default}";
    desc = "same, but also assigns it to var";
    example = "\${TMPDIR:=/tmp}";
  }
  {
    cat = "var";
    syntax = "\${var:?msg}";
    desc = "abort with msg if var is unset — good for required arguments";
    example = "\${1:?usage: script <file>}";
  }
  {
    cat = "var";
    syntax = "\${#var}";
    desc = "length of the value";
    example = "echo \${#PATH}";
  }
  {
    cat = "var";
    syntax = "\${var#pat} / \${var##pat}";
    desc = "strip shortest / longest match from the FRONT";
    example = "name=\${path##*/}   # basename";
  }
  {
    cat = "var";
    syntax = "\${var%pat} / \${var%%pat}";
    desc = "strip shortest / longest match from the END";
    example = "dir=\${path%/*}   # dirname";
  }
  {
    cat = "var";
    syntax = "\${var/old/new}";
    desc = "replace first match; // replaces all";
    example = "echo \${s//,/;}";
  }
  {
    cat = "var";
    syntax = "$? $$ $! $#";
    desc = "last exit status / this PID / last background PID / argument count";
    example = "cmd; echo \"exit=$?\"";
  }
  {
    cat = "var";
    syntax = "\"$@\" vs \"$*\"";
    desc = "$@ = each argument separately (what you want); $* = all joined into one";
    example = "for a in \"$@\"; do echo \"$a\"; done";
  }

  # --- globs, brace expansion ----------------------------------------------
  {
    cat = "glob";
    syntax = "* ? [abc]";
    desc = "any chars / exactly one char / one of a set. * does NOT match a leading dot";
    example = "ls *.log";
  }
  {
    cat = "glob";
    syntax = "**/";
    desc = "recursive glob — needs shopt -s globstar (on by default in zsh)";
    example = "ls **/*.nix";
  }
  {
    cat = "glob";
    syntax = "{a,b}";
    desc = "brace expansion — happens before globbing, no files needed";
    example = "cp f.txt{,.bak}";
  }
  {
    cat = "glob";
    syntax = "{1..10}";
    desc = "ranges, with optional step {0..20..5}";
    example = "for i in {1..5}; do echo $i; done";
  }

  # --- tests / conditionals -------------------------------------------------
  {
    cat = "test";
    syntax = "[[ ... ]]";
    desc = "bash/zsh test: no word splitting, supports && || and =~. Prefer over [ ]";
    example = "if [[ -f $f && $n -gt 3 ]]; then";
  }
  {
    cat = "test";
    syntax = "-e -f -d -L";
    desc = "exists / regular file / directory / symlink";
    example = "[[ -d /tmp ]] && echo yes";
  }
  {
    cat = "test";
    syntax = "-z -n";
    desc = "string is empty / is non-empty";
    example = "[[ -z \"$1\" ]] && usage";
  }
  {
    cat = "test";
    syntax = "-eq -ne -lt -le -gt -ge";
    desc = "NUMERIC comparison; use = and != for strings";
    example = "[[ $n -gt 10 ]]";
  }
  {
    cat = "test";
    syntax = "=~";
    desc = "regex match, right side unquoted; groups land in BASH_REMATCH";
    example = "[[ $s =~ ^[0-9]+$ ]]";
  }
  {
    cat = "test";
    syntax = "case x in p) ;; esac";
    desc = "match against glob patterns; ;; ends a branch, *) is the default";
    example = "case $1 in start) up ;; *) usage ;; esac";
  }

  # --- writing scripts ------------------------------------------------------
  {
    cat = "script";
    syntax = "set -euo pipefail";
    desc = "exit on error, on unset variable, and let a failing pipe stage fail the pipeline";
    example = "set -euo pipefail";
  }
  {
    cat = "script";
    syntax = "trap 'cleanup' EXIT";
    desc = "run something on exit, however it happens";
    example = "trap 'rm -f \"$tmp\"' EXIT";
  }
  {
    cat = "script";
    syntax = "cmd || true";
    desc = "let one command fail without tripping set -e";
    example = "grep -q x f || true";
  }
  {
    cat = "script";
    syntax = "while read -r line";
    desc = "read lines safely; -r stops backslash mangling, IFS= keeps whitespace";
    example = "while IFS= read -r l; do echo \"$l\"; done < f";
  }

  # --- job control / history -----------------------------------------------
  {
    cat = "job";
    syntax = "Ctrl+Z / bg / fg";
    desc = "suspend the foreground job, then resume it in background / foreground";
    example = "fg %1";
  }
  {
    cat = "job";
    syntax = "jobs -l";
    desc = "list this shell's jobs with PIDs";
    example = "jobs -l";
  }
  {
    cat = "job";
    syntax = "disown -h %1";
    desc = "detach a job so it survives closing the shell";
    example = "disown -h %1";
  }
  {
    cat = "job";
    syntax = "Ctrl+C / Ctrl+D";
    desc = "interrupt the running command / end of input (closes the shell if idle)";
    example = "";
  }
  {
    cat = "hist";
    syntax = "!! and !$";
    desc = "the whole previous command / its last argument";
    example = "sudo !!";
  }
  {
    cat = "hist";
    syntax = "Ctrl+R";
    desc = "fuzzy history search (fzf is wired in)";
    example = "";
  }
  {
    cat = "hist";
    syntax = "Ctrl+T / Alt+C";
    desc = "fzf: insert a file path / cd into a directory";
    example = "";
  }
  {
    cat = "hist";
    syntax = "Ctrl+F";
    desc = "tmux-sessionizer: pick a project, jump to its tmux session";
    example = "";
  }

  # --- finding things -------------------------------------------------------
  {
    cat = "find";
    syntax = "rg pattern";
    desc = "ripgrep: recursive, respects .gitignore. -i case-insensitive, -n line numbers";
    example = "rg -i 'todo' -g '*.nix'";
  }
  {
    cat = "find";
    syntax = "fd name";
    desc = "friendlier find. -e for extension, -H to include hidden";
    example = "fd -e nix polybar";
  }
  {
    cat = "find";
    syntax = "find . -name '*.x'";
    desc = "quote the pattern or the shell expands it first";
    example = "find . -name '*.log' -mtime +7";
  }
  {
    cat = "find";
    syntax = "find ... -exec cmd {} +";
    desc = "run cmd on the results; + batches them, \\; runs one at a time";
    example = "find . -name '*.tmp' -exec rm {} +";
  }
  {
    cat = "find";
    syntax = "-print0 | xargs -0";
    desc = "the safe pairing when filenames may contain spaces";
    example = "find . -print0 | xargs -0 grep -l foo";
  }
  {
    cat = "find";
    syntax = "grep -rn pat dir";
    desc = "recursive with line numbers; -l names only, -v invert, -c count";
    example = "grep -rn 'def main' .";
  }

  # --- files and permissions -----------------------------------------------
  {
    cat = "file";
    syntax = "chmod +x f";
    desc = "make executable; 644 = rw-r--r--, 755 = rwxr-xr-x, 600 = private";
    example = "chmod 600 ~/.ssh/id_ed25519";
  }
  {
    cat = "file";
    syntax = "du -sh *";
    desc = "size of each entry here; sort -h to rank them";
    example = "du -sh * | sort -h | tail";
  }
  {
    cat = "file";
    syntax = "df -h";
    desc = "free space per filesystem";
    example = "df -h /";
  }
  {
    cat = "file";
    syntax = "tar -czf out.tgz dir";
    desc = "create gzipped tar; -xzf extracts, -tzf lists";
    example = "tar -xzf archive.tgz";
  }
  {
    cat = "file";
    syntax = "ln -s target link";
    desc = "symlink — target first, then the name of the link";
    example = "ln -s /run/media/x ~/x";
  }
  {
    cat = "file";
    syntax = "rsync -avh --progress src/ dst/";
    desc = "copy/sync; a trailing slash on src copies its CONTENTS";
    example = "rsync -avh ~/docs/ /mnt/backup/docs/";
  }

  # --- processes, services, network ----------------------------------------
  {
    cat = "proc";
    syntax = "systemctl status|start|stop|restart";
    desc = "system units; add --user for your session's units";
    example = "systemctl --user restart polybar";
  }
  {
    cat = "proc";
    syntax = "journalctl -u unit -f";
    desc = "follow a unit's log; -b this boot, -e jump to the end, -p err";
    example = "journalctl -u blocky -b -p err";
  }
  {
    cat = "proc";
    syntax = "ss -tlnp";
    desc = "listening TCP sockets with the owning process";
    example = "ss -tlnp | grep 4000";
  }
  {
    cat = "proc";
    syntax = "pkill -f pattern";
    desc = "kill by full command line; pgrep -af first to check what matches";
    example = "pgrep -af polybar";
  }
  {
    cat = "proc";
    syntax = "kill -9 pid";
    desc = "SIGKILL, unignorable and no cleanup — try plain kill (TERM) first";
    example = "kill 1234";
  }

  # --- nix / this config ----------------------------------------------------
  {
    cat = "nix";
    syntax = "nh os switch . -H host";
    desc = "rebuild and switch this flake for a host (desktop, laptop, work_pc, work_laptop)";
    example = "nh os switch ~/00_projects/nixos-config -H desktop";
  }
  {
    cat = "nix";
    syntax = "nixos-rebuild build --flake .#host";
    desc = "build without activating — the safe way to check a change";
    example = "sudo nixos-rebuild build --flake .#laptop";
  }
  {
    cat = "nix";
    syntax = "nix flake check";
    desc = "evaluate every host + check formatting, no rebuild";
    example = "nix flake check --no-build";
  }
  {
    cat = "nix";
    syntax = "nix fmt";
    desc = "alejandra over the whole tree";
    example = "nix fmt";
  }
  {
    cat = "nix";
    syntax = "nix flake update";
    desc = "bump every input; --update-input name for just one";
    example = "nix flake update nixpkgs";
  }
  {
    cat = "nix";
    syntax = "nix shell nixpkgs#pkg";
    desc = "drop a package into a throwaway shell; nix run to execute it once";
    example = "nix run nixpkgs#htop";
  }
  {
    cat = "nix";
    syntax = "nix search nixpkgs term";
    desc = "find a package name";
    example = "nix search nixpkgs wireguard";
  }
  {
    cat = "nix";
    syntax = "nix repl";
    desc = ":lf . loads this flake, then tab-complete through the config";
    example = "nix repl";
  }
  {
    cat = "nix";
    syntax = "nixos-rebuild --rollback switch";
    desc = "go back a generation; the boot menu also lists them";
    example = "sudo nixos-rebuild --rollback switch";
  }

  # --- this machine's own commands -----------------------------------------
  {
    cat = "mine";
    syntax = "pw / pw <entry>";
    desc = "password store: picker, or copy one entry's password (clears after 45s)";
    example = "pw github";
  }
  {
    cat = "mine";
    syntax = "vpn up|down|toggle|status";
    desc = "NordLynx tunnel; the polybar shield does the same";
    example = "vpn status";
  }
  {
    cat = "mine";
    syntax = "dnd toggle";
    desc = "do not disturb: silence notifications + block social. Also mod+shift+n";
    example = "dnd on";
  }
  {
    cat = "mine";
    syntax = "marketplace-toggle";
    desc = "stop/resume the marketplace poller; right-click its polybar icon does this";
    example = "marketplace-toggle off";
  }
  {
    cat = "mine";
    syntax = "sops secrets/common.yaml";
    desc = "edit encrypted secrets in place";
    example = "sops secrets/passwords.yaml";
  }

  # --- tmux -----------------------------------------------------------------
  {
    cat = "tmux";
    syntax = "prefix then %  /  \"";
    desc = "split vertically / horizontally";
    example = "";
  }
  {
    cat = "tmux";
    syntax = "prefix then c / n / p / <n>";
    desc = "new window / next / previous / jump to number";
    example = "";
  }
  {
    cat = "tmux";
    syntax = "prefix then d";
    desc = "detach; tmux a reattaches, tmux ls lists sessions";
    example = "tmux a -t name";
  }
  {
    cat = "tmux";
    syntax = "prefix then z";
    desc = "zoom the current pane fullscreen, again to restore";
    example = "";
  }

  # --- herdr (agent multiplexer; defaults from `herdr --default-config`) -----
  {
    cat = "herdr";
    syntax = "herdr";
    desc = "launch or attach the persistent session; prefix is ctrl+b, same as tmux";
    example = "herdr";
  }
  {
    cat = "herdr";
    syntax = "herdr --session <name>";
    desc = "named persistent session; session list / attach / stop / delete";
    example = "herdr --session work";
  }
  {
    cat = "herdr";
    syntax = "prefix ? / s / q";
    desc = "help overlay / settings / detach (server keeps running)";
    example = "";
  }
  {
    cat = "herdr";
    syntax = "prefix c / n / p / 1..9";
    desc = "new tab / next / previous / jump to tab number";
    example = "";
  }
  {
    cat = "herdr";
    syntax = "prefix v / prefix -";
    desc = "split pane vertically / horizontally";
    example = "";
  }
  {
    cat = "herdr";
    syntax = "prefix h j k l";
    desc = "focus the pane left / down / up / right";
    example = "";
  }
  {
    cat = "herdr";
    syntax = "prefix tab";
    desc = "cycle to the next pane; shift+tab for the previous one";
    example = "";
  }
  {
    cat = "herdr";
    syntax = "prefix z / x / r";
    desc = "zoom pane fullscreen / close pane / enter resize mode";
    example = "";
  }
  {
    cat = "herdr";
    syntax = "prefix w / g";
    desc = "workspace picker / goto (navigate mode: hjkl and arrows)";
    example = "";
  }
  {
    cat = "herdr";
    syntax = "prefix shift+n / shift+g";
    desc = "new workspace / new git worktree-backed workspace";
    example = "";
  }
  {
    cat = "herdr";
    syntax = "prefix shift+w / shift+d";
    desc = "rename / close the current workspace";
    example = "";
  }
  {
    cat = "herdr";
    syntax = "prefix shift+t / shift+x";
    desc = "rename / close the current tab";
    example = "";
  }
  {
    cat = "herdr";
    syntax = "prefix b / e";
    desc = "toggle the sidebar / open this pane's scrollback in $EDITOR";
    example = "";
  }
  {
    cat = "herdr";
    syntax = "prefix shift+r";
    desc = "reload config.toml in the running server, no restart";
    example = "herdr server reload-config";
  }
  {
    cat = "herdr";
    syntax = "herdr agent list";
    desc = "every agent pane and its lifecycle state";
    example = "herdr agent list";
  }
  {
    cat = "herdr";
    syntax = "herdr agent prompt";
    desc = "send a prompt into an agent pane from outside herdr";
    example = "herdr agent prompt --id 1 'run the tests'";
  }
  {
    cat = "herdr";
    syntax = "herdr agent wait";
    desc = "block until an agent reaches a state — the scripting primitive";
    example = "herdr agent wait --id 1 --state idle";
  }
  {
    cat = "herdr";
    syntax = "herdr pane run / read";
    desc = "run a command in a pane / read a pane's terminal output";
    example = "herdr pane read --id 2";
  }
  {
    cat = "herdr";
    syntax = "herdr pane wait-output";
    desc = "block until a pane prints something matching";
    example = "herdr pane wait-output --id 2 --pattern 'done'";
  }
  {
    cat = "herdr";
    syntax = "herdr worktree create";
    desc = "create a git worktree and open it as its own workspace";
    example = "herdr worktree create --branch feat/x";
  }
  {
    cat = "herdr";
    syntax = "herdr --remote <ssh>";
    desc = "attach to a herdr server on another box over SSH";
    example = "herdr --remote lab";
  }
  {
    cat = "herdr";
    syntax = "herdr --skill";
    desc = "print the agent instructions for driving herdr from a pane";
    example = "herdr --skill";
  }
  {
    cat = "herdr";
    syntax = "herdr --default-config";
    desc = "print the whole annotated default config.toml";
    example = "herdr --default-config > ~/.config/herdr/config.toml";
  }

  # --- i3 (this config's bindings; mod = Alt) -------------------------------
  {
    cat = "i3";
    syntax = "mod+Enter / mod+Shift+q";
    desc = "terminal / close window";
    example = "";
  }
  {
    cat = "i3";
    syntax = "mod+d / mod+o / mod+c";
    desc = "launcher / bookmarks / calculator (rofi tabs: Tab cycles them)";
    example = "";
  }
  {
    cat = "i3";
    syntax = "mod+b / mod+v / mod+f";
    desc = "split next window horizontally / vertically / fullscreen toggle";
    example = "";
  }
  {
    cat = "i3";
    syntax = "mod+Shift+e / mod+Shift+n";
    desc = "lock the screen / do not disturb";
    example = "";
  }
  {
    cat = "i3";
    syntax = "mod+Win+hjkl";
    desc = "focus another monitor; add Shift to move the workspace there";
    example = "";
  }
  {
    cat = "i3";
    syntax = "mod+r";
    desc = "resize mode — arrows resize, Escape leaves";
    example = "";
  }
  {
    cat = "i3";
    syntax = "Win+Space";
    desc = "switch keyboard layout us <-> lt";
    example = "";
  }

  # --- the X11 clipboard, which is genuinely confusing ---------------------
  {
    cat = "clip";
    syntax = "PRIMARY vs CLIPBOARD";
    desc = "X11 has two: selecting text fills PRIMARY, Ctrl+C fills CLIPBOARD. Different buffers";
    example = "";
  }
  {
    cat = "clip";
    syntax = "middle-click";
    desc = "pastes PRIMARY (whatever you last selected), NOT what you Ctrl+C'd";
    example = "";
  }
  {
    cat = "clip";
    syntax = "Ctrl+C in Firefox";
    desc = "copy. Ctrl+SHIFT+C is the devtools inspector — only the terminal wants the Shift";
    example = "";
  }
  {
    cat = "clip";
    syntax = "select in alacritty";
    desc = "already copies to the clipboard (save_to_clipboard), no keystroke needed";
    example = "";
  }
  {
    cat = "clip";
    syntax = "Ctrl+Shift+C / Ctrl+Shift+V";
    desc = "terminal copy/paste; Ctrl+Insert and Shift+Insert also work here";
    example = "";
  }
  {
    cat = "clip";
    syntax = "mod+p  /  clip";
    desc = "clipboard history: everything copied since boot, pick one to re-copy it";
    example = "clip";
  }
  {
    cat = "clip";
    syntax = "rofi 'clip' tab";
    desc = "same history inside the launcher; picking restores it to BOTH selections";
    example = "";
  }
  {
    cat = "clip";
    syntax = "cmd | xclip -sel clip";
    desc = "put output on the clipboard; -o reads it back, -sel primary for the other one";
    example = "pwd | xclip -sel clip";
  }
  {
    cat = "clip";
    syntax = "xclip -sel clip -o";
    desc = "print the clipboard to stdout";
    example = "xclip -sel clip -o > f.txt";
  }
  {
    cat = "clip";
    syntax = "clipctl disable / enable";
    desc = "pause clipboard history — `pw` does this itself so passwords never land in it";
    example = "clipctl status";
  }
  {
    cat = "clip";
    syntax = "\"+y in nvim";
    desc = "yank to the system clipboard; plain y only touches vim's own registers";
    example = "";
  }

  # --- vim, the parts everyone re-looks-up ---------------------------------
  {
    cat = "vim";
    syntax = "ciw / caw";
    desc = "change inner word / a word (with its trailing space). Same shape: di( ya\" ct,";
    example = "ci\"";
  }
  {
    cat = "vim";
    syntax = "verb + motion";
    desc = "d y c v + w b e $ 0 ^ G gg }  — combine, don't memorise pairs";
    example = "d}";
  }
  {
    cat = "vim";
    syntax = "f x / t x / ; / ,";
    desc = "jump to next x / just before it; ; repeats, , repeats backwards";
    example = "dt,";
  }
  {
    cat = "vim";
    syntax = "% ";
    desc = "jump to the matching bracket";
    example = "d%";
  }
  {
    cat = "vim";
    syntax = "gg=G";
    desc = "re-indent the whole file";
    example = "gg=G";
  }
  {
    cat = "vim";
    syntax = ":%s/old/new/gc";
    desc = "replace in the file; g all per line, c confirm each, I case-sensitive";
    example = ":%s/foo/bar/gc";
  }
  {
    cat = "vim";
    syntax = "qa ... q  then @a";
    desc = "record a macro into register a, replay it; @@ repeats the last one";
    example = "10@a";
  }
  {
    cat = "vim";
    syntax = "Ctrl+v";
    desc = "visual block; I or A then Esc edits every selected line";
    example = "";
  }
  {
    cat = "vim";
    syntax = "\"+y  /  \"+p";
    desc = "yank to / paste from the system clipboard (in this config: <leader>y)";
    example = "\"+yy";
  }
  {
    cat = "vim";
    syntax = "m a  then  'a";
    desc = "set mark a, jump back to it. `` returns to where you just were";
    example = "";
  }
  {
    cat = "vim";
    syntax = "Ctrl+o / Ctrl+i";
    desc = "jump list: back / forward through where you've been";
    example = "";
  }
  {
    cat = "vim";
    syntax = ":e! / :w !sudo tee %";
    desc = "reload discarding changes / save a file you opened without permission";
    example = "";
  }
  {
    cat = "vim";
    syntax = ":sp / :vs / Ctrl+w hjkl";
    desc = "split horizontally / vertically / move between splits";
    example = ":vs file.txt";
  }
  {
    cat = "vim";
    syntax = ":bn / :bp / :bd";
    desc = "next / previous / close buffer; :ls lists them";
    example = ":ls";
  }
  {
    cat = "vim";
    syntax = "u / Ctrl+r / .";
    desc = "undo / redo / repeat the last change";
    example = "";
  }

  # --- this neovim config (leader = Space) ---------------------------------
  {
    cat = "nvim";
    syntax = "<leader>pf / Ctrl+p";
    desc = "telescope: find files / git files";
    example = "";
  }
  {
    cat = "nvim";
    syntax = "<leader>ps";
    desc = "telescope: grep the project for a prompt";
    example = "";
  }
  {
    cat = "nvim";
    syntax = "<leader>pv";
    desc = "file explorer (netrw)";
    example = "";
  }
  {
    cat = "nvim";
    syntax = "<leader>a / Ctrl+e";
    desc = "harpoon: pin this file / open the pinned menu";
    example = "";
  }
  {
    cat = "nvim";
    syntax = "Ctrl+h t n s";
    desc = "harpoon: jump to pinned file 1 / 2 / 3 / 4";
    example = "";
  }
  {
    cat = "nvim";
    syntax = "gd / K / gr";
    desc = "LSP: go to definition / hover docs / references";
    example = "";
  }
  {
    cat = "nvim";
    syntax = "<leader>rn / <leader>ca";
    desc = "LSP: rename symbol / code action";
    example = "";
  }
  {
    cat = "nvim";
    syntax = "<leader>f";
    desc = "format the buffer (also happens on save, via conform)";
    example = "";
  }
  {
    cat = "nvim";
    syntax = "<leader>s";
    desc = "replace the word under the cursor throughout the file";
    example = "";
  }
  {
    cat = "nvim";
    syntax = "<leader>y / <leader>Y";
    desc = "yank to the system clipboard; <leader>d deletes without clobbering the register";
    example = "";
  }
  {
    cat = "nvim";
    syntax = "<leader>p (visual)";
    desc = "paste over a selection without losing what you had yanked";
    example = "";
  }
  {
    cat = "nvim";
    syntax = "J / K (visual)";
    desc = "move the selected lines down / up, re-indenting";
    example = "";
  }
  {
    cat = "nvim";
    syntax = "Ctrl+k / Ctrl+j";
    desc = "quickfix next / previous (centred); <leader>k and <leader>j do the location list";
    example = "";
  }
  {
    cat = "nvim";
    syntax = "Ctrl+f";
    desc = "tmux-sessionizer in a new tmux window, without leaving nvim";
    example = "";
  }
  {
    cat = "nvim";
    syntax = "<leader>x";
    desc = "chmod +x the current file";
    example = "";
  }
  {
    cat = "nvim";
    syntax = "nvim vs nnvim";
    desc = "nvim = this config (nixvim); nnvim = nixy's build, kept for comparison";
    example = "";
  }

  # --- zsh ------------------------------------------------------------------
  {
    cat = "zsh";
    syntax = "Right arrow";
    desc = "accept the greyed-out autosuggestion from history";
    example = "";
  }
  {
    cat = "zsh";
    syntax = "Tab";
    desc = "fzf-tab: fuzzy completion menu; type to filter, Enter to pick";
    example = "";
  }
  {
    cat = "zsh";
    syntax = "cd -  /  cd ~2";
    desc = "previous directory / from the dirs -v stack";
    example = "dirs -v";
  }
  {
    cat = "zsh";
    syntax = "**/*.nix";
    desc = "recursive glob, no globstar option needed in zsh";
    example = "ls **/*.nix";
  }
  {
    cat = "zsh";
    syntax = "*(.) *(/) *(om[1,5])";
    desc = "glob qualifiers: plain files / directories / the 5 most recently modified";
    example = "ls -d *(/)";
  }
  {
    cat = "zsh";
    syntax = "^x  and  *~*.txt";
    desc = "negation: everything except x / every file except .txt (needs extendedglob)";
    example = "";
  }
  {
    cat = "zsh";
    syntax = "ll / lab / act";
    desc = "this config's aliases: ls -al / ssh the cryolab box / activate ./env";
    example = "lab";
  }
  {
    cat = "zsh";
    syntax = "tldr cmd";
    desc = "practical examples instead of a full man page";
    example = "tldr tar";
  }
]
