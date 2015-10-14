NAME=$(shell basename `pwd`)
VERSION=latest

TAG=devhub/${NAME}:${VERSION}

REGISTRY=10.10.3.72:5000
PORTS= -p 3128:3128
LINKS= 
VOLUMES= --volumes-from  data-${NAME}
VOLUME_LIST= -v /var/spool/squid -v /var/log/squid 
HTTP_PROXY="http://172.17.42.1:3128"

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
	
	@sudo docker build --tag=${TAG} .
	@echo "Created image ${TAG}"

restart:	stop	start


console:	purge
	@echo "starting container ${TAG}"
	@sudo docker run -i -t --name ${NAME} ${LINKS} ${PORTS} ${VOLUMES} ${PARAMS} ${TAG} bash
	@echo "Type 'make logs' for the logs"


start:	purge
	@echo "starting container ${TAG} under name ${NAME}"	
	@echo docker run -e http_proxy=${HTTP_PROXY} --name ${NAME} ${LINKS} ${PORTS} ${VOLUMES} -t -d ${START_ARGS} ${TAG} ${RUN_ARGS}
	@sudo docker run -e http_proxy=${HTTP_PROXY} --name ${NAME} ${LINKS} ${PORTS} ${VOLUMES} -t -d ${START_ARGS} ${TAG} ${RUN_ARGS}
	@echo "Type 'make logs' for the logs"

create-certs:
	@echo sudo docker run --rm -e http_proxy=${HTTP_PROXY} ${LINKS} ${VOLUMES} -v $(pwd):/out -ti   ${TAG} create-certs
	@sudo docker run --rm -e http_proxy=${HTTP_PROXY} ${LINKS} ${VOLUMES} -v $(pwd):/out -ti   ${TAG} create-certs
	
ps:
	@sudo docker ps|grep ${NAME}

exec:
	@echo "Entering console for ${NAME}.."
	@sudo docker exec -ti ${NAME} sh

stop:
	@echo "Stopping container ${name} ${TAG}..."
	-sudo docker stop ${NAME}  

purge: stop
	@echo "removing container"
	-sudo docker rm ${NAME}  >/dev/null

remove-data:
	@sudo docker rm data-${NAME}  >/dev/null

create: 
	@echo "Creating volume container"
	@sudo docker create ${VOLUME_LIST} --name data-${NAME} busybox /bin/true

new: remove-data create
	@echo "NEW data volume"
	
tar-data: 	
	@sudo docker run --rm ${VOLUMES}  busybox find /var/spool/squid

push: build
	@echo "Pushing to registry"
	@sudo docker tag ${TAG} ${REGISTRY}/${TAG}
	@sudo docker push ${REGISTRY}/${TAG}

logs:
	@sudo docker logs -f ${NAME} 

save:
	@echo "exporting image  ${TAG} to file ${NAME}.img"
	@(mkdir -p /tmp/${NAME} && cp Makefile /tmp/${NAME} && cd /tmp/${NAME} && sudo docker save -o ${NAME}.img  ${TAG} && bzip2 -f ${NAME}.img && cd ..&& tar cvf ${NAME}-${VERSION}.tar  ${NAME} )
	@mv /tmp/${NAME}-${VERSION}.tar .

load: 
	@echo "loading image  ${TAG} to docker"
	bunzip2 ${NAME}.img.bz2 && sudo docker load -i ${NAME}.img && sudo docker images|grep ${NAME}
