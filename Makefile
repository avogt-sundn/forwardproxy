NAME=$(shell basename `pwd`)
NAMESPACE=$(shell cat NAMESPACE)
TAG=${NAMESPACE}/${NAME}
VERSION=$(shell cat VERSION)
GIT=$(shell git  log --oneline|head -n 1|awk '{print $$1;}')
RELEASE=${TAG}:${VERSION}-${GIT}


build: Dockerfile
	@docker-compose build

info:
	@echo "      TAG : ${TAG}"
	@echo "  VERSION : ${VERSION}"
	@echo "      GIT : ${GIT}"

release: build
	docker tag ${TAG}:latest ${RELEASE}
	@echo "Released:  ${RELEASE}"

run:
	docker-compose up -d

stop:
	docker-compose stop

rm: stop
	docker-compose rm ${NAME}

export: release
	docker save ${RELEASE} -o ${NAME}_${VERSION}-${GIT}.image
	gzip *.image

exec:
	docker exec -ti ${NAME}_${NAME}_1 /bin/ash
