#! /bin/bash
# For Vagrant and LIRW
# Removing old and adding new .ssh/config entries for servers,
# that are listed in servers_list file.
# Expect FUN if server in server's list has same name as some other
# server in ssh config. just sayin'
# TODO: make script smarter, isntead of inserting before the last
# line, just delete the START and END comments, and re-add them after
# re-adding config files.

# Wed 18 Dec 2019 06:23:42 PM CET Ignacy
# Attempting to change the script to stop using servers_list and
# instead take a list of running servers from vagrant global status.



#set -x

#backup, but only once per hour
if [[ ! -e ~/.ssh/config.bak.$(date +%H.%d%m%y) ]]; then
    cp ~/.ssh/config ~/.ssh/config.bak.$(date +%H.%d%m%y)
fi

# read server's list from file (leaving commented in case it comes in
# handy at some point).
 mapfile -t servers < ./servers_list


# Remove old entries (old version).
#Left commented for reference on how to use arrays:
#for sys in ${servers[*]} 
#do
#    sed -i "/Host ${sys}/,+10d" ~/.ssh/config
#done

# Remember where_it_started (the Vagrant block in ssh_config)
where_it_started=$(sed -n  '/#Vagrant Projects START/ =' ~/.ssh/config)
# Remove old entries.
sed -i '/#Vagrant Projects START/,/#Vagrant Projects END/ d'\
~/.ssh/config 

# Here I need to get a new list of servers, preferably in an array of
# either server names (what I will use and what ssh_config needs, or
# vagrant server hashes (which wagrant command supplies to
# vagrant). Another array, preferably associative with key-values -
# server-hash -> name or vice versa.
# Let's say it(the arrary)'s called servers


# Adding new entries can be done two ways. Since now I can use sed 'i'
# function, I could just insert each server config batch in the right
# place. Instead decided to upgrade the old method. The for loop can
# be inside the curly braces, so that the block init and close lines
# can be written only ones. Need to trace the pointer somehow. Started
# playing with where it ends variable, but then remembered, that I'm
# still reading the unchanged ssh config and writing into a temp ssh
# config.

#Add new entries
{ head -$(($where_it_started - 1)) ~/.ssh/config
echo "#Vagrant Projects START"
for sys in ${servers[*]}
do
    printf "$( wagrant ssh-config "$sys" | sed "s/Host default/Host $sys/" )\n\n";
done
 tail -n +$where_it_started ~/.ssh/config; } > ~/.ssh/config-tmp
    mv ~/.ssh/config-tmp ~/.ssh/config

