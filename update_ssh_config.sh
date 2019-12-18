#! /bin/bash
# For Vagrant and LIRW
# Removing old and adding new .ssh/config entries for servers,
# that are listed in servers_list file.
# Expect FUN if server in server's list has same name as some other
# server in ssh config. just sayin'
# TODO: make script smarter, isntead of inserting before the last
# line, just delete the START and END comments, and re-add them after
# re-adding config files.

#set -x

#backup, but only once per hour
if [[ ! -e ~/.ssh/config.bak.$(date +%H.%d%m%y) ]]; then
    cp ~/.ssh/config ~/.ssh/config.bak.$(date +%H.%d%m%y)
fi

mapfile -t servers < ./servers_list

#remove old entries
for sys in ${servers[*]} 
do
    sed -i "/Host ${sys}/,+10d" ~/.ssh/config
done

#add new entries
for sys in ${servers[*]}
do
    { head --lines=-1 ~/.ssh/config;
 printf "$( wagrant ssh-config "$sys" | sed "s/Host default/Host $sys/" )\n\n";
 tail -1 ~/.ssh/config; } > ~/.ssh/config-tmp
    mv ~/.ssh/config-tmp ~/.ssh/config
done
