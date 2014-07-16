#!/bin/sh
# Script: /usr/share/sshupdated/wrapper.sh 

case "$SSH_ORIGINAL_COMMAND" in
	"inventory")
		/usr/bin/dpkg -l
		;;
	"patch")
                export DEBIAN_FRONTEND=noninteractive 
		/usr/bin/apt-get update && /usr/bin/apt-get upgrade -y -q --force-yes
		;;
  "upgrade-major")
    echo "This is supposed to do a major upgrade of your distribution release but we havnt tried it out on this platform yet."
  ;;
  "upgrade-major-n-reboot")
    echo "This is supposed to do a major upgrade of your distribution release but we havnt tried it out on this platform yet."
  ;;
	"available-updates")
                export DEBIAN_FRONTEND=noninteractive 
		/usr/bin/apt-get update && echo n | /usr/bin/apt-get upgrade 
		;;
	"patch-n-reboot")
                export DEBIAN_FRONTEND=noninteractive 
		/usr/bin/apt-get update && /usr/bin/apt-get upgrade -y -q --force-yes
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
