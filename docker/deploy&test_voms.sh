#!/bin/bash
set -x

MODE="${MODE:-clean}"
PLATFORM="${PLATFORM:-SL6}"
VO="${VO:-test.vo}"
VO_HOST="${VO_HOST:-vgrid02.cnaf.infn.it}"
VO_ISSUER="${VO_ISSUER:-/C=IT/O=INFN/OU=Host/L=CNAF/CN=vgrid02.cnaf.infn.it}"
VOMSREPO="${VOMSREPO:-http://radiohead.cnaf.infn.it:9999/view/REPOS/job/repo_voms_develop_SL6/lastSuccessfulBuild/artifact/voms-develop_sl6.repo}"


mkdir -p /tmp/docker_voms/storage

# run VOMS deployment
docker run -d -P -e "MODE=${MODE}" \
  -e "PLATFORM=${PLATFORM}" \
  -h voms-server \
  -v /etc/localtime:/etc/localtime:ro \
  -v /tmp/docker_voms/storage:/storage:rw \
  --name voms-server \
  centos6/voms-server:1.0

# run VOMS testsuite when deployment is over
docker run -e "VO=${VO}" \
  -e "VO_HOST=${VO_HOST}" \
  -e "VO_ISSUER=${VO_ISSUER}" \
  -e "VOMSREPO=${VOMSREPO}" \  
  -h voms-ts \
  -v /etc/localtime:/etc/localtime:ro \
  --name voms-ts \
  --link voms-server:voms-server \
  --volumes-from voms-server \
  centos6/voms-ts:1.0

# copy testsuite reports
mkdir voms-ts_reports
docker cp voms-ts:/home/voms/voms-testsuite/reports voms-ts_reports/

# copy VOMS logs 
docker cp voms-server:/var/log/voms .

# get deployment log
docker logs --tail="all" voms-server &> voms-server-deployment.log

# remove containers
docker rm -f voms-server
docker rm -f voms-ts-linked
