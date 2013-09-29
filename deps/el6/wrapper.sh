#!/bin/sh
# Script: /usr/share/sshupdated/wrapper.sh 

case "$SSH_ORIGINAL_COMMAND" in
	"inventory")
		/bin/rpm -qa
		;;
	"patch")
		/usr/bin/yum update -y --quiet
		;;
	"available-updates")
		/usr/bin/yum list updates
		;;
	"patch-n-reboot")
		/usr/bin/yum update -y --quiet
		LAST_KERNEL=$(rpm -q --last kernel | sed 's/^kernel-\([a-z0-9._-]*\).*/\1/g' | head -1)
		CURRENT_KERNEL=$(uname -r)
		if [ $LAST_KERNEL != $CURRENT_KERNEL ]; then
			wall "Warning: System will reboot in 1 min"
			sleep 60
			init 6
		fi
                ;;	
	"reboot-if-needed")
		LAST_KERNEL=$(rpm -q --last kernel | sed 's/^kernel-\([a-z0-9._-]*\).*/\1/g' | head -1)
		CURRENT_KERNEL=$(uname -r)
		test $LAST_KERNEL = $CURRENT_KERNEL || init 6
		;;
	"check-if-reboot-req")
		LAST_KERNEL=$(rpm -q --last kernel | sed 's/^kernel-\([a-z0-9._-]*\).*/\1/g' | head -1)
		CURRENT_KERNEL=$(uname -r)
		if [ $LAST_KERNEL != $CURRENT_KERNEL ]; then 
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
