#!/bin/bash
set -x

MODE=${MODE:-clean}
PLATFORM=${PLATFORM:-SL6}

VOMSREPO=${VOMSREPO:-http://radiohead.cnaf.infn.it:9999/view/REPOS/job/repo_voms_develop_SL6/lastSuccessfulBuild/artifact/voms-develop_sl6.repo}

VO1=${VO1:-vomsci}
VO1_HOST=${VO1_HOST:-voms-server}
VO1_ISSUER=${VO1_ISSUER:-/C=IT/O=IGI/CN=voms-server}
VO2_PORT=${VO1_PORT:-15000}

VO2=${VO2:-test.vo}
VO2_HOST=${VO2_HOST:-vgrid02.cnaf.infn.it}
VO2_ISSUER=${VO2_ISSUER:-/C=IT/O=INFN/OU=Host/L=CNAF/CN=vgrid02.cnaf.infn.it}
VO2_PORT=${VO2_PORT:-15000}

mkdir -p /tmp/docker_voms/storage

# run VOMS deployment
deploy_id=`docker run -d -P -e "MODE=${MODE}" \
  -e "PLATFORM=${PLATFORM}" \
  -h voms-server \
  -v /etc/localtime:/etc/localtime:ro \
  -v /tmp/docker_voms/storage:/storage:rw \
  --name voms-server \
  centos6/voms-server:1.0`

# get names for deployment and testsuite containers
deployment_name=`docker inspect -f "{{ .Name }}" $deploy_id|cut -c2-`
testsuite_name="ts-linked-to-$deployment_name"

# run VOMS testsuite when deployment is over
docker run -e "VOMSREPO=${VOMSREPO}" \
  -e "VO1=${VO1}" \
  -e "VO1_HOST=${VO1_HOST}" \
  -e "VO1_ISSUER=${VO1_ISSUER}" \
  -e "VO1_PORT=${VO1_PORT}" \
  -e "VO2=${VO2}" \
  -e "VO2_HOST=${VO2_HOST}" \
  -e "VO2_ISSUER=${VO2_ISSUER}" \
  -e "VO2_PORT=${VO2_PORT}" \
  -h voms-ts \
  -v /etc/localtime:/etc/localtime:ro \
  --name $testsuite_name \
  --link $deployment_name:voms-server \
  centos6/voms-ts:1.1 \
  /bin/sh /setup_clients.sh

#  --volumes-from voms-server \

# copy testsuite reports
mkdir voms-ts_reports
docker cp $testsuite_name:/home/voms/voms-testsuite/reports .

# copy VOMS server logs 
docker cp $deployment_name:/var/log/voms voms-server_logs

# get deployment log
docker logs --tail="all" $deployment_name &> voms-server-deployment.log

# remove containers
docker rm -f $deployment_name
docker rm -f $testsuite_name
