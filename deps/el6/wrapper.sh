#!/bin/sh
# Script: /usr/share/sshupdated/wrapper.sh 
PATH=/bin:/sbin:/usr/bin:/usr/sbin
REPOMIRROR=http://ftp.sunet.se/pub/Linux/distributions/centos
UPGURL="http://dev.centos.org/centos/6/upg/x86_64/Packages"
OSUPGVER=7

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
  "upgrade-major")
    if [ -f /etc/centos-release ]; then
      if [ ! -d /root/upgrade ]; then
        mkdir -p /root/upgrade
      fi
      cd /root/upgrade
      which wget > /dev/null 2>&1
      if [ $? != 0 ]; then
        yum install wget -y --quiet
      fi
      for PKG in preupgrade-assistant-1.0.2-33.el6.x86_64.rpm preupgrade-assistant-contents-0.5.13-1.el6.noarch.rpm preupgrade-assistant-ui-1.0.2-33.el6.x86_64.rpm python-rhsm-1.9.7-1.el6.x86_64.rpm redhat-upgrade-tool-0.7.22-1.el6.noarch.rpm
      do
        wget -q ${UPGURL}/${PKG}
      done
      yum localinstall -y preupgrade-assistant-* --quiet
      if [ $? = 0 ]; then
        preupg --force > /dev/null 2>&1
      fi
      if [ $? = 0 ]; then
        yum localinstall -y redhat-upgrade-tool-0.7.22-1.el6.noarch.rpm python-rhsm-1.9.7-1.el6.x86_64.rpm --quiet
        rpm --import ${REPOMIRROR}/RPM-GPG-KEY-CentOS-${OSUPGVER}
        redhat-upgrade-tool --network ${OSUPGVER} --instrepo ${REPOMIRROR}/${OSUPGVER}/os/x86_64/ --force > /dev/null 2>&1
      fi
    else
      echo "This is supposed to do a major upgrade of your distribution release but we havnt tried it out on this platform yet."
    fi
  ;;
  "upgrade-major-n-reboot")
    if [ -f /etc/centos-release ]; then
      if [ ! -d /root/upgrade ]; then
        mkdir -p /root/upgrade
      fi
      cd /root/upgrade
      which wget  > /dev/null 2>&1
      if [ $? != 0 ]; then
        yum install wget -y --quiet
      fi
      for PKG in preupgrade-assistant-1.0.2-33.el6.x86_64.rpm preupgrade-assistant-contents-0.5.13-1.el6.noarch.rpm preupgrade-assistant-ui-1.0.2-33.el6.x86_64.rpm python-rhsm-1.9.7-1.el6.x86_64.rpm redhat-upgrade-tool-0.7.22-1.el6.noarch.rpm
      do
        wget -q ${UPGURL}/${PKG}
      done
      yum localinstall -y preupgrade-assistant-* --quiet
      if [ $? = 0 ]; then
        preupg --force > /dev/null 2>&1
      fi
      if [ $? = 0 ]; then
        yum localinstall -y redhat-upgrade-tool-0.7.22-1.el6.noarch.rpm python-rhsm-1.9.7-1.el6.x86_64.rpm --quiet
        rpm --import ${REPOMIRROR}/RPM-GPG-KEY-CentOS-${OSUPGVER}
        redhat-upgrade-tool --network ${OSUPGVER} --instrepo ${REPOMIRROR}/${OSUPGVER}/os/x86_64/ --force --reboot > /dev/null 2>&1
      fi
    else
      echo "This is supposed to do a major upgrade of your distribution release but we havnt tried it out on this platform yet."
    fi
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
    if [ "$(awk '$0 ~ /kernel \/vmlinuz-redhat-upgrade-tool/ { print $2 }' /boot/grub/menu.lst)" = "/vmlinuz-redhat-upgrade-tool" ]; then
      LAST_KERNEL="reboot"
    fi
		test $LAST_KERNEL = $CURRENT_KERNEL || init 6
  ;;
	"check-if-reboot-req")
		LAST_KERNEL=$(rpm -q --last kernel | sed 's/^kernel-\([a-z0-9._-]*\).*/\1/g' | head -1)
		CURRENT_KERNEL=$(uname -r)
    if [ "$(awk '$0 ~ /kernel \/vmlinuz-redhat-upgrade-tool/ { print $2 }' /boot/grub/menu.lst)" = "/vmlinuz-redhat-upgrade-tool" ]; then
      LAST_KERNEL="reboot"
    fi
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
