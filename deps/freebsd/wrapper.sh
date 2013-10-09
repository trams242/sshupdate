#!/bin/sh
# Script: /usr/local/share/sshupdated/wrapper.sh 

PKGTOOL="/usr/sbin/pkg"
SYSTEMTOOL="/usr/sbin/freebsd-update"

case "$SSH_ORIGINAL_COMMAND" in
	"inventory")
		$PKGTOOL info
		;;
	"patch")
		$PKGTOOL upgrade -q -y
		;;
	"available-updates")
		$PKGTOOL upgrade -q -n
		;;
	"patch-system")
		$SYSTEMTOOL fetch install
		;;
	"patch-system-n-reboot")
		$SYSTEMTOOL fetch install
		wall "Warning: System will reboot in 1 min"
		wall "Remember to run patch-system after reboot"
		sleep 60
		init 6
		fi
                ;;	
#	"reboot-if-needed")
#		LAST_KERNEL=$(rpm -q --last kernel | sed 's/^kernel-\([a-z0-9._-]*\).*/\1/g' | head -1)
#		CURRENT_KERNEL=$(uname -r)
#		test $LAST_KERNEL = $CURRENT_KERNEL || init 6
#		;;
#	"check-if-reboot-req")
#		LAST_KERNEL=$(rpm -q --last kernel | sed 's/^kernel-\([a-z0-9._-]*\).*/\1/g' | head -1)
#		CURRENT_KERNEL=$(uname -r)
#		if [ $LAST_KERNEL != $CURRENT_KERNEL ]; then 
#			echo "Reboot required"
#		else
#			echo "Already running on latest installed kernel"
#		fi
#		;;
	*)
		echo "Sorry. Only these commands are available to you:"
		echo "inventory patch available-updates patch-system patch-system-n-reboot"
		exit 1
		;;
esac
