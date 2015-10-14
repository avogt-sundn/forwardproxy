FROM alpine:3.2
MAINTAINER Armin Vogt avogt@s-und-n.de

# http://wiki.alpinelinux.org/wiki/Setting_up_Transparent_Squid_Proxy
#

RUN set -x && export http_proxy="http://172.17.42.1:3128"  \
 && mkdir -p /srv/openldap.d /etc/openldap/sasl2 \
 && apk add --update curl gettext acf-squid bash gnutls-utils

ENV SQUID_VERSION=3.3.8 \
    SQUID_CACHE_DIR=/var/spool/squid \
    SQUID_LOG_DIR=/var/log/squid \
    SQUID_USER=squid \
	CA_CERT_PASSWORD=toor \
	CA_DOMAIN=s-und-n.de


COPY squid.conf /etc/squid/squid.conf
COPY createCA.sh /
ENV proxy_pass=
ENV proxy_user=
ENV parent_proxy=10.10.1.102
ENV https_parent_proxy=
ENV parent_port=80


COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

VOLUME ["/out"]
EXPOSE 3128
ENTRYPOINT ["/sbin/entrypoint.sh"]

