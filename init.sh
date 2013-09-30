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
# Please remember, the server does not run a daemon, only the client does that
server_service_name="sshupdate"
client_service_name="sshupdated"

# Where should we build the RPM
RPM_ROOT=./RPM-ROOT

# Where do we find the deps-directory
deps=./deps

# Where is the pkgs directory found
pkgs=./pkgs

### Sanity is good
# Making sure we have a sane path
PATH=/sbin:/usr/sbin:/bin:/usr/bin

RPMBUILD=/usr/bin/rpmbuild

# Some variables needed for fancy output
COLS=$($TPUT cols)
COL=$(($COLS-8))
UP=$($TPUT cuu1)
START=$($TPUT hpa 0)
END=$($TPUT hpa $COL)
NORMAL=$($TPUT op)
GREEN=$($TPUT setaf 2)
RED=$($TPUT setaf 1)

### Functions
# To be used to print success on a previous command, like so: print_success $?
function print_success {
  if [ $1 -eq 0 ]
  then
    STATUS="${GREEN}ok"
  else
    STATUS="${RED}fail"
  fi
  if [ ! -z "$2" ]
  then
    REASON=$2
    /bin/echo -e " [ ${STATUS}${NORMAL} ]\n  Reason: $REASON"
  else
    /bin/echo -e " [ ${STATUS}${NORMAL} ]"
  fi
}

# Used in conjunction with print_success
function print_line {
  if [ -z "$1" ]
  then
    echo
  else
    echo -n $@
  fi
}

function f_create_sshd_config_el6 {
  DEST=$1
  [ -d "${DEST}" ] || mkdir -p ${DEST}
  [ -f "${deps}/el6/sshd_config" ] && sed -e "s/^Port.*/Port ${sshd_port}/g" -e "s/^AddressFamily.*/AddressFamily ${sshd_inet}/g" ${deps}/el6/sshd_config > ${DEST}/${client_service_name}.conf
}

function f_create_sshd_startscripts_el6 {
  RPM_ROOT=$1
  [ -d "${RPM_ROOT}/etc/rc.d/init.d" ] || mkdir -p ${RPM_ROOT}/etc/rc.d/init.d
  [ -f "${deps}/el6/startscript" ] && cp ${deps}/el6/startscript ${RPM_ROOT}/etc/rc.d/init.d/${client_service_name}
}

function f_populate_scripts {
  RPM_ROOT=$1
  # Make sure directory exists
  [ -d "${RPM_ROOT}/usr/share/${client_service_name}" ] || mkdir -p ${RPM_ROOT}/usr/share/${client_service_name}
  # Install wrapper.sh
  [ -f "${deps}/el6/wrapper.sh" ] && cp ${deps}/el6/wrapper.sh ${RPM_ROOT}/usr/share/${client_service_name}
  # Install sshupdate
  [ -f "${deps}/el6/sshupdate" ] && mkdir -p ${RPM_ROOT}/usr/sbin && cp ${deps}/el6/sshupdate ${RPM_ROOT}/usr/sbin/sshupdate
}

function f_create_sshd_authkeys_el6 {
  DEST=$1
  mkdir -p ${DEST}/root/.ssh/
  [ -f "${DEST}/root/.ssh/${client_service_name}_keys" ] && rm ${DEST}/root/.ssh/${client_service_name}_keys
  for key in $keys; do
    tmpkey=`cat keys/${key}.pub`
    echo "command=\"/usr/share/${client_service_name}/wrapper.sh\",no-port-forwarding,no-X11-forwarding,no-pty ${tmpkey}" >> ${DEST}/root/.ssh/${client_service_name}_keys
  done
}

function f_build_server_rpm_el6  {
  mkdir -p ~/rpmbuild/server/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
  echo '%_topdir %(echo ${HOME})/rpmbuild/server' > ~/.rpmmacros
  mkdir -p tmp/${server_service_name}-${version}
  cd ${RPM_ROOT}
  cp -r * ../tmp/${server_service_name}-${version}
  cd ../tmp 
  tar zcf ~/rpmbuild/server/SOURCES/${server_service_name}-${version}.tar.gz . 
  print_line "Building RPM based on scripts:"
  if [ ! -f $RPMBUILD ]; then
	echo "No rpmbuild installed. exiting. ($RPMBUILD)"
	echo "try yum install rpm-build"
	exit 1
  fi
  rpmbuild -bb ../specfiles/el6/${server_service_name}.specfile > /dev/null 2>&1
  print_success $?
  echo -e "\nServer RPM available in: /root/rpmbuild/server/RPMS/noarch/${server_service_name}-${version}-1.noarch.rpm"
}

function f_build_client_rpm_el6  {
  mkdir -p ~/rpmbuild/client/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
  echo '%_topdir %(echo ${HOME})/rpmbuild/client' > ~/.rpmmacros
  mkdir -p tmp/${client_service_name}-${version}
  cd ${RPM_ROOT}
  cp -r * ../tmp/${client_service_name}-${version}
  cd ../tmp 
  tar zcf ~/rpmbuild/client/SOURCES/${client_service_name}-${version}.tar.gz . 
  print_line "Building RPM based on scripts:"
  if [ ! -f $RPMBUILD ]; then
	echo "No rpmbuild installed. exiting. ($RPMBUILD)"
	echo "try yum install rpm-build"
	exit 1
  fi
  rpmbuild -bb ../specfiles/el6/${client_service_name}.specfile > /dev/null 2>&1
  print_success $?
  echo -e "\nClient RPM available in: /root/rpmbuild/client/RPMS/noarch/${client_service_name}-${version}-1.noarch.rpm"
}

function f_create_el6_client_rpm {
  f_build_server_rpm_el6 ${pkgs}/${client_service_name}-el6/${client_service_name}.spec
}

function f_create_el6_client_rpm {
  f_create_sshd_config_el6 ${RPM_ROOT}/etc/ssh
  f_create_sshd_startscripts_el6 ${RPM_ROOT}
  f_populate_scripts ${RPM_ROOT}
  f_create_sshd_authkeys_el6 ${RPM_ROOT}
  f_build_client_rpm_el6 ${pkgs}/${client_service_name}-el6/${client_service_name}.spec
}

function f_genkeys {
  print_line "Generating keys"
  for key in $keys; do
    if [ ! -f keys/$key ]; then
      umask 077
      mkdir -p ./keys	
      ssh-keygen -t $keytype -b ${keysize} -f keys/${key}
      print_success $?
    else
      print_success $? "${client_service_name}-key already exist (keys/${key})"
    fi
  done
}

function f_help {
PROG=$(basename $0)
  cat << EOF
$PROG options:
	$PROG gen-keys - Generate ssh-keys
	$PROG build-rpm - Create rpm's
	$PROG build-client-rpm - Create client rpm
	$PROG build-server-rpm - Create server rpm
	$PROG clean - Clean failed build
	$PROG init - Run gen-keys, then build-rpm

Note: $PROG uses relative paths.
EOF
}



### Main
case "$1" in 
  gen-keys)
    f_genkeys
  ;;
  build-rpm)
    f_create_el6_client_rpm
    f_create_el6_server_rpm
  ;;
  build-rpm)
    f_create_el6_client_rpm
  ;;
  build-server-rpm)
    f_create_el6_server_rpm
  ;;
  clean)
    rm -rf /var/tmp/${client_service_name}-root/
  ;;
  init)
    f_genkeys
    f_create_el6_client_rpm
    f_create_el6_server_rpm
  ;;
  *)
    f_help
  ;;
esac
