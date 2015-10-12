FROM alpine:3.2
MAINTAINER avogt

# http://wiki.alpinelinux.org/wiki/Setting_up_Transparent_Squid_Proxy
#

RUN set -x && export http_proxy="http://10.10.1.102:80" \
 && mkdir -p /srv/openldap.d /etc/openldap/sasl2 \
 && apk add --update \
        gettext acf-squid bash

ENV SQUID_VERSION=3.3.8 \
    SQUID_CACHE_DIR=/var/spool/squid \
    SQUID_LOG_DIR=/var/log/squid \
    SQUID_USER=squid


COPY squid.conf /etc/squid/squid.conf
ENV proxy_pass=
ENV proxy_user=
ENV corporate_proxy=10.10.1.102


COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 3128/tcp
VOLUME ["${SQUID_CACHE_DIR}"]
ENTRYPOINT ["/sbin/entrypoint.sh"]

