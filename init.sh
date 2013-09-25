#!/bin/bash
# Description:
# This script will setup your server with sshupdated. It offers you a way to create required package to spread to your clients in the same time.
# It generates the SSH-keys used in the different scripts.

### Variables
version=0.1

# ? What is this used for? Or well, intended to be used for
keys="sshupdated" 

# Which type of SSH-key do we want to use
keytype="rsa"

# What size should the key be
keysize=4096

# Which port do we want to run the server on
sshd_port=2222

# Where should we listen? Default: any ( any / inet6 )
sshd_inet="any"

# What do we call the service
sshd_name="sshupdated"

# Where should we build the RPM
RPM_ROOT=./RPM-ROOT

# Where do we find the deps-directory
deps=./deps

# Where is the pkgs directory found
pkgs=./pkgs

### Sanity is good
# Making sure we have a sane path
PATH=/sbin:/usr/sbin:/bin:/usr/bin

### Functions
function f_create_sshd_config_el6 {
	DEST=$1
        [ -d "${DEST}" ] || mkdir -p ${DEST}
        [ -f "${deps}/el6/sshd_config" ] && sed -e "s/^Port.*/Port ${sshd_port}/g" -e "s/^AddressFamily.*/AddressFamily ${sshd_inet}/g" ${deps}/el6/sshd_config > ${DEST}/${sshd_name}.conf
}

function f_create_sshd_startscripts_el6 {
	RPM_ROOT=$1
	[ -d "${RPM_ROOT}/etc/rc.d/init.d" ] || mkdir -p ${RPM_ROOT}/etc/rc.d/init.d
	[ -f "${deps}/el6/startscript" ] && cp ${deps}/el6/startscript ${RPM_ROOT}/etc/rc.d/init.d/${sshd_name}
}

function f_populate_scripts {
	RPM_ROOT=$1
	[ -d "${RPM_ROOT}/usr/share/${sshd_name}" ] || mkdir -p ${RPM_ROOT}/usr/share/${sshd_name}
	[ -f "${deps}/el6/wrapper.sh" ] && cp ${deps}/el6/wrapper.sh ${RPM_ROOT}/usr/share/${sshd_name}
}

function f_create_sshd_authkeys_el6 {
	DEST=$1
	mkdir -p ${DEST}/root/.ssh/
	[ -f "${DEST}/root/.ssh/${sshd_name}_keys" ] && rm ${DEST}/root/.ssh/${sshd_name}_keys
	for key in $keys; do
		tmpkey=`cat keys/${key}.pub`
		echo "command=\"/usr/share/${sshd_name}/${key}\",no-port-forwarding,no-X11-forwarding,no-pty ${tmpkey}" >> ${DEST}/root/.ssh/${sshd_name}_keys
	done
}

function f_build_rpm_el6  {
	mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
	echo '%_topdir %(echo ${HOME})/rpmbuild' > ~/.rpmmacros
	mkdir -p tmp/${sshd_name}-${version}
	cd ${RPM_ROOT}
	cp -r * ../tmp/${sshd_name}-${version}
	cd ../tmp 
	tar zcvf ~/rpmbuild/SOURCES/${sshd_name}-${version}.tar.gz . 
	rpmbuild -bb ../specfiles/el6/${sshd_name}.specfile
}

function f_create_el6_client_rpm {
	f_create_sshd_config_el6 ${RPM_ROOT}/etc/ssh
	f_create_sshd_startscripts_el6 ${RPM_ROOT}
	f_populate_scripts ${RPM_ROOT}
	f_create_sshd_authkeys_el6 ${RPM_ROOT}
	f_build_rpm_el6 ${pkgs}/${sshd_name}-el6/${sshd_name}.spec
}

function f_genkeys {
for key in $keys; do
	if [ ! -f keys/$key ]; then
		umask 077
		mkdir -p ./keys	
		ssh-keygen -t $keytype -b ${keysize} -f keys/${key}
	else
		echo "${sshd_name}-key already exist (keys/${key})"
	fi
done
}

#main
function f_help {
cat << EOF
$0 options:
	$0 gen-keys - Generate ssh-keys
	$0 build-rpm - Create client rpm
	$0 clean - Clean failed build
	$0 init - Run gen-keys, then build-rpm

Note: $0 uses relative paths.

EOF
}




case "$1" in 
	gen-keys)
		f_genkeys
	;;
	build-rpm)
		f_create_el6_client_rpm
	;;
	clean)
		rm -rf /var/tmp/${sshd_name}-root/
	;;
	init)
		f_genkeys
		f_create_el6_client_rpm
	;;
	*)
	f_help
	;;
esac
