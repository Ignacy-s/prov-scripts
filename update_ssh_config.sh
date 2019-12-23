#! /bin/bash

# For Vagrant and LIRW course

# Removing old and adding new .ssh/config entries for servers that are
# listed in servers_list file.  Expect FUN if server in server's list
# has same name as some other server in ssh config.
# 
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
for i in $(vagrant global-status --prune | grep running | \
	       awk '{ print $5 }' )
    do servers_array+=( "${i##*/}" );
done
if [ $debug_mode -eq 1 ]; then
    echo "Oto lista serwerow: ${servers_array[*]}"
fi

# Define start and end line strings.
start_line="#Vagrant Projects START"
end_line="#Vagrant Projects END"
# Check if there is only one of START and STOP lines.
for line in "$start_line" "$end_line"; do
    how_many_lines="$(grep -c "$line" ~/.ssh/config)"
    if [ "$how_many_lines" -ne 1 ]; then
	echo "There are $how_many_lines of $line"
	echo "Aborting"
	exit 1
    fi
done
#travelling exit 0 to debug the script step by step.
exit 0

# Remember where_it_started (the Vagrant block in ssh_config)
where_it_started=$(sed -n  "/$start_line/ =" ~/.ssh/config)
# Remove old entries.
sed -i "/$start_line/,/$end_line/ d" ~/.ssh/config 


# Add new entries to .ssh/config
{
    #this will "save" the content of ssh_config
head -$((where_it_started - 1)) ~/.ssh/config
echo "$start_line"
for sys in "${servers_array[@]}"
do
    #do nothing if VM's status is not running
    if [ $(wagrant status $sys | grep -c running) -lt 1 ] ; then
	continue
    fi
    printf "$( wagrant ssh-config "$sys" | sed "s/Host default/Host $sys/" )\n\n";
done
echo "$end_line"
tail -n +$where_it_started ~/.ssh/config; } > ~/.ssh/config-tmp
mv ~/.ssh/config-tmp ~/.ssh/config
exit 0
