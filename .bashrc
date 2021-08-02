### Michael Gebis's .bashrc; https://github.com/michael-gebis/dotfiles
### See LICENSE file for details (MIT License)
### If any of my work helps you, let me know by tweeting @IvyMike

if [ -f ~/.bashlog ]; then . ~/.bashlog; else function log() { :; }; fi

log "start .bashrc"

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
function do_powerline {
  log "start do_powerline"
  GOPATH=$HOME/go
  function _update_ps1() {
      # In addition to defaults:
      #   displays error status
      #   displays count of background jobs.
      PS1="$($GOPATH/bin/powerline-go -error $? -jobs $(jobs -p | wc -l))"

      # Clears errors after displaying them once
      # set "?"
  }

  if [ "$TERM" != "linux" ] && [ -f "$GOPATH/bin/powerline-go" ]; then
      PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
  fi
  log "end do_powerline"
}

### WSL2 specific code
function do_windows {
  log "start do_windows"

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

  # Pretty prompt
  # https://www.hanselman.com/blog/how-to-make-a-pretty-prompt-in-windows-terminal-with-powerline-nerd-fonts-cascadia-code-wsl-and-ohmyposh

  # Prerequisites for powerline on WSL2: 
  #   sudo apt install golang-go
  #   go get -u github.com/justjanne/powerline-go

  # ALSO
  # Need to install and use "CascadiaCodePL" font or things will look all wonky
  # https://github.com/microsoft/cascadia-code

  do_powerline
  log "end do_windows"
}

### Linux (non-WSL2) specific code:
function do_linux {
  log "start do_linux"
  # prerequisites for powerline on ubuntu:
  #   sudo apt install golang-go
  #   go get -u github.com/justjanne/powerline-go

  # ALSO: install fonts as per https://github.com/powerline/fonts
  #   sudo apt-get install fonts-powerline
  do_powerline
  log "end do_linux"
}
  
# OS specifics
# As per https://stackoverflow.com/questions/38086185/how-to-check-if-a-program-is-run-in-bash-on-ubuntu-on-windows-and-not-just-plain
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null ; then
    log "WSL detected..."
    do_windows
else
    log "Linux detected..."
    do_linux
fi

### Editor
export VISUAL=vi
export EDITOR="$VISUAL"

### rust:
pathprepend $HOME/.cargo/bin

### kubernetes:
# https://www.atomiccommits.io/everything-useful-i-know-about-kubectl/
alias k="kubectl"
complete -F __start_kubectl k

### Execute custom bash completions
### Depending on context, this may have already been done and
### will be a no-op.
if [[ -f /etc/profile.d/bash_completion.sh ]]; then
  . /etc/profile.d/bash_completion.sh
fi

### Execute local bash configuration
if [[ -f ~/.bashrc.local ]]; then
  . ~/.bashrc.local
fi

log "end .bashrc"
