VERBOSE=true
# Any login-specific stuff would go here
# In this case, it's nothing
###
if [[ $VERBOSE ]] ; then echo "start .bash_profile"; fi

# Always run my .bashrc
if [ -f ~/.bashrc ]; then . ~/.bashrc; fi

if [[ $VERBOSE ]] ; then echo "end .bashrc_profile"; fi
