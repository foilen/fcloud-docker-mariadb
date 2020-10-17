#!/bin/bash

export VERSION=test

RUN_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $RUN_PATH

echo ----[ Stop and remove docker container ]----
docker rm -f fcloud-docker-mariadb-test

echo ----[ Delete temporary data ]----
rm -rfv _data
