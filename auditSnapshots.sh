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
# Author:  Hans.Botha@appdynamics.com
#
# To configure:  Supply the correct paths, URL's and Base64 connect string.
# 


#configure all your connection details
export AUDITHOME=`pwd`
echo $AUDITHOME
cookieFile=$AUDITHOME'/out/audit/cookies/cookie.appd.'$$
filter=$AUDITHOME'/out/audit/config/sensitiveFilters.config'

#refer to config file
. ./controller.config

if [ $# -gt 0 ]; then
   env=$1
else
   echo "Usage ./auditSnapshots.sh <env> <tenant> <duration> <snapshot-type>"
   exit
fi
 
if [ "$env" == "Prod" ]; then
  controllerURL=$Prod_controllerURL 
  hashedCredentials=$Prod_hashedCredentials
  API_ACCOUNT=$Prod_API_ACCOUNT             # Controller Global Account Name
  API_KEY=$Prod_API_KEY 
  ProxyServer=$Prod_ProxyServer
  ProxyPort=$Prod_ProxyPort
  URL="$Prod_eventsURL/events"
  analyticsURL="$Prod_eventsURL/events/query"
elif [ "$env" == "Test" ]; then
  controllerURL=$Test_controllerURL
  hashedCredentials=$Test_hashedCredentials
  API_ACCOUNT=$Test_API_ACCOUNT             # Controller Global Account Name
  API_KEY=$Test_API_KEY 
  ProxyServer=$Test_ProxyServer
  ProxyPort=$Test_ProxyPort
  analyticsURL="$Test_eventsURL/events/query"  
  URL="$Test_eventsURL/events"
else
  echo "Invalid environment specified"
  exit
fi
 
if [ $# -gt 1 ]; then
  tenant=$2
else
  tenant="All"
fi
 
if [ $# -gt 2 ]; then
  duration=$3
else
  duration=15
fi
 
types="NORMAL,SLOW,VERY_SLOW"
 
if [ $# -gt 3 ]; then
  type=$4
  if [ "$type" == "ERROR" ]; then
    types="ERROR"
  fi   
else
  types="NORMAL"
fi
 
if [ $# -gt 4 ]; then
  audit=1
  logFile=$AUDITHOME'/out/audit/log/'$env$types'.log'
  `rm $logFile`
else
  audit=0
fi
 
reportDir=$AUDITHOME'/out/audit'

appList=$AUDITHOME'/out/audit/apps/AppsList'$env'.txt'
runList=$AUDITHOME'/out/audit/apps/RunList'$env'.txt'

 
curl -s -c $cookieFile --proxy $ProxyHost:$ProxyPort --header "Authorization: Basic ${hashedCredentials}"  -X GET $controllerURL/auth?action=login
X_CSRF_TOKEN="$(grep X-CSRF-TOKEN $cookieFile|rev|cut -d$'\t' -f1|rev)"
X_CSRF_TOKEN_HEADER="`if [ -n "$X_CSRF_TOKEN" ]; then echo "X-CSRF-TOKEN:$X_CSRF_TOKEN"; else echo ''; fi`"
 
#
#The following REST Call is used to extract a list of Applications
#
if [ "$tenant" == "All" ]; then
   cp $appList $runList
else
   echo $tenant > $runList
   echo $runList
fi
sleep 1
echo $logFile
 
cat $runList | while IFS='|' read name id
do
  shortName=`echo $name | cut -d- -f1 | cut -d_ -f1`
 
  echo "Getting Snapshot detail for: "  $name;
  echo $controllerURL"/rest/applications/"$id"/request-snapshots?time-range-type=BEFORE_NOW&duration-in-mins="$duration"&maximum-results=100000&user-experience="$types"&need-props=true&need-exit-calls=true"
  curl -s -b $cookieFile --proxy $ProxyHost:$ProxyPort -H "$X_CSRF_TOKEN_HEADER" -X GET "$controllerURL/rest/applications/$id/request-snapshots?time-range-type=BEFORE_NOW&duration-in-mins=$duration&maximum-results=100000&user-experience=$types&need-props=true&need-exit-calls=true" > $AUDITHOME"/out/audit/snapshots/$shortName.$types.snapshots.txt";

  # Process Application Specific Exclude filter.  Config file needs to include the first unique part.
  # Example:  HELLO:  will represent HELLO-PROD, HELLO-DEV, HELLO-Anything
 
  OPTIONS=`grep "^$shortName" $filter | cut -d: -f2`
 
  if [ "$OPTIONS" == "" ]; then
    echo ""
    echo "   ****** Cannot find filter in $filter - Using default"
    echo ""
    # Set OPTIONS Default to exclude 16-Digit numbers that does not contain sensitive data.
    OPTIONS="|grep -v StartTime |grep -v requestGUID |grep -v httpSessionID |grep -E -v [a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}"
  fi
 
  if [ "$audit" == 1 ]; then
    echo "Getting Snapshot detail for: $name"  >> $logFile
    echo "" >> $logFile
    echo "  $OPTIONS" >> $logFile
    echo "" >> $logFile
  fi
 
 entriesFound=0;
 cmd="grep -E '(?:[0-9]{1,3}\.){3}[0-9]{1,3}|[0-9]{16}|(\.[\w\-]+)*@([A-Za-z0-9-]+\.)+[A-Za-z]{2,4}' $AUDITHOME"/out/audit/snapshots/"$shortName.$types.snapshots.txt $OPTIONS |sed -E 's/\b\w+@/###  Email-Address  ### @/g' | sed -E 's/[0-9]{16}/#### 16 Digits ####/g'"
 entriesFound=`eval $cmd | wc -l`
  #  Publish results to Analytics Custom Schema

  
 # if [[ $1 == "Prod" ]]; then
 # fi

  NOW=`date +"%Y-%m-%d : %T"`
 
  if [[ $entriesFound -eq 0 ]]; then
     Status="Comply"
     Description="Healthy"
     Data=""
     echo curl -k --proxy $ProxyHost:$ProxyPort  -X POST "$URL/publish/INTERNAL_AUDITS" -H"X-Events-API-AccountName:$API_ACCOUNT" -H"X-Events-API-Key:$API_KEY" -H"Content-type: application/vnd.appd.events+json;v=2" -d "[ { \"Environment\": \"$1\", \"Tenant\": \"$name\", \"SnapshotType\": \"$types\", \"AuditTime\": \"$NOW\", \"Status\": \"$Status\", \"Description\": \"$Description\", \"SampleData\": \"$Data\" } ]"
     curl -k --proxy $ProxyHost:$ProxyPort  -X POST "$URL/publish/INTERNAL_AUDITS" -H"X-Events-API-AccountName:$API_ACCOUNT" -H"X-Events-API-Key:$API_KEY" -H"Content-type: application/vnd.appd.events+json;v=2" -d "[ { \"Environment\": \"$1\", \"Tenant\": \"$name\", \"SnapshotType\": \"$types\", \"AuditTime\": \"$NOW\", \"Status\": \"$Status\", \"Description\": \"$Description\", \"SampleData\": \"$Data\" } ]"
  else
     echo "Potential issues requiring further investigation:"
     echo "================================================"
     eval $cmd
     echo $entriesFound
     Status="Investigate"
     Description="Potential issues"
     echo $cmd
     Data="'"`eval $cmd | sort -u | tr '\n' ';'`"'"
    # echo $Data
     echo curl -k --proxy $ProxyHost:$ProxyPort -X POST "$URL/publish/INTERNAL_AUDITS" -H"X-Events-API-AccountName:$API_ACCOUNT" -H"X-Events-API-Key:$API_KEY" -H"Content-type: application/vnd.appd.events+json;v=2" -d "[ { \"Environment\": \"$1\", \"Tenant\": \"$name\", \"SnapshotType\": \"$types\", \"AuditTime\": \"$NOW\", \"Status\": \"$Status\", \"Description\": \"$Description\", \"SampleData\": \"$Data\" } ]"
     curl -k -X POST "$URL/publish/INTERNAL_AUDITS" -H"X-Events-API-AccountName:$API_ACCOUNT" -H"X-Events-API-Key:$API_KEY" -H"Content-type: application/vnd.appd.events+json;v=2" -d "[ { \"Environment\": \"$1\", \"Tenant\": \"$name\", \"SnapshotType\": \"$types\", \"AuditTime\": \"$NOW\", \"Status\": \"$Status\", \"Description\": \"$Description\", \"SampleData\": \"$Data\" } ]"
  fi 
 
  if [ "$audit" == 1 ]; then
    cmd="$cmd >> $logFile"
    eval $cmd
  fi
 
  RESULT=`tail -10 $reportDir/snapshots/$shortName.$types.snapshots.txt`;
  [[ "$RESULT" =~ "500 Internal Server Error" ]] && echo "The selection window may be too large.  Please use a smaller window.  Error Message:  $RESULT"
done
 
if [ -f "$cookieFile" ]; then
  rm $cookieFile
fi
