#! /bin/bash

# Add running Vagrant servers to ~/.ssh/config, so they can be
# accessed with ssh $server_name or from inside emacs.

#Debugging variables
#set -e
#set -x
debug_mode=0


# Backup ~/.ssh/config, but only once per hour
if [[ ! -e ~/.ssh/config.bak.$(( $(date +%s)/(60*60) )) ]]; then
    if [ $debug_mode -eq 1 ]; then
	echo "backing up config to config."$(($(date +%s)/(60*60)))
    fi
    cp ~/.ssh/config ~/.ssh/config.bak.$(($(date +%s)/(60*60)))
elif [ $debug_mode -eq 1 ]; then
    echo ".ssh/confing already backed up this hour."
fi

# Create an array with names of running servers.
unset servers_array
for i in $(vagrant global-status --prune | grep running | \
	       awk '{ print $5 }' )
    do servers_array+=( "${i##*/}" );
done
if [ $debug_mode -eq 1 ]; then
    echo "Servers list: ${servers_array[*]}"
fi

# Define start and end line strings.
start_line="#Vagrant Projects START"
end_line="#Vagrant Projects END"
    
# Check if there is at most one of START and STOP lines.
for line in "$start_line" "$end_line"; do
    how_many_lines="$(grep -c "$line" ~/.ssh/config)"
    if [ "$how_many_lines" -gt 1 ]; then
	echo "There are $how_many_lines of $line"
	echo "Aborting"
       	exit 1
    fi
done

# Check if script is run for the first time
# (by checking if $start_line exists in the file)
if [ $how_many_lines -eq 0 ]; then
    echo "Welcome aboard!"
    where_it_started=$(sed -n "$ =" ~/.ssh/config)
else
# Remember where_it_started (the Vagrant block in ~/.ssh/config)
    where_it_started=$(sed -n  "/$start_line/ =" ~/.ssh/config)
    if [ $debug_mode -eq 1 ]; then
	echo "Block starts at: $where_it_started"
    fi
fi
# Remove old entries.
sed -i "/$start_line/,/$end_line/ d" ~/.ssh/config 

# Add new entries to .ssh/config
{
    #this will "save" the content of ~/.ssh/config
    head -$((where_it_started - 1)) ~/.ssh/config
    echo "$start_line"
    for sys in "${servers_array[@]}"
        do
	#do nothing if VM's status is not running
	if [ $(wagrant status $sys | grep -c running) -lt 1 ] ; then
	    continue
	fi
	#use wagrant to print the VM-specific ssh config
	printf "$( wagrant ssh-config "$sys" |\
	       sed "s/Host default/Host $sys/" )\n\n";
    done
    echo "$end_line"
    tail -n +$where_it_started ~/.ssh/config
} > ~/.ssh/config-tmp

mv ~/.ssh/config-tmp ~/.ssh/config
exit 0
