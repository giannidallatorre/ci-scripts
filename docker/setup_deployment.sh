#!/bin/bash
set -x

MODE="${MODE:-clean}"
PLATFORM="${PLATFORM:-SL6}"

mkdir -p $PWD/docker_storm/storage

# run StoRM deployment
docker run -d -e "MODE=${MODE}" -e "PLATFORM=${PLATFORM}" -h docker-storm.cnaf.infn.it -v $PWD/docker_storm/storage:/storage:rw -v /etc/localtime:/etc/localtime:ro --name storm-deploy centos6/storm-deploy:1.0 docker run -d -e "MODE=clean" -e "PLATFORM=SL6" -h docker-storm.cnaf.infn.it -t -i  -v ~/docker_storm/storage:/storage:rw -v /etc/localtime:/etc/localtime:ro --name storm-deploy centos6/storm-deploy:1.0 /bin/sh deploy.sh

# run StoRM testsuite when deployment is over
docker run --link storm-deploy:docker-storm.cnaf.infn.it --volumes-from storm-deploy -v /etc/localtime:/etc/localtime:ro --name storm-ts centos6/storm-ts:1.0

# copy StoRM logs 
docker cp storm-deploy:/var/log/storm .

# remove containers
docker rm -f storm-deploy
docker rm -f storm-ts