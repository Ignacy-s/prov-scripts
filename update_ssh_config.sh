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


#Debugging variables
set -e
set -x
debug_mode=1


# Backup, but only once per hour
if [[ ! -e ~/.ssh/config.bak.$(( $(date +%s)/(60*60) )) ]]; then
    if [ $debug_mode -eq 1 ]; then
	echo "backing up config to config."$(($(date +%s)/(60*60)))
    fi
    cp ~/.ssh/config ~/.ssh/config.bak.$(($(date +%s)/(60*60)))
elif [ $debug_mode -eq 1 ]; then
    echo ".ssh/confing already backed up this hour."
fi

# read server's list from file (leaving commented in case it comes in
# handy at some point).
#  mapfile -t servers < ./servers_list

# Remove old entries (old version).
#Left commented for reference on how to use arrays:
#for sys in ${servers[*]} 
#do
#    sed -i "/Host ${sys}/,+10d" ~/.ssh/config
#done


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

# Create an array with names of running servers.
unset servers_array
for i in $(vagrant global-status --prune | grep running | cut -f6 -d' ') ; do servers_array+=( "${i##*/}" ); done
if [ $debug_mode -eq 1 ]; then
    echo "Oto lista serwerow:${servers_array[*]}"
fi


#travelling exit 0 to debug the script step by step.
exit 0

# Remember where_it_started (the Vagrant block in ssh_config)
where_it_started=$(sed -n  '/#Vagrant Projects START/ =' ~/.ssh/config)
# Remove old entries.
sed -i '/#Vagrant Projects START/,/#Vagrant Projects END/ d'\
~/.ssh/config 


# Add new entries to .ssh/config
{
    #this will "save" the content of ssh_config
head -$((where_it_started - 1)) ~/.ssh/config
echo "#Vagrant Projects START"
for sys in "${servers_array[@]}"
do
    #do nothing if VM's status is not running
    if [ $(wagrant status $sys | grep -c running) -lt 1 ] ; then
	continue
    fi
    printf "$( wagrant ssh-config "$sys" | sed "s/Host default/Host $sys/" )\n\n";
done
echo "#Vagrant Projects END"
tail -n +$where_it_started ~/.ssh/config; } > ~/.ssh/config-tmp
mv ~/.ssh/config-tmp ~/.ssh/config
exit 0
