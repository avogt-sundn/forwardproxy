#!/bin/bash
# arguments come from the commandline (when using the makefile: make RUN_ARGS="1 2 3" comes as $1,$2,$3 vars)
#
echo "called with arguments:" \"$1\"  \"$2\" \"$3\"
set -e


set |grep SQUID
find /etc/squid*
echo "squid bin: $(which squid)"
echo "ssl_crtd bin: $(which ssl_crtd)"
export myCA_pem=/myCA.pem

#########################################################################################################
setup_gnutls() {
	cat > cert.cfg <<EOF 
# X.509 Certificate options
#
# DN options

# The organization of the subject.
organization = "S&N AG"

# The organizational unit of the subject.
unit = "Docker Works"

# The locality of the subject.
locality = "OWL"

# The state of the certificate owner.
state = "NRW"

# The country of the subject. Two letter code.
country = DE

# The common name of the certificate owner.
cn = "Armin Vogt"

# A user id of the certificate owner.
uid = "avogt"
# The serial number of the certificate
# Comment the field for a time-based serial number.
serial = 007001

# In how many days, counting from today, this certificate will expire.
# Use -1 if there is no expiration date.
expiration_days = 700

# An email in case of a person
email = "avogt@s-und-n.de"

# Challenge password used in certificate requests
challenge_password = 123456
# Path length contraint. Sets the maximum number of
# certificates that can be used to certify this certificate.
# (i.e. the certificate chain length)
#path_len = -1
path_len = 2

# An URL that has CRLs (certificate revocation lists)
# available. Needed in CA certificates.
crl_dist_points = "http://www.getcrl.crl/getcrl/"
# Whether this is a CA certificate or not
ca 

# Whether this key will be used to sign other certificates. The
# keyCertSign flag in RFC5280 terminology.
cert_signing_key

# Whether this key will be used to sign CRLs. The
# cRLSign flag in RFC5280 terminology.
crl_signing_key

EOF
}

create_certs() {
	certtool --generate-privkey --outfile ca-key.pem
	certtool --generate-self-signed --load-privkey ca-key.pem --outfile $myCA_pem --template cert.cfg
	
	FILE="myCA.der"
	openssl x509 -in myCA.pem -outform DER -out /out/$FILE
	echo "wrote $FILE to /out"
}


envsubstitution() {
  export proxy_pass
  export proxy_user
  export corporate_proxy
  if [[ -z "$proxy_user" ]]; then
	echo "removing login from squid conf since ENV proxy_user is empty"
	sed -i s/.login=.*//g /etc/squid/squid.conf
  fi
  cat /etc/squid/squid.conf | envsubst > tmp_squid.conf && mv tmp_squid.conf /etc/squid/squid.conf 
  echo "--------setup squid.conf:"
  cat /etc/squid/squid.conf
  echo "--------end of squid.conf"
}
create_ssl_cache() {
	mkdir -p /var/lib/ssl_db
	$(which ssl_crtd) -c -s /var/lib/ssl_db
	chown squid:squid -R /var/lib/ssl_db
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

# allow arguments to be passed to squid3
if [[ ${1} == "create-certs" || ${2} == "create-certs" ]]; then
	echo "you asked me to create a new CA. Complying.."
	EXTRA_ARGS="${@:2}"
	set --
	setup_gnutls
	create_certs
	exec "bash"
fi

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
