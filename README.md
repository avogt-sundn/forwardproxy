

# Reverse Proxy #
--------------

This image runs a squid serving as a forward proxy. It can be used

-  **transparently**: only for http urls! and you need to add the routing.
-  **non-transparently**: 
	-  means: your client must be configured to use this proxy.
		-  in a browser, change the networking settings and enter proxy for http and if you want https
		-  for linux commands using the *http(s)_proxy* environment variables  
 
### It's small
It is based on alpine linux which gives you a super small image size of about 26mb only.
 
--------------

## Starting (with makefile)##
Start with the right environment variables set to define **the parent proxy**. the parent proxy is usually your corporate proxy. Proxy user and password can be given also:

    $ make create
    $ make start START_ARGS="-e parent_proxy=astaro.it.gefa.de -e parent_port=8080 -e proxy_user=GEFA0150 -e proxy_pass=xxxx"
    
If you want to purge the data collected (cached), remove the data volume container with

	$ make remove-data create

Here are all arguments available 

variable | default | description
---------|---------|----------
parent_proxy | 10.10.1.102|the hostname or ip to the proxy that is next (corporate proxy) 
parent_port  | 80 | the port where the parent proxy listens
proxy_user   | <empty> | if your parent proxy needs authentication, put the username here
proxy_pass=  | <empty | .. and your user's password here


## Starting (with docker run)##

	$ docker create  -v /var/spool/squid -v /var/log/squid  data-reverse-proxy devhub/reverse-proxy /bin/true 

    $ docker run -d -p 3128:3128 --name squid  --volumes-from  data-reverse-proxy devhub/reverse-proxy -e parent_proxy=astaro.it.gefa.de -e parent_port=8080 -e proxy_user=GEFA0150 -e proxy_pass=xxxx"


## Starting (with makefile)##

# Using the proxy on other docker containers and during build

You simply have to configure the **http_proxy** variable:

	export http_proxy=http://172.17.42.1:3128  

# Test it! #
Make a test on the docker host line (outside of the docker containers)

	$ (export http_proxy=http://172.17.42.1:3128 && curl http://www.heise.de)

Then enter any container and do it again from the inside:

## SSL ##
SSL proxy is *non-transparent*.

It can proxy SSL/TLS/https urls but only when the client has a https proxy configured! this 

	$ (export https_proxy=http://172.17.42.1:3128 && curl http://www.google.de)

# Transparent proxying #

Read this: 

[http://wiki.squid-cache.org/ConfigExamples/Intercept/SslBumpExplicit](http://wiki.squid-cache.org/ConfigExamples/Intercept/SslBumpExplicit)

# Further reading #
[http://wiki.alpinelinux.org/wiki/Setting_up_Explicit_Squid_Proxy](http://wiki.alpinelinux.org/wiki/Setting_up_Explicit_Squid_Proxy)
