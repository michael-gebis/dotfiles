### Michael Gebis's .bashrc; https://github.com/michael-gebis/dotfiles
### See LICENSE file for details (MIT License)

# Source the logging helper if present (it defines bashlog). Guarantee bashlog
# exists regardless: if ~/.bashlog is missing -- or present but doesn't define
# it -- fall back to a no-op so the bashlog calls below never error.
[ -f ~/.bashlog ] && . ~/.bashlog
declare -F bashlog >/dev/null || bashlog() { :; }

bashlog "start .bashrc"

### https://superuser.com/questions/39751/add-directory-to-path-if-its-not-already-there
_setup_pathprepend() {
  local i ARG
  for ((i=$#; i>0; i--)); do
    ARG=${!i}
    if [ -d "$ARG" ] && [[ ":$PATH:" != *":$ARG:"* ]]; then
        PATH="$ARG${PATH:+":$PATH"}"
    fi
  done
}

### --- Environment for ALL shells (must precede the interactive guard) ------
### PATH and core env vars are set here so non-interactive shells -- e.g.
### `bash -lc '...'` -- and their children still get them. Everything below
### the guard is interactive-only (prompt, aliases, completion, ssh-agent, ...).
export VISUAL=vi
export EDITOR="$VISUAL"
_setup_pathprepend "$HOME/.cargo/bin"   # rust
_setup_pathprepend "$HOME/.local/bin"   # user-local bin

### Stop here for non-interactive shells. `return` is valid because .bashrc is
### always *sourced* (by .bash_profile for login shells, or directly otherwise).
case $- in
  *i*) ;;        # interactive: keep going
  *)   return ;; # non-interactive: nothing below is useful
esac

### As per https://github.com/justjanne/powerline-go
### Also https://www.hanselman.com/blog/how-to-make-a-pretty-prompt-in-windows-terminal-with-powerline-nerd-fonts-cascadia-code-wsl-and-ohmyposh
_setup_powerline() {
  bashlog "start _setup_powerline"
  # Full path to the powerline-go binary (installed by `go install` into
  # GOPATH/bin, which defaults to ~/go/bin). Kept in its own variable -- not
  # GOPATH -- so _update_ps1 doesn't break if GOPATH is later changed/unset,
  # and so we don't leak a GOPATH value into the shell. Survives the _setup_*
  # cleanup (not prefixed) because _update_ps1 reads it at every prompt.
  _PL_GO_BIN="$HOME/go/bin/powerline-go"
  _update_ps1() {
      # In addition to defaults:
      #   displays error status
      #   displays count of background jobs.
      # Plain `jobs -p` includes Done-but-not-yet-reaped entries, causing
      # phantom counts at prompt time. `-r` (running) and `-s` (stopped)
      # filter those out, but bash doesn't OR them, so we sum two calls.
      PS1="$("$_PL_GO_BIN" -error $? -jobs $(( $(jobs -rp | wc -l) + $(jobs -sp | wc -l) )))"
  }

  if [ "$TERM" != "linux" ] && [ -f "$_PL_GO_BIN" ]; then
      # Guard against re-sourcing: install once. Otherwise PROMPT_COMMAND
      # accumulates "_update_ps1; _update_ps1; ..." each time .bashrc is sourced
      # (which also breaks the error indicator, since the 2nd call sees $?=0).
      [[ "$PROMPT_COMMAND" == *_update_ps1* ]] || PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
  fi
  bashlog "end _setup_powerline"
}

