#!/bin/sh
# Script: /usr/share/sshupdated/wrapper.sh 

case "$SSH_ORIGINAL_COMMAND" in
	"inventory")
		/usr/bin/dpkg -l
		;;
	"patch")
		/usr/bin/apt-get update && /usr/bin/apt-get upgrade -y -q
		;;
	"available-updates")
		echo n | /usr/bin/apt-get upgrade 
		;;
	"patch-n-reboot")
		/usr/bin/apt-get update && /usr/bin/apt-get upgrade -y -q
                if [ -f /var/run/reboot-required ] 
                then
		  echo "Warning: System will reboot in 1 min" | wall
		  sleep 60
                  shutdown -r now
		fi
                ;;	
	"reboot-if-needed")
                if [ -f /var/run/reboot-required ] 
                then
                  shutdown -r now
		fi
		;;
	"check-if-reboot-req")
                if [ -f /var/run/reboot-required ] 
                then
                  echo "Reboot required"
		else
		  echo "Already running on latest installed kernel"
		fi
		;;
	*)
		echo "Sorry. Only these commands are available to you:"
		echo "inventory patch available-updates reboot-if-needed check-if-reboot-req"
		exit 1
		;;
esac
