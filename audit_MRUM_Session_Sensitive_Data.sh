#!/bin/bash
 
# AppDynamics Legal Disclosure
#
# THE SCRIPT IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THIS SCRIPT OR THE USE OR
# OTHER DEALINGS IN THE SCRIPT.
#


#
# Author:  Paul.Mateos@appdynamics.com
#
# To configure:  Supply the correct paths, URL's and Base64 connect string.
# 
 
export AUDITHOME=`pwd`
echo $AUDITHOME
cookieFile=$AUDITHOME'/out/audit/cookies/cookie.appd.'$$
filter=$AUDITHOME'/out/audit/config/sensitiveFilters.config'
#refer to config file
. ./controller.config

if [ $# -gt 0 ]; then
   env=$1
else
   echo "Usage ./audit_EUM_Sensitive_Data.sh <env>"
   exit
fi
 
if [ "$env" == "Prod" ]; then
  eventsURL=$Prod_eventsURL
  controllerURL=$Prod_controllerURL 
  hashedCredentials=$Prod_hashedCredentials
  API_ACCOUNT=$Prod_API_ACCOUNT             # Controller Global Account Name
  API_KEY=$Prod_API_KEY 
  ProxyHost=$Prod_ProxyServer
  ProxyPort=$Prod_ProxyPort
elif [ "$env" == "Test" ]; then
  eventsURL=$Test_eventsURL
  controllerURL=$Test_controllerURL
  hashedCredentials=$Test_hashedCredentials
  API_ACCOUNT=$Test_API_ACCOUNT             # Controller Global Account Name
  API_KEY=$Test_API_KEY 
  ProxyHost=$Test_ProxyServer
  ProxyPort=$Test_ProxyPort
else
  echo "Invalid environment specified"
  exit
fi
 
curl -v -c $cookieFile --header "Authorization: Basic ${hashedCredentials}"  -X GET $controllerURL/auth?action=login
X_CSRF_TOKEN="$(grep X-CSRF-TOKEN $cookieFile|rev|cut -d$'\t' -f1|rev)"
X_CSRF_TOKEN_HEADER="`if [ -n "$X_CSRF_TOKEN" ]; then echo "X-CSRF-TOKEN:$X_CSRF_TOKEN"; else echo ''; fi`"
 
appsList=`curl -v -b $cookieFile -H "$X_CSRF_TOKEN_HEADER" -X GET "$controllerURL/restui/eumApplications/getAllMobileApplicationsData?time-range=last_2_weeks.BEFORE_NOW.-1.-1.20160" | grep appKey | sed -E 's/\".* \: \"//g' | sed -E 's/",//g'`
sortedList=$(echo $appsList | xargs -n1 | sort -u | xargs)
for appKey in $sortedList
do
  echo $appKey
  stmt=`echo curl -v -X POST \"$eventsURL/events/query\" -H\"X-Events-API-AccountName:$API_ACCOUNT\" -H\"X-Events-API-Key:$API_KEY\" -H\"Content-type: application/vnd.appd.events+text\;v=2\" -d \'SELECT networkrequest.networkrequestname, ip, crash.crashexception FROM mobile_session_records WHERE appkey = \"ABCDEF\" SINCE 30 minutes\' | sed "s/ABCDEF/$appKey/g"`
  eval $stmt > ./tmpFile.json
  entriesFound=0;
  cmd="python ./formatJson.py | grep -E '(?:[0-9]{1,3}\.){3}[0-9]{1,3}|[0-9]{16}|[0-9]{16}|(\.[\w\-]+)*@([A-Za-z0-9-]+\.)+[A-Za-z]{2,4}' $OPTIONS |sed -E 's/\b\w+@/###  Email-Address  ### @/g' | sed -E 's/[0-9]{16}/#### 16 Digits ####/g' | sed -E 's/\"//g'"
  entriesFound=`eval $cmd | wc -l`
  echo $entriesFound
 
  #  Publish results to Analytics Custom Schema
  NOW=`date +"%Y-%m-%d : %T"`

  if [[ $entriesFound -eq 0 ]]; then
     Status="Comply"
     Description="Healthy"
     Data=""
     curl -k -v -X POST "$eventsURL/events/publish/INTERNAL_AUDITS" -H"X-Events-API-AccountName:$API_ACCOUNT" -H"X-Events-API-Key:$API_KEY" -H"Content-type: application/vnd.appd.events+json;v=2" -d "[ { \"Environment\": \"$1\", \"Tenant\": \"$appKey\", \"SnapshotType\": \"Mobile Session\", \"AuditTime\": \"$NOW\", \"Status\": \"$Status\", \"Description\": \"$Description\", \"SampleData\": \"$Data\" } ]"
  else
     echo "Potential issues requiring further investigation:"
     echo "================================================"
     Status="Investigate"
     Description="Potential issues"
     #Data="'"`eval $cmd | sort -u | tr '\n' ';'`"'"
     #Data="'"`eval $cmd | sort -u | tr '\n' ';'`"'" | sed -e 's/\"//g'
     Data="'"`eval $cmd | sort -u | tr '\n' ';'`"'"
    # echo $Data
     echo curl -k -v -X POST "$eventsURL/events/publish/INTERNAL_AUDITS" -H"X-Events-API-AccountName:$API_ACCOUNT" -H"X-Events-API-Key:$API_KEY" -H"Content-type: application/vnd.appd.events+json;v=2" -d "[ { \"Environment\": \"$1\", \"Tenant\": \"$appKey\", \"SnapshotType\": \"Mobile Session\", \"AuditTime\": \"$NOW\", \"Status\": \"$Status\", \"Description\": \"$Description\", \"SampleData\": \"$Data\" } ]"
     curl -k -v -X POST "$eventsURL/events/publish/INTERNAL_AUDITS" -H"X-Events-API-AccountName:$API_ACCOUNT" -H"X-Events-API-Key:$API_KEY" -H"Content-type: application/vnd.appd.events+json;v=2" -d "[ { \"Environment\": \"$1\", \"Tenant\": \"$appKey\", \"SnapshotType\": \"Mobile Session\", \"AuditTime\": \"$NOW\", \"Status\": \"$Status\", \"Description\": \"$Description\", \"SampleData\": \"$Data\" } ]"
  fi
 
done
 
if [ -f "$cookieFile" ]; then
  rm $cookieFile
fi

