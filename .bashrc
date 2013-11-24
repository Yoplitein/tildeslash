#read ~/.bash_profile if necessary
if [ "$(alias | grep -i grepi | wc -l)" -eq "0" ]; then #hacky, but it works
    source ~/.bash_profile
fi

