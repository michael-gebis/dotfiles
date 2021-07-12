echo "start .bashrc"
### Functions
# https://superuser.com/questions/39751/add-directory-to-path-if-its-not-already-there
pathprepend() {
  for ((i=$#; i>0; i--)); 
  do
    ARG=${!i}
    if [ -d "$ARG" ] && [[ ":$PATH:" != *":$ARG:"* ]]; then
        PATH="$ARG${PATH:+":$PATH"}"
    fi
  done
}

# For rust:
pathprepend $HOME/.cargo/bin
echo "end .bashrc"

function do_windows {
  # Windows native user and home directory. This is a long walk for a small drink of water.
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

  # Prerequisites: 
  # sudo apt install golang-go
  # go get -u github.com/justjanne/powerline-go

  # ALSO
  # Need to install and use "CascadiaCodePL" font or things will look all wonky
  # https://github.com/microsoft/cascadia-code

  GOPATH=$HOME/go
  function _update_ps1() {
      PS1="$($GOPATH/bin/powerline-go -error $?)"
  }
  if [ "$TERM" != "linux" ] && [ -f "$GOPATH/bin/powerline-go" ]; then
      PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
  fi
}

function do_linux {
  #prerequisites
  # sudo apt install golang-go
  # go get -u github.com/justjanne/powerline-go

  # ALSO: install fonts as per https://github.com/powerline/fonts
  GOPATH=$HOME/go
  function _update_ps1() {
    eval "$($GOPATH/bin/powerline-go -error $? -shell bash -eval -modules-right git)"
  }

  if [ "$TERM" != "linux" ] && [ -f "$GOPATH/bin/powerline-go" ]; then
    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
  fi
}
  
# OS specifics
# As per https://stackoverflow.com/questions/38086185/how-to-check-if-a-program-is-run-in-bash-on-ubuntu-on-windows-and-not-just-plain
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null ; then
    echo "Windows 10 Bash"
    do_windows
else
    echo "Not Windows 10 Bash"
    do_linux
fi
