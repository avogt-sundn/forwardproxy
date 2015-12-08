#!/bin/sh
# arguments come from the commandline (when using the makefile: make RUN_ARGS="1 2 3" comes as $1,$2,$3 vars)
#
echo "called with arguments:" \"$1\"  \"$2\" \"$3\"
set -e


set |grep SQUID
find /etc/squid*
echo "squid bin: $(which squid)"


envsubstitution() {
  export proxy_pass
  export proxy_user
  export parent_proxy
  export disk_cache_mb
  
  if [[ -z "$proxy_user" ]]; then
	echo "removing login from squid conf since ENV proxy_user is empty"
	sed -i s/.login=.*//g /etc/squid/squid.conf
  fi
  if [[ -z "$parent_proxy" ]]; then
	echo "removing parent squid from squid conf since ENV parent_proxy is empty"
	sed -i /cache_peer/d 	/etc/squid/squid.conf
	sed -i /never_direct/d 	/etc/squid/squid.conf
  fi
  
  cat /etc/squid/squid.conf | envsubst > tmp_squid.conf && mv tmp_squid.conf /etc/squid/squid.conf 
  echo "Disk cache (-e disk_cache_mb=<mb>) to be used is set to: "$disk_cache_mb" megabytes"
  cat /etc/squid/squid.conf
}

create_log_dir() {
  mkdir -p ${SQUID_LOG_DIR}
  chmod -R 755 ${SQUID_LOG_DIR}
  chown -R ${SQUID_USER}:${SQUID_USER} ${SQUID_LOG_DIR}
}

create_cache_dir() {
  mkdir -p ${SQUID_CACHE_DIR}
  chown -R ${SQUID_USER}:${SQUID_USER} ${SQUID_CACHE_DIR}
}

create_log_dir
create_cache_dir
envsubstitution

# default behaviour is to launch squid
if [[ -z ${1} ]]; then
  if [[ ! -d ${SQUID_CACHE_DIR}/00 ]]; then
    echo "Initializing cache..."
    $(which squid) -N -f /etc/squid/squid.conf -z
  fi
  echo "Starting squid3..."
  exec $(which squid) -f /etc/squid/squid.conf -NYCd 1 ${EXTRA_ARGS}
else
  exec "$@"
fi
