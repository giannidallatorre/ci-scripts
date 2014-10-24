#!/bin/bash
set -x

MODE="${MODE:-clean}"
PLATFORM="${PLATFORM:-SL6}"
STORM_REPO="${STORM_REPO:-http://radiohead.cnaf.infn.it:9999/view/REPOS/job/repo_storm_develop_SL6/lastSuccessfulBuild/artifact/storm_develop_sl6.repo}"

mkdir -p /tmp/docker_storm/storage

# run StoRM deployment
docker run -d -e "STORM_REPO=${STORM_REPO}" -e "MODE=${MODE}" -e "PLATFORM=${PLATFORM}" \
  -h docker-storm.cnaf.infn.it \
  -v /tmp/docker_storm/storage:/storage:rw \
  -v /etc/localtime:/etc/localtime:ro \
  --name storm-deploy \
  centos6/storm-deploy:1.0 \
  /bin/sh deploy.sh

# run StoRM testsuite when deployment is over
docker run --link storm-deploy:docker-storm.cnaf.infn.it \
  -v /etc/localtime:/etc/localtime:ro \
  --name storm-ts-linked \
  centos6/storm-ts:1.0

# copy testsuite reports 
docker cp storm-ts-linked:/home/tester/storm-testsuite/reports .

# copy StoRM logs 
docker cp storm-deploy:/var/log/storm .

# get deployment log
docker logs --tail="all" storm-deploy &> storm-deployment.log

# remove containers
docker rm -f storm-deploy
docker rm -f storm-ts-linked
