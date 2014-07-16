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
  "upgrade-major")
    echo "This is supposed to do a major upgrade of your distribution release but we havnt tried it out on this platform yet."
  ;;
  "upgrade-major-n-reboot")
    echo "This is supposed to do a major upgrade of your distribution release but we havnt tried it out on this platform yet."
  ;;
	"available-updates")
		$PKGTOOL upgrade -q -n
		;;
	"patch-n-reboot")
		$PKGTOOL upgrade -q -y
		wall "Warning: System will reboot in 1 min"
		wall "Remember to run patch-system after reboot"
		sleep 60
		init 6
		;;
	"system-upgrade")
		$SYSTEMTOOL fetch install
		;;
	"system-upgrade-n-reboot")
		$SYSTEMTOOL fetch install
		wall "Warning: System will reboot in 1 min"
		wall "Remember to run patch-system after reboot"
		sleep 60
		init 6
                ;;	
	"reboot-if-needed")
	        echo "Function not done yet" ; exit 1
		LAST_KERNEL=$(echo)
		CURRENT_KERNEL=$(echo)
		test $LAST_KERNEL = $CURRENT_KERNEL || init 6
		;;
	"check-if-reboot-req")
	        echo "Function not done yet" ; exit 1
		LAST_KERNEL=$(echo)
		CURRENT_KERNEL=$(echo)
		if [ $LAST_KERNEL != $CURRENT_KERNEL ]; then 
			echo "Reboot required"
		else
			echo "Already running on latest installed kernel"
		fi
		;;
	*)
		echo "Sorry. Only these commands are available to you:"
		echo "inventory patch available-updates patch-system patch-system-n-reboot"
		exit 1
		;;
esac