### WSL2 specific code
_setup_windows() {
  bashlog "start _setup_windows"

  # Set Windows native user and home directory.
  # This is a long walk for a small drink of water.
  WINUSER=$(/mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0/powershell.exe /c "echo -n \$env:username")
  WINUSER="${WINUSER//$'\r'/}"   # strip any trailing CR (pure bash: no subshell, space-safe)
  export WINUSER WINHOME="/mnt/c/Users/$WINUSER"

  # Add "start" cmd to wsl2:
  # https://superuser.com/questions/1182275/how-to-use-start-command-in-bash-on-windows
  start() {
    local abspath wpath
    abspath=$(readlink -f "$1");
    wpath=$(/bin/wslpath -w "$abspath");
    powershell.exe -Command Start-Process "$wpath"
  }

  # Prerequisites for powerline on WSL2:
  #   sudo apt install golang-go
  #   go install github.com/justjanne/powerline-go@latest
  # ALSO
  # Need to install and use "CascadiaCodePL" font or things will look all wonky
  # https://github.com/microsoft/cascadia-code

  # How to set Windows Terminal Starting Directory for WSL2:
  # As of 2021: https://docs.microsoft.com/en-us/windows/terminal/troubleshooting
  # or. https://goulet.dev/posts/how-to-set-windows-terminal-starting-directory/

  # Since "shutdown" and "reboot" don't work on WSL (no init) these aliases
  # are workarounds.
  # https://stackoverflow.com/questions/66375364/shutdown-or-reboot-a-wsl-session-from-inside-the-wsl-session
  alias shutdown='wsl.exe --terminate $WSL_DISTRO_NAME'
  alias reboot='wsl.exe --terminate $WSL_DISTRO_NAME'
  # This suggestion from SO attempts to restart another window, but it isn't reliable
  # No point to reboot; next invocation of WSL will start it again anyways.
  #alias reboot='cd /mnt/c/ && cmd.exe /c start "rebooting WSL" cmd /c "timeout 5 && wsl -d $WSL_DISTRO_NAME" && wsl.exe --terminate $WSL_DISTRO_NAME'

  bashlog "end _setup_windows"
}

### Linux (non-WSL2) specific code:
_setup_linux() {
  bashlog "start _setup_linux"

  alias start="xdg-open"

  # NOTE: prerequisites for powerline on ubuntu:
  #   sudo apt install golang-go
  #   go install github.com/justjanne/powerline-go@latest
  # ALSO: install fonts as per https://github.com/powerline/fonts
  #   sudo apt-get install fonts-powerline

  bashlog "end _setup_linux"
}

