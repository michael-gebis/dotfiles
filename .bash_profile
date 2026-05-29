### Michael Gebis's .bash_profile; https://github.com/michael-gebis/dotfiles
### See LICENSE file for details (MIT License)

[ -f ~/.bashlog ] && . ~/.bashlog
declare -F bashlog >/dev/null || bashlog() { :; }

# Any login-specific stuff would go here
# In this case, it's nothing
###
bashlog "start .bash_profile"

# Always run my .bashrc
if [ -f ~/.bashrc ]; then . ~/.bashrc; fi

bashlog "end .bash_profile"
