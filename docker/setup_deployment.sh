#!/bin/bash
set -x

MODE="${MODE:-clean}"
PLATFORM="${PLATFORM:-SL6}"

git clone https://github.com/dandreotti/docker-scripts.git
cd storm-deployment-test

mkdir -p ~/docker_storm/storage
mkdir -p ~/docker_storm/logs

docker run -e "MODE=${MODE}" -e "PLATFORM=${PLATFORM}" -h docker-storm.cnaf.infn.it -d -v ~/docker_storm/storage:/storage:rw -v ~/docker_storm/logs:/var/log/storm:rw -v /etc/localtime:/etc/localtime:ro --name storm-deploy centos6/storm-deploy:1.0
