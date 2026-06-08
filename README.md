# dotfiles

My personal dotfiles. Managed by [yadm](https://yadm.io/), used on both native Ubuntu and WSL2 machines.

## Quick start (new machine)

```bash
# Install yadm
sudo apt install yadm

# Clone and bootstrap
yadm clone <your-repo-url>
yadm bootstrap
```

The bootstrap script installs [Ansible](https://docs.ansible.com/) if needed, then runs `~/.config/ansible/setup.yml` to set up the machine. It will prompt for your sudo password.

## What's included

### Shell (`.bashrc`)

The `.bashrc` is organized around a `_setup_main` function that runs all setup, then unsets its `_setup_*` helper functions afterward. Key features:

- **Logging** — sources `~/.bashlog` if present; all sections call `bashlog` for tracing (useful when debugging shell startup). If `.bashlog` is missing, `bashlog` becomes a no-op.
- **`_setup_pathprepend`** — helper to add directories to `$PATH` without duplicates.
- **OS detection** — detects WSL2 vs native Linux and runs platform-specific setup (`_setup_windows` / `_setup_linux`).
- **Powerline prompt** — sets up [powerline-go](https://github.com/justjanne/powerline-go) if installed (shows error status and background job count).
- **Tool initialization** — nvm and SDKMAN are initialized inside `_setup_main` with existence checks so missing tools don't cause errors. [atuin](https://atuin.sh) (shell history) is initialized **at top level, outside `_setup_main`** — deliberately: it sources the vendored [bash-preexec](https://github.com/rcaloras/bash-preexec) (`~/.bash-preexec.sh`), whose `declare -a` hook arrays must be global. Inside a function they'd be local and vanish on return, silently breaking command recording (Ctrl-R still reads old history, but new commands aren't saved). atuin's config (`~/.config/atuin/config.toml`) is tracked but holds **no** server address; set `ATUIN_SYNC_ADDRESS` in `~/.bashrc.local` on machines that can reach a sync server — others run local-only.
- **SSH wrapper** — a generic `ssh()` function that color-codes the terminal background based on the destination host. Reads host-to-color mappings from `~/.config/ssh-terminal-colors` (not tracked). Format: one line per entry, `glob_pattern hex_color`. Example:

  ```
  *prod*   #3b0a0a
  *dev*    #0a3b1a
  ```

- **Local overrides** — sources `~/.bashrc.local` (not tracked) at the end of `_setup_main` for machine-specific configuration (e.g., toolchain paths, org-specific environment variables).

### Ansible setup (`~/.config/ansible/`)

The playbook `setup.yml` is the generic, portable configuration tracked by yadm. It handles:

- **Third-party repos & keys** — Docker, Tailscale, Typora, Ghostty (PPA), VS Code, Google Chrome
- **APT packages** — dev tools, editors, search tools, Docker, desktop apps, networking, compression utilities
- **Snap packages** — pdftk
- **User-level tools** — powerline-go (via `go install`), atuin, nvm, SDKMAN

For machine-specific or org-specific packages, create `~/.config/ansible/local.yml` (not tracked by yadm). This file is automatically included by the playbook if present. It runs as a list of Ansible tasks with `become: true` already in effect and access to the `ubuntu_release` variable. Example:

```yaml
---
- name: Add a custom repo GPG key
  ansible.builtin.shell: |
    curl -fsSL https://example.com/key.pub \
      | gpg --dearmor -o /etc/apt/keyrings/example.gpg
  args:
    creates: /etc/apt/keyrings/example.gpg

- name: Add custom repository
  ansible.builtin.apt_repository:
    repo: "deb [signed-by=/etc/apt/keyrings/example.gpg] https://example.com/apt {{ ubuntu_release }} main"
    filename: example

- name: Install org-specific packages
  ansible.builtin.apt:
    name:
      - some-package
    state: present
```

### Files not tracked by yadm

These files are machine-specific and should be created manually or copied separately:

| File | Purpose |
|---|---|
| `~/.bashrc.local` | Machine-specific shell config (toolchain paths, env vars; e.g. `ATUIN_SYNC_ADDRESS` to point atuin's history sync at a server this machine can reach) |
| `~/.config/ansible/local.yml` | Org-specific Ansible tasks (repos, packages) |
| `~/.config/ssh-terminal-colors` | SSH host-to-color mappings for the terminal wrapper |

## Re-running the playbook

The playbook is idempotent — safe to re-run at any time to pick up changes:

```bash
ansible-playbook ~/.config/ansible/setup.yml --ask-become-pass
```

Or re-run the full bootstrap:

```bash
yadm bootstrap
```

## Troubleshooting apt repositories

The third-party repo tasks use `ansible.builtin.deb822_repository`, which writes one
declarative `*.sources` file per repo and **updates it in place** — so changing a key or
URL can't leave a stale, conflicting line behind. (The playbook used to use
`apt_repository`, which *appended* on change; the migration deletes the old `*.list` files
it left, and installs `python3-debian`, which the module requires.)

Conflicts can still arise — from a leftover `*.list` on a machine provisioned by the old
playbook, a vendor-managed `*.sources`, or a manually added repo. If two entries for the
same repo disagree on the signing key, apt refuses to read its sources at all:

```
E: Conflicting values set for option Signed-By regarding source
   https://packages.microsoft.com/repos/code/ stable:
   /usr/share/keyrings/microsoft.asc != /usr/share/keyrings/microsoft.gpg
E: The list of sources could not be read.
```

Fix it by deleting the **stale** entry, then re-checking:

```bash
# show every configured repo and which key each entry uses
grep -rn 'signed-by\|Signed-By' /etc/apt/sources.list /etc/apt/sources.list.d/

# e.g. remove a leftover one-line .list that a .sources now supersedes
sudo rm /etc/apt/sources.list.d/vscode.list

# definitive check — re-reads the whole sources tree
sudo apt-get update
```

A non-fatal `W: Target … is configured multiple times` is the harmless cousin: the same
repo is defined twice with the *same* key (or one entry has no key), so apt just
deduplicates. Safe to ignore, or clean up the same way.

Three kinds of repo definitions can coexist on one machine:

- **Playbook-managed** `*.sources`, written by `deb822_repository` (Docker, Tailscale,
  Typora, Ghostty, VS Code, Chrome, Charm). The source of truth.
- **Vendor-self-configured** `*.sources` — the `code` and `google-chrome` packages manage
  their own files and recreate them on upgrade. The playbook names its VS Code and Chrome
  repos to match (`vscode`, `google-chrome`), so it rewrites that *same* file instead of
  creating a competing duplicate.
- **Manually added**, e.g. `adoptium.list` (Eclipse Temurin) — *not* in the playbook;
  maintained by hand.
