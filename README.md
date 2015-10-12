
----------
# Reverse Proxy #
## Starting ##

Start with the right environment variables set to define **the parent proxy**. the parent proxy is usually your corporate proxy. Proxy user and password can be given also:

    make start START_ARGS="-e parent_proxy=astaro.it.gefa.de parent_port=8080 proxy_user=GEFA0150 proxy_pass=xxxx"


