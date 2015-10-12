NAME=$(shell basename `pwd`)
VERSION=latest

TAG=devhub/${NAME}:${VERSION}


REGISTRY=10.10.3.72:5000

PORTS= -p 3128:3128
LINKS= 
VOLUMES= --volumes-from  data-${NAME}
VOLUME_LIST= -v /var/spool/squid -v /var/log/squid 
HTTP_PROXY="http://10.10.1.102:80"
START_ARGS=-e 'LDAP_DOMAIN=devhub.my' -e "LDAP_PASSWORD=toor"

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
	@sudo docker run -e http_proxy=${HTTP_PROXY} --name ${NAME} ${LINKS} ${PORTS} ${VOLUMES}  ${START_ARGS} -t -d  ${TAG} 
	@echo "Type 'make logs' for the logs"

	
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
	@sudo docker run --rm ${VOLUMES}  busybox find /var/

push: build
	@echo "Pushing to registry"
	@sudo docker tag ${TAG} ${REGISTRY}/${TAG}
	@sudo docker push ${REGISTRY}/${TAG}

logs:
	@sudo docker logs -f ${NAME} 

save:
	@echo "exporting image  ${TAG} to file ${NAME}.img"
	@sudo docker save -o ${NAME}.img  ${TAG} && bzip2 ${NAME}.img 
