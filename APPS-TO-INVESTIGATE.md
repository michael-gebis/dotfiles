# Apps to Investigate

CLI/dev tools not currently installed that fit my workflow (RE + heavy
docs/diagrams + multi-language dev + git/yadm). Generated 2026-06-25 from a
PATH scan against what I already have.

**Already covered (excluded from this list):** `gdb`, `jq`, `strace`, `mtr`,
`tcpdump`, `objdump`/`readelf`, plus my modern set (`rg`, `fdfind`, `atuin`,
`btop`, `uv`, `ncdu`, `glow`, `d2`, `mmdc`).

Install-channel tags are approximate — confirm when wiring into `setup.yml`.
Tags: `(apt)` `(charm repo — already configured!)` `(cargo)` `(go)` `(pip)` `(.deb)`

---

## Top picks (highest value first)
- [x] **fzf** `(release binary → ~/.local/bin)` — fuzzy finder; connective tissue for rg/fd/git/atuin. Ctrl-T, `**<tab>`, vim integration. ✅ installed + wired into setup.yml & .bashrc (atuin keeps Ctrl-R; fzf gets Ctrl-T/Alt-C/completion + an `rgf` live-grep helper).
- [ ] **delta** `(cargo / .deb)` — syntax-highlighted side-by-side git diffs; upgrades every `git diff`/`git show`/`yadm diff`.
- [ ] **zoxide** `(apt)` — `cd` that learns frequent dirs (`z proj`); natural atuin sibling.
- [ ] **gh** `(apt repo)` — GitHub CLI: PRs/issues/releases/auth from the terminal.
- [ ] **direnv** `(apt)` — per-directory env auto-load; auto-activates Go/Java(SDKMAN)/Python(uv)/Node(nvm) on `cd`.
- [ ] **bat** `(apt: batcat)` — `cat` with syntax highlighting + git gutters; also powers fzf previews.

## Reverse engineering & binaries
- [ ] **rizin** `(apt)` — maintained radare2 fork; CLI disasm/patch to complement Ghidra (**cutter** = its GUI).
- [ ] **hexyl** `(apt)` — colored hex viewer (bat author); firmware/binary poking.
- [ ] **ltrace** `(apt)` — library-call tracer (the other half of strace).
- [ ] **gef** *or* **pwndbg** `(git)` — gdb plugins that transform gdb for RE/exploitation.
- [ ] **upx** `(apt: upx-ucl)` — pack/unpack executables.
- [ ] **patchelf** `(apt)` — rewrite ELF interpreter & rpath.
- [ ] **pwntools** `(pip)` + **ropper** `(pip)` — exploit-dev framework / ROP gadget finder (if doing CTF).

## Docs & diagrams (Charm repo already in my apt sources!)
- [ ] **vhs** `(charm repo)` — script terminal sessions → GIF/MP4 for READMEs.
- [ ] **gum** `(charm repo)` — pretty prompts/spinners/choosers for shell scripts.
- [ ] **freeze** `(charm repo)` — code → PNG/SVG screenshots.
- [ ] **mods** `(charm repo)` — pipe shell output through an LLM.
- [ ] **asciinema** `(apt)` — record/share real-time terminal sessions.
- [ ] **plantuml** `(apt)` — UML/sequence diagrams (the genre mermaid/d2/wavedrom/bytefield don't cover).

## Git
- [x] **lazygit** `(release binary → ~/.local/bin)` — fast git TUI; a modern gitk. ✅ installed + wired into setup.yml (asset is lowercase `linux_x86_64`; for the yadm repo try `yadm enter lazygit`).
- [ ] **tig** `(apt)` — lighter text-mode git browser.

## Networking
- [ ] **nmap** `(apt)` — port/network scanner.
- [ ] **xh** `(cargo)` — friendly rust HTTP client vs curl.
- [ ] **doggo** `(go)` — modern `dig`.
- [ ] **bandwhich** `(cargo)` — per-*process* bandwidth (vs per-interface bmon).

## Docker
- [x] **lazydocker** `(release binary → ~/.local/bin)` — container/image/log TUI. ✅ installed + wired into setup.yml (go install is broken; uses the GitHub release tarball).
- [ ] **dive** `(.deb)` — inspect image layers / find bloat.

## Dev workflow
- [ ] **just** `(cargo / .deb)` — modern `make` task runner.
- [ ] **hyperfine** `(apt)` — CLI benchmarking (bat/fd author).
- [ ] **watchexec** `(cargo)` / **entr** `(apt)` — run command on file change.
- [ ] **shfmt** `(apt)` — shell formatter (pairs with shellcheck).
- [ ] **pre-commit** `(apt / pip)` — multi-language git hook framework.
- [ ] **tokei** `(cargo)` — faster `cloc`.

## Everyday ergonomics
- [ ] **eza** `(apt / cargo)` — modern `ls` (git status, tree, icons).
- [ ] **sd** `(cargo)` — intuitive `sed` find/replace.
- [ ] **dust** `(cargo)` — visual `du`.
- [ ] **duf** `(apt)` — friendly `df`.
- [ ] **procs** `(apt / cargo)` — modern `ps`.
- [ ] **tealdeer** `(cargo)` / **tldr** `(apt)` — community command cheat-sheets.
- [ ] **ouch** `(cargo)` — one tool for all lz4/zstd/7z/unar formats.
- [ ] **yq** `(snap / .deb — the Go mikefarah build, not the apt python `yq`)` — YAML/JSON processor; complement to jq for ansible work.

## System
- [ ] **smartmontools** `(apt: smartctl)` — SMART disk health (covers SATA/USB where nvme-cli doesn't).
- [ ] **lm-sensors** `(apt: sensors)` — CPU/board temperatures.
- [ ] **glances** `(apt)` — all-in-one monitor with web/API export.

---

# Appendix — setup notes

## fzf — installed & wired in (2026-06-25)
fzf 0.73.1 in `~/.local/bin`; reproducible via `setup.yml` (fetches the latest
release binary, version-guarded like the Obsidian/lazydocker tasks) and configured
in `.bashrc`.

**`.bashrc` config:** loaded *before* atuin so **atuin keeps Ctrl-R**;
`FZF_DEFAULT_COMMAND` uses `fdfind` (fast, `.gitignore`-aware), Ctrl-T preview via
`batcat`→`cat` fallback (prettier once `bat` is installed), plus an `rgf`
live-ripgrep helper.

**Activate** after a fresh pull / first run — reload the shell:
```bash
exec bash      # or: source ~/.bashrc, or open a new terminal
```

**Cheat-sheet:**

| Key / command | Does |
|---|---|
| `Ctrl-T` | fuzzy-pick file(s)/dirs onto the command line (e.g. `vim` then Ctrl-T) |
| `Alt-C` | fuzzy `cd` into a subdirectory |
| `<cmd> **` + Tab | fuzzy completion — e.g. `ssh **`, `kill -9 **`, `git switch **`, then Tab |
| `rgf [query]` | live ripgrep across the tree → Enter opens the match in `$EDITOR` at the line |
| `Ctrl-R` | history search — still **atuin** (intentional, not fzf) |

**More to explore later:** the `fzf.vim` plugin (`:Files` / `:Rg` / `:GFiles` /
`:Buffers`), the `fzf --tmux center` popup, and `zi` once `zoxide` is installed.
