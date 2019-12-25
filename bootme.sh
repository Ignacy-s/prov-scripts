#! /bin/bash
# Script to quickly boot all servers given as arguments.
for serv in $@ ; do
    echo "Booting ${serv}."
    wagrant up $serv && echo "$serv is up." || {
	    echo "Failed to boot: $serv"
	    exit 1; } 
    sleep 1
done
exit 0
