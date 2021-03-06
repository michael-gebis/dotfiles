### Michael Gebis's .bashrc; https://github.com/michael-gebis/dotfiles
### See LICENSE file for details (MIT License)
### If any of my work helps you, let me know by tweeting @IvyMike

if [ -f ~/.bashlog ]; then . ~/.bashlog; else function bashlog() { :; }; fi

# Any login-specific stuff would go here
# In this case, it's nothing
###
bashlog "start .bash_profile"

# Always run my .bashrc
if [ -f ~/.bashrc ]; then . ~/.bashrc; fi

bashlog "end .bash_profile"
