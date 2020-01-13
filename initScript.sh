#!/bin/bash
export AUDITHOME=`pwd`
echo $AUDITHOME
mkdir -p $AUDITHOME/out/audit/cookies
mkdir -p $AUDITHOME/out/audit/config
mkdir -p $AUDITHOME/out/audit/log
mkdir -p $AUDITHOME/out/audit/apps
mkdir -p $AUDITHOME/out/audit/snapshots

cp $AUDITHOME/sensitiveFilters.config $AUDITHOME/out/audit/config/sensitiveFilters.config
cp $AUDITHOME/formatJson.py $AUDITHOME/out/audit/config

echo "****COMPLETE******"

#appList=$reportDir'/config/.doNotDelete/AppsList'$env'.txt'
#runList=$reportDir'/config/RunList'$env'.txt'
 
