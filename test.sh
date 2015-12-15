#!/bin/bash
#


PROXY_SOCKET=localhost:3128
export https_proxy="https://${PROXY_SOCKET}"
export http_proxy="http://${PROXY_SOCKET}"

wget -O /dev/null --server-response http://www.heise.de
wget -O /dev/null --server-response https://www.google.de