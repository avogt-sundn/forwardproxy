NAME=$(shell basename `pwd`)
VERSION=latest

TAG=devhub/${NAME}:${VERSION}

REGISTRY=10.10.3.72:5000
PORTS= -p 3128:3128
LINKS= 
START_ARGS= --restart=always -e SERVICE_NAME='forwardproxy'
VOLUMES= --volumes-from  data-${NAME}
VOLUME_LIST= -v /var/spool/squid -v /var/log/squid 
HTTP_PROXY=

#"http://172.17.42.1:3128"

pwd=`pwd`
all: help

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""	
	@echo "   1. make build        - build the ${name} image"
	@echo "   2. make start        - run ${name}"
	@echo "   3. make stop         - stop ${name}"
	@echo "   4. make logs         - view logs"
	@echo "   5. make purge        - stop and remove the container"
	@echo "   add arguments to the entrypoint.sh with RUN_ARGS=""

build:
	@echo "building ${TAG}"
	
	@docker build --tag=${TAG} .
	@echo "Created image ${TAG}"

restart:	stop	start


console:	purge
	@echo "starting container ${TAG}"
	@docker run -i -t --name ${NAME} ${LINKS} ${PORTS} ${VOLUMES} ${PARAMS} ${TAG} bash
	@echo "Type 'make logs' for the logs"


start:	purge
	@echo "starting container ${TAG} under name ${NAME}"	
	@echo docker run -e parent_proxy=${HTTP_PROXY} --name ${NAME} ${LINKS} ${PORTS} ${VOLUMES} -t -d ${START_ARGS} ${TAG} ${RUN_ARGS}
	@docker run -e parent_proxy=${HTTP_PROXY} --name ${NAME} ${LINKS} ${PORTS} ${VOLUMES} -t -d ${START_ARGS} ${TAG} ${RUN_ARGS}
	@echo "Type 'make logs' for the logs"

create-certs:
	@echo  docker run --rm -e http_proxy=${HTTP_PROXY} ${LINKS} ${VOLUMES} -v $(pwd):/out -ti   ${TAG} create-certs
	@docker run --rm -e http_proxy=${HTTP_PROXY} ${LINKS} ${VOLUMES} -v $(pwd):/out -ti   ${TAG} create-certs
	
ps:
	@docker ps|grep ${NAME}

exec:
	@echo "Entering console for ${NAME}.."
	@docker exec -ti ${NAME} sh

stop:
	@echo "Stopping container ${name} ${TAG}..."
	- docker stop ${NAME}  

purge: stop
	@echo "removing container"
	- docker rm ${NAME}  >/dev/null

remove-data:
	- docker rm data-${NAME}  >/dev/null

create: 
	@echo "Creating volume container"
	@docker create ${VOLUME_LIST} --name data-${NAME} ${TAG} /bin/true

new: remove-data create
	@echo "NEW data volume"
	
tar-data: 	
	@docker run --rm ${VOLUMES}  busybox find /var/spool/squid

push: build
	@echo "Pushing to registry"
	@docker tag ${TAG} ${REGISTRY}/${TAG}
	@docker push ${REGISTRY}/${TAG}

logs:
	@docker logs -f ${NAME} 

save:
	@echo "exporting image  ${TAG} to file ${NAME}.img"
	@(mkdir -p /tmp/${NAME} && cp Makefile /tmp/${NAME} && cd /tmp/${NAME} &&  docker save -o ${NAME}.img  ${TAG} && bzip2 -f ${NAME}.img && cd ..&& tar cvf ${NAME}-${VERSION}.tar  ${NAME} )
	@mv /tmp/${NAME}-${VERSION}.tar .

load: 
	@echo "loading image  ${TAG} to docker"
	bunzip2 ${NAME}.img.bz2 &&  docker load -i ${NAME}.img &&  docker images|grep ${NAME}
