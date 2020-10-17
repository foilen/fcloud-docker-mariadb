#!/bin/bash

set -e

export VERSION=test

RUN_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $RUN_PATH

echo ----[ Create test image ]----
./create-local-release.sh $VERSION

echo ----[ Create temporary data ]----
mkdir -p _data/volumes/config _data/mysql
if [ ! -f _data/newPass ]; then
	echo Create initial root password: ABC
	echo -n ABC > _data/newPass

	echo "[client]" > _data/newPass.cnf
	echo "password=ABC" >> _data/newPass.cnf
fi

echo ----[ Stop previous and prepare ]----
DOCKER_INSTANCE_NAME=fcloud-docker-mariadb-test

set +e
docker stop $DOCKER_INSTANCE_NAME
docker logs $DOCKER_INSTANCE_NAME > _data/log-$(date +%Y-%m-%d-%H-%M-%S)-out.txt
docker logs $DOCKER_INSTANCE_NAME 2> _data/log-$(date +%Y-%m-%d-%H-%M-%S)-err.txt
docker rm $DOCKER_INSTANCE_NAME

set -e
docker create --name $DOCKER_INSTANCE_NAME fcloud-docker-mariadb:test
docker cp _data/newPass $DOCKER_INSTANCE_NAME:/newPass
docker cp _data/newPass.cnf $DOCKER_INSTANCE_NAME:/newPass.cnf
docker commit $DOCKER_INSTANCE_NAME fcloud-docker-mariadb:test2
docker rm $DOCKER_INSTANCE_NAME

echo ----[ Execute ]----
docker run --detach \
 --name $DOCKER_INSTANCE_NAME \
 --volume $PWD/_data/volumes:/volumes \
 --volume $PWD/_data/mysql:/var/lib/mysql \
 --user $(id -u) \
 fcloud-docker-mariadb:test2 \
 /mariadb-start.sh

echo ----[ Logs ]----
docker logs -f $DOCKER_INSTANCE_NAME
