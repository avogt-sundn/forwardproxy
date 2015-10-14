10/14/2015 5:56:14 PM 

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

### Why?
 
1.  This proxy comes as an advantage to those confined behind corporate firewalls that demand credentials. You can enter your credentials when starting the proxy. Then continue using this proxy without credentials.

		notice that all your requests still get logged on the corporate proxy!
2.  This proxy also can be used especially in virtualized lab environments where the docker host changes. Simply reference the **docker bridge ip** *172.17.42.1* from within your containers/dockerfiles:

	  	RUN set -x && export http_proxy="http://172.17.42.1:3128"  \		 
 			 && apk add --update curl gettext acf-squid bash gnutls-utils
 
3.   

## Building with a fixed proxy address
This proxy is not transparent, you still need to configure each client to use it explicitly. **BUT** its address can be fixed to http://172.17.42.1:3128.

Why? Because this is the default docker bridge ip, and unless you start your docker daemon with *--bip* or other options that change this default ip, you can consider this being never changing between environments. 

### Alpine

	ENV http_proxy="http://172.17.42.1:3128"	
	RUN apk add --update curl gettext   

or
	
	RUN (http_proxy="http://172.17.42.1:3128" apk add --update curl gettext)

### Ubuntu

	ENV http_proxy="http://172.17.42.1:3128"	
	RUN apt-get update && \
		apt-get -y install --no-install-recommends software-properties-common python-software-properties



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


## Check what gets cached: squid access.log ##

	$ make exec
	$ sudo docker exec -ti ..

	$ tail -f /var/log/squid/access.log

## Use as linux package cache?

You can use the proxy as package cache. Just size the persistent cache big enough (full ubuntu takes 100 MB) or trust the cache eviction of Squid.

I tested it for Ubuntu and for Alpine packages.

## Cache settings

Change in the squid.conf and rebuild the docker image.
Or do it on a running container with docker exec.

## Troubleshooting
 
It is **not** sufficient to set the http_proxy variable on your docker host and then start the docker build! docker build command never accepts any environment variables from the host. (if it does it would make the build become environment-dependent!)

# Transparent proxying #

Read this: 

[http://wiki.squid-cache.org/ConfigExamples/Intercept/SslBumpExplicit](http://wiki.squid-cache.org/ConfigExamples/Intercept/SslBumpExplicit)

# Further reading #
[http://wiki.alpinelinux.org/wiki/Setting_up_Explicit_Squid_Proxy](http://wiki.alpinelinux.org/wiki/Setting_up_Explicit_Squid_Proxy)