_setup_main() {
  # OS specifics
  # As per https://stackoverflow.com/questions/38086185/how-to-check-if-a-program-is-run-in-bash-on-ubuntu-on-windows-and-not-just-plain
  if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null ; then
      bashlog "WSL detected..."
      _setup_windows
  else
      bashlog "Linux detected..."
      _setup_linux
  fi

  ### Set up powerline
  _setup_powerline

  ### kubernetes:
  # https://www.atomiccommits.io/everything-useful-i-know-about-kubectl/
  if command -v kubectl &> /dev/null; then
    # kubectl's completion script defines __start_kubectl; without sourcing
    # it, the `complete -F __start_kubectl k` below has no function to call.
    # Cache the generated script and refresh only when the kubectl binary
    # changes, so we don't run kubectl on every shell startup.
    local kube_comp="$HOME/.cache/kubectl-completion.bash"
    if [ ! -s "$kube_comp" ] || [ "$(command -v kubectl)" -nt "$kube_comp" ]; then
      mkdir -p "$HOME/.cache"
      kubectl completion bash > "$kube_comp"
    fi
    . "$kube_comp"
    alias k=kubectl
    complete -o default -F __start_kubectl k   # reuse kubectl's completion for `k`
  fi

  ### some generic aliases:
  alias ls="ls -F"
  alias dir="ls -Fla"
  alias mkae="make"
  alias cd..="cd .."
  alias ips="landscape-sysinfo --sysinfo-plugins=Network"

  ### Add custom bash completions.
  ### Depending on context (login shell or not?), this may have
  ### already been done in which case this is a no-op.
  if [[ -f /etc/profile.d/bash_completion.sh ]]; then
    . /etc/profile.d/bash_completion.sh
  fi

  ### nvm (lazy-loaded):
  export NVM_DIR="$HOME/.nvm"
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    # Sourcing nvm.sh is slow (~0.5-1s), so defer it until the first use of
    # nvm/node/npm/npx. Each stub loads the real nvm (+ its completion),
    # removes all the stubs, then re-runs the requested command.
    _load_nvm() {
      unset -f nvm node npm npx _load_nvm
      \. "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
      hash -r   # forget any stale command paths so nvm's node/npm win
    }
    nvm()  { _load_nvm; nvm  "$@"; }
    node() { _load_nvm; node "$@"; }
    npm()  { _load_nvm; npm  "$@"; }
    npx()  { _load_nvm; npx  "$@"; }
  fi

  # ssh-agent: prefer an already-provided agent (GNOME keyring, agent
  # forwarding, a parent shell). Otherwise reuse a single shared agent
  # recorded in ~/.ssh/agent.env across all shells, starting a new one only
  # when none is reachable -- so we don't orphan a fresh agent per terminal.
  if [ -z "$SSH_AUTH_SOCK" ] || [ ! -S "$SSH_AUTH_SOCK" ]; then
    local SSH_ENV="$HOME/.ssh/agent.env"
    [ -f "$SSH_ENV" ] && . "$SSH_ENV" >/dev/null
    # ssh-add -l exit codes: 0 = agent has keys, 1 = agent but no keys,
    # 2 = no agent reachable (dead or stale socket) -> start a fresh one.
    ssh-add -l >/dev/null 2>&1
    if [ $? -eq 2 ]; then
      bashlog "starting ssh-agent..."
      mkdir -p "$HOME/.ssh"
      (umask 077; ssh-agent > "$SSH_ENV")
      . "$SSH_ENV" >/dev/null
    fi
  fi

  ### sdkman (must be near end of _setup_main):
  export SDKMAN_DIR="$HOME/.sdkman"
  [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

  ### Execute local bash configuration.
  if [[ -f ~/.bashrc.local ]]; then
    . ~/.bashrc.local
  fi

  ### Remove all setup-only functions (named `_setup_*`), including this one.
  ### Unsetting a *running* function is safe: bash finishes the current
  ### invocation from its in-memory copy; only the name binding disappears.
  unset -f $(compgen -A function _setup_)
}

_setup_main

### atuin (shell history):
### IMPORTANT: must be sourced at top-level, NOT inside a function.
### bash-preexec.sh uses `declare -a precmd_functions` / `preexec_functions`,
### and `declare` inside a function creates LOCAL arrays that vanish when the
### function returns -- which silently breaks atuin's command recording.
### Symptoms: Ctrl-R still works (older history readable), but new commands
### are not saved. ATUIN_SESSION is set but preexec_functions is unset.
if [[ -f "$HOME/.atuin/bin/env" ]]; then
  . "$HOME/.atuin/bin/env"
  [[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
  eval "$(atuin init bash)"
fi

### ssh wrapper: color-codes terminal background by host.
### Reads host-to-color mappings from ~/.config/ssh-terminal-colors
### Format: one entry per line, glob_pattern followed by hex_color
### e.g.:  *prod*  #3b0a0a
ssh() {
    local color=""
    local default_color="#1a1b26"
    local config="$HOME/.config/ssh-terminal-colors"

    if [[ -f "$config" ]]; then
        while read -r pattern hex; do
            [[ -z "$pattern" || "$pattern" == \#* ]] && continue
            case "$*" in
                $pattern) color="$hex"; break ;;
            esac
        done < "$config"
    fi

    # Tint this terminal's background for the session, then restore it.
    # ssh runs in a subshell whose EXIT trap restores the background on
    # every exit path (normal logout, Ctrl-C, kill), so the terminal is
    # never left tinted. Escapes go to /dev/tty rather than stdout, so
    # redirecting/piping ssh output (`ssh host cmd >file`) can't capture them.
    (
        trap 'printf "\033]111\007" 2>/dev/null >/dev/tty' EXIT
        trap 'exit' INT TERM HUP
        printf "\033]11;%s\007" "${color:-$default_color}" 2>/dev/null >/dev/tty
        command ssh "$@"
    )
}

bashlog "end .bashrc"
