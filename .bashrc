VERBOSE=true
if [[ $VERBOSE ]] ; then echo "start .bashrc"; fi

### https://superuser.com/questions/39751/add-directory-to-path-if-its-not-already-there
pathprepend() {
  for ((i=$#; i>0; i--)); do
    ARG=${!i}
    if [ -d "$ARG" ] && [[ ":$PATH:" != *":$ARG:"* ]]; then
        PATH="$ARG${PATH:+":$PATH"}"
    fi
  done
}

### As per https://github.com/justjanne/powerline-go
function do_powerline {
  if [[ $VERBOSE ]]; then echo "start do_powerline"; fi
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
  if [[ $VERBOSE ]]; then echo "end do_powerline"; fi
}

### WSL2 specific code
function do_windows {
  if [[ $VERBOSE ]]; then echo "start do_windows"; fi  

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
  if [[ $VERBOSE ]]; then echo "end do_windows"; fi  
}

### Linux (non-WSL2) specific code:
function do_linux {
  if [[ $VERBOSE ]] ; then echo "start do_linux"; fi
  # prerequisites for powerline on ubuntu:
  #   sudo apt install golang-go
  #   go get -u github.com/justjanne/powerline-go

  # ALSO: install fonts as per https://github.com/powerline/fonts
  #   sudo apt-get install fonts-powerline
  do_powerline
  if [[ $VERBOSE ]] ; then echo "end do_linux"; fi
}
  
# OS specifics
# As per https://stackoverflow.com/questions/38086185/how-to-check-if-a-program-is-run-in-bash-on-ubuntu-on-windows-and-not-just-plain
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null ; then
    if [[ $VERBOSE ]]; then echo "Windows 10 detected..."; fi
    do_windows
else
    if [[ $VERBOSE ]]; then echo "Linux detected..."; fi
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
if [[ -f /etc/profile.d/bash_completion.sh ]]; then
  if [[ $VERBOSE ]]; then echo "sourcing bash_completions..."; fi
  . /etc/profile.d/bash_completion.sh
fi

if [[ $VERBOSE ]]; then echo "end .bashrc"; fi
