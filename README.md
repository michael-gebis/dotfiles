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

The `.bashrc` is organized around a `bash_main` function that runs all setup, then cleans up helper functions afterward. Key features:

- **Logging** — sources `~/.bashlog` if present; all sections call `bashlog` for tracing (useful when debugging shell startup). If `.bashlog` is missing, `bashlog` becomes a no-op.
- **`pathprepend`** — helper to add directories to `$PATH` without duplicates.
- **OS detection** — detects WSL2 vs native Linux and runs platform-specific setup (`do_windows` / `do_linux`).
- **Powerline prompt** — sets up [powerline-go](https://github.com/justjanne/powerline-go) if installed (shows error status and background job count).
- **Tool initialization** — nvm, atuin, SDKMAN are initialized inside `bash_main` with existence checks so missing tools don't cause errors.
- **SSH wrapper** — a generic `ssh()` function that color-codes the terminal background based on the destination host. Reads host-to-color mappings from `~/.config/ssh-terminal-colors` (not tracked). Format: one line per entry, `glob_pattern hex_color`. Example:

  ```
  *prod*   #3b0a0a
  *dev*    #0a3b1a
  ```

- **Local overrides** — sources `~/.bashrc.local` (not tracked) at the end of `bash_main` for machine-specific configuration (e.g., toolchain paths, org-specific environment variables).

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
| `~/.bashrc.local` | Machine-specific shell config (toolchain paths, env vars) |
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
