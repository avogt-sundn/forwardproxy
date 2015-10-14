#!/bin/bash
#


PROXY_SOCKET=172.17.42.1:3128
export https_proxy="https://${PROXY_SOCKET}"
export http_proxy="http://${PROXY_SOCKET}"

wget -O /dev/null --server-response https://www.google.de