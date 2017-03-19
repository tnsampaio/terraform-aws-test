#!/bin/sh

docker pull redmine
CMDLOGIN=`aws ecr get-login --region ${1}`

$CMDLOGIN

IMGID=`docker images | grep redmine | sed 's/ \+/ /g' | cut -f 3 -d " "`
ACCID=`aws sts get-caller-identity --output text --query 'Account'`

docker tag ${IMGID} ${ACCID}.dkr.ecr.us-east-1.amazonaws.com/redmine:latest
docker push ${ACCID}.dkr.ecr.us-east-1.amazonaws.com/redmine:latest