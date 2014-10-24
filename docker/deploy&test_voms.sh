#!/bin/bash
set -x

MODE="${MODE:-clean}"
PLATFORM="${PLATFORM:-SL6}"

mkdir -p /tmp/docker_voms/storage

# run VOMS deployment
docker run -d -P -e "MODE=${MODE}" -e "PLATFORM=${PLATFORM}" \
  -h voms-server \
  -v /tmp/docker_voms/storage:/storage:rw \
  -v /etc/localtime:/etc/localtime:ro \
  --name voms-server \
  centos6/voms-server:1.0 \
  /bin/sh deploy.sh

# run VOMS testsuite when deployment is over
docker run --link voms-server:voms-server \
  --volumes-from voms-server \
  -v /etc/localtime:/etc/localtime:ro \
  --name voms-ts-linked \
  centos6/voms-ts:1.0

# copy testsuite reports 
docker cp voms-ts-linked:/home/tester/voms-testsuite/reports .

# copy VOMS logs 
docker cp voms-server:/var/log/voms .

# get deployment log
docker logs --tail="all" voms-server &> voms-server-deployment.log

# remove containers
docker rm -f voms-server
docker rm -f voms-ts-linked
