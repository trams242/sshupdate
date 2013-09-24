#!/bin/bash
# generate ssh keys for different scripts.
version=0.1
keys="patchssh" 
keytype="rsa"
keysize=4096
sshd_port=2222
#can be any, inet or inet6
sshd_inet="any"
sshd_name="patchssh"
RPM_ROOT=./RPM-ROOT
deps=./deps
pkgs=./pkgs

function f_create_sshd_config_el6 {
	DEST=$1
	mkdir -p $DEST
	cat $deps/el6/sshd_config | sed -e "s/^Port.*/Port $sshd_port/g" -e "s/^AddressFamily.*/AddressFamily $sshd_inet/g" > $DEST/${sshd_name}.conf
}

function f_create_sshd_startscripts_el6 {
	RPM_ROOT=$1
	mkdir -p $RPM_ROOT/etc/rc.d/init.d
	cp $deps/el6/startscript $RPM_ROOT/etc/rc.d/init.d/$sshd_name
}

function f_populate_scripts {
	RPM_ROOT=$1
	mkdir -p $RPM_ROOT/usr/share/$sshd_name
	cp $deps/el6/wrapper.sh $RPM_ROOT/usr/share/$sshd_name
}

function f_create_sshd_authkeys_el6 {
	#fix the sshd auth keys
	DEST=$1
	mkdir -p $DEST/root/.ssh/
	if [ -f $DEST/root/.ssh/patch_keys ]; then
		rm $DEST/root/.ssh/patch_keys
	fi
	for key in $keys; do
		tmpkey=`cat keys/$key.pub`
		echo "command=\"/usr/share/PatcSSH/$key\",no-port-forwarding,no-X11-forwarding,no-pty $tmpkey" >> $DEST/root/.ssh/patch_keys
	done
}

function f_build_rpm_el6  {
	mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
	echo '%_topdir %(echo $HOME)/rpmbuild' > ~/.rpmmacros
	mkdir -p tmp/$sshd_name-$version
	cd $RPM_ROOT
	cp -r * ../tmp/$sshd_name-$version
	cd ../tmp 
	tar zcvf ~/rpmbuild/SOURCES/$sshd_name-$version.tar.gz . 
	rpmbuild -bb ../specfiles/el6/PatchSSH.specfile
}

function f_create_el6_client_rpm {
	f_create_sshd_config_el6 $RPM_ROOT/etc/ssh
	f_create_sshd_startscripts_el6 $RPM_ROOT
	f_populate_scripts $RPM_ROOT
	f_create_sshd_authkeys_el6 $RPM_ROOT
	f_build_rpm_el6 $pkgs/${sshd_name}-el6/${sshd_name}.spec
}

function f_genkeys {
for key in $keys; do
	if [ ! -f keys/$key ]; then
		umask 077
		mkdir -p ./keys	
		ssh-keygen -t $keytype -b $keysize -f keys/$key
	else
		echo "Patchkey already exist (keys/$key"
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
		echo "srry, not implemented yes."
	;;
	init)
		f_genkeys
		f_create_el6_client_rpm
	;;
	*)
	f_help
	;;
esac
