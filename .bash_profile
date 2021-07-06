# Any login-specific stuff would go here
# In this case, it's nothing
###
echo "begin .bash_profile"

# Always run my .bashrc
if [ -f ~/.bashrc ]; then . ~/.bashrc; fi
echo "end .bash_profile"