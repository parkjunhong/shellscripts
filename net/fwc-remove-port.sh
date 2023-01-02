#!/usr/bin/env bash

while [ ! -z "$1" ];
do
	{
		sudo firewall-cmd --remove-port=$1 --permanent
	}||{
		echo
		echo "Oops.... Errors..."
	}
	shift
done

echo 
echo "Reload firwall list..."
sudo firewall-cmd --reload

echo
echo "List firewalls"
sudo firewall-cmd --list-all

exit 0


