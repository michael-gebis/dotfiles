### Michael Gebis's .bashrc; https://github.com/michael-gebis/dotfiles
### See LICENSE file for details (MIT License)
### If any of my work helps you, let me know by tweeting @IvyMike

if [ -f ~/.bashlog ]; then . ~/.bashlog; else function bashlog() { :; }; fi

bashlog "start .bashrc"

### https://superuser.com/questions/39751/add-directory-to-path-if-its-not-already-there
function pathprepend() {
  for ((i=$#; i>0; i--)); do
    ARG=${!i}
    if [ -d "$ARG" ] && [[ ":$PATH:" != *":$ARG:"* ]]; then
        PATH="$ARG${PATH:+":$PATH"}"
    fi
  done
}

### As per https://github.com/justjanne/powerline-go
### Also https://www.hanselman.com/blog/how-to-make-a-pretty-prompt-in-windows-terminal-with-powerline-nerd-fonts-cascadia-code-wsl-and-ohmyposh
function do_powerline {
  bashlog "start do_powerline"
  GOPATH=$HOME/go
  function _update_ps1() {
      # In addition to defaults:
      #   displays error status
      #   displays count of background jobs.
      # Plain `jobs -p` includes Done-but-not-yet-reaped entries, causing
      # phantom counts at prompt time. `-r` (running) and `-s` (stopped)
      # filter those out, but bash doesn't OR them, so we sum two calls.
      PS1="$($GOPATH/bin/powerline-go -error $? -jobs $(( $(jobs -rp | wc -l) + $(jobs -sp | wc -l) )))"

      # Clears errors after displaying them once
      # set "?"
  }

  if [ "$TERM" != "linux" ] && [ -f "$GOPATH/bin/powerline-go" ]; then
      PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
  fi
  bashlog "end do_powerline"
}

### WSL2 specific code
function do_windows {
  bashlog "start do_windows"

  # Set Windows native user and home directory.
  # This is a long walk for a small drink of water.
  export WINUSER=$(/mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0/powershell.exe /c "echo -n \$env:username")
  export WINUSER=$(echo $WINUSER | sed -e 's/\r//g')
  export WINHOME="/mnt/c/Users/$WINUSER"

  # Add "start" cmd to wsl2:
  # https://superuser.com/questions/1182275/how-to-use-start-command-in-bash-on-windows
  function start {
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

  bashlog "end do_windows"
}

### Linux (non-WSL2) specific code:
function do_linux {
  bashlog "start do_linux"

  alias start="xdg-open"

  # NOTE: prerequisites for powerline on ubuntu:
  #   sudo apt install golang-go
  #   go install github.com/justjanne/powerline-go@latest
  # ALSO: install fonts as per https://github.com/powerline/fonts
  #   sudo apt-get install fonts-powerline

  bashlog "end do_linux"
}

function bash_main {
  # OS specifics
  # As per https://stackoverflow.com/questions/38086185/how-to-check-if-a-program-is-run-in-bash-on-ubuntu-on-windows-and-not-just-plain
  if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null ; then
      bashlog "WSL detected..."
      do_windows
  else
      bashlog "Linux detected..."
      do_linux
  fi

  ### Set up powerline
  do_powerline

  ### editor settings
  export VISUAL=vi
  export EDITOR="$VISUAL"

  ### rust:
  pathprepend $HOME/.cargo/bin

  ### local bin:
  pathprepend $HOME/.local/bin

  ### kubernetes:
  # https://www.atomiccommits.io/everything-useful-i-know-about-kubectl/
  if command -v kubectl &> /dev/null; then
    alias k="kubectl"
    complete -F __start_kubectl k
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

  ### nvm:
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

  # Reuse existing ssh-agent (e.g. from GNOME keyring) or start a new one
  if [ -z "$SSH_AUTH_SOCK" ] || [ ! -S "$SSH_AUTH_SOCK" ]; then
    bashlog "starting ssh-agent..."
    { eval $(ssh-agent); } &> /dev/null
  fi

  ### sdkman (must be near end of bash_main):
  export SDKMAN_DIR="$HOME/.sdkman"
  [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

  ### Execute local bash configuration.
  if [[ -f ~/.bashrc.local ]]; then
    . ~/.bashrc.local
  fi

}

bash_main

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

### Cleanup functions needed only during setup.
### I wish there was a cleaner way to do this.
unset -f pathprepend do_windows do_linux do_powerline bash_main

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

    printf "\033]11;%s\007" "${color:-$default_color}"
    command ssh "$@"
    printf "\033]111\007" # Reset
}

bashlog "end .bashrc"
