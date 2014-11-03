#!/bin/bash
set -x

MODE="${MODE:-clean}"
PLATFORM="${PLATFORM:-SL6}"
STORM_REPO="${STORM_REPO:-http://radiohead.cnaf.infn.it:9999/view/REPOS/job/repo_storm_develop_SL6/lastSuccessfulBuild/artifact/storm_develop_sl6.repo}"

mkdir -p /tmp/docker_storm/storage

# run StoRM deployment and get its id
deploy_id=`docker run -d -e "STORM_REPO=${STORM_REPO}" -e "MODE=${MODE}" -e "PLATFORM=${PLATFORM}" \
  -h docker-storm.cnaf.infn.it \
  -v /tmp/docker_storm/storage:/storage:rw \
  -v /etc/localtime:/etc/localtime:ro \
  centos6/storm-deploy:1.0 \
  /bin/sh deploy.sh`

# get names for deployment and testsuite containers
deployment_name=`docker inspect -f "{{ .Name }}" $deploy_id|cut -c2-`
testsuite_name="ts-linked-to-$deployment_name"

# run StoRM testsuite when deployment is over
docker run --link $deployment_name:docker-storm.cnaf.infn.it \
  -v /etc/localtime:/etc/localtime:ro \
  --name $testsuite_name \
  centos6/storm-ts:1.0

# copy testsuite reports 
docker cp $testsuite_name:/home/tester/storm-testsuite/reports .

# copy StoRM logs 
docker cp $deployment_name:/var/log/storm .

# get deployment log
docker logs --tail="all" $deployment_name &> storm-deployment.log

# remove containers
docker rm -f $deployment_name
docker rm -f $testsuite_name

