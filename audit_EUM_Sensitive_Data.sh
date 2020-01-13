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
export AUDITHOME=`pwd`
echo $AUDITHOME
cookieFile=$AUDITHOME'/out/audit/cookies/cookie.appd.'$$
filter=$AUDITHOME'/out/audit/config/sensitiveFilters.config'
analyticsURL='https://analytics.api.appdynamics.com/events/query'

if [ $# -gt 0 ]; then
   env=$1
else
   echo "Usage ./audit_EUM_Sensitive_Data.sh <env>"
   exit
fi
 
if [ "$env" == "Prod" ]; then
    controllerURL="https://xxxxas.appdynamics.com/controller"
    hashedCredentials='xxxxNva2UxMjM='
    API_ACCOUNT="xxxx2f-45f9-8f1f-20875e4ac32f"                                  # Controller Global Account Name
    API_KEY="xxxxxc-75db00368c50" 
    ProxyServer='XXXX'
    ProxyPort='XXXX'
else
  if [ "$env" == "Test" ]; then
    controllerURL="https://XXXXX-test.saas.appdynamics.com/controller"
    hashedCredentials='XXXXXXXXXX'      # Controller Access
    AccountName='XXXXXXXX'              # Controller Global Account Name
    API_KEY='XXXXXXXX'                  # Custom events API Key with Schema Update permissions
  else
    echo "Invalid environment specified"
    exit
  fi
fi
 
curl -s -c $cookieFile --header "Authorization: Basic ${hashedCredentials}"  -X GET $controllerURL/auth?action=login
X_CSRF_TOKEN="$(grep X-CSRF-TOKEN $cookieFile|rev|cut -d$'\t' -f1|rev)"
X_CSRF_TOKEN_HEADER="`if [ -n "$X_CSRF_TOKEN" ]; then echo "X-CSRF-TOKEN:$X_CSRF_TOKEN"; else echo ''; fi`"
 
appsList=`curl -s -b $cookieFile -H "$X_CSRF_TOKEN_HEADER" -X GET "$controllerURL/restui/eumApplications/getAllEumApplicationsData?time-range=last_2_weeks.BEFORE_NOW.-1.-1.20160" | grep appKey | sed -E 's/\".* \: \"//g' | sed -E 's/",//g'`
for appKey in $appsList
do
  echo $appKey
  stmt=`echo curl -s  -X POST \"$analyticsURL\" -H\"X-Events-API-AccountName:$API_ACCOUNT\" -H\"X-Events-API-Key:$API_KEY\" -H\"Content-type: application/vnd.appd.events+text\;v=2\" -d \'SELECT pagename, pageurl FROM browser_records WHERE appkey = \"ABCDEF\" SINCE 30 minutes\' | sed "s/ABCDEF/$appKey/g"`
  eval $stmt > /Applications/AppDynamics/data/AppdCustomReports/tmpFile.json
  entriesFound=0;
  #cmd="python /Users/yadiraj.narayan/Documents/westpac/Audit/formatJson.py | grep -E '(?:[0-9]{1,3}\.){3}[0-9]{1,3}|[0-9]{16}|(\.[\w\-]+)*@([A-Za-z0-9-]+\.)+[A-Za-z]{2,4}' $OPTIONS |sed -E 's/\b\w+@/###  Email-Address  ### @/g' | sed -E 's/[0-9]{16}/#### 16 Digits ####/g'"
   cmd="python /Users/yadiraj.narayan/Documents/westpac/Audit/formatJson.py | grep -E '(?:[0-9]{1,3}\.){3}[0-9]{1,3}|[0-9]{16}|[0-9]{16}|(\.[\w\-]+)*@([A-Za-z0-9-]+\.)+[A-Za-z]{2,4}' $OPTIONS |sed -E 's/\b\w+@/###  Email-Address  ### @/g' | sed -E 's/[0-9]{16}/#### 16 Digits ####/g' | sed -E 's/\"//g'"
  entriesFound=`eval $cmd | wc -l`
  echo $entriesFound
 
  #  Publish results to Analytics Custom Schema
  URL="https://analytics.api.appdynamics.com/events"
   if [[ $1 == "Prod" ]]; then

    AccountName="xxxxx5f9-8f1f-20875e4ac32f"                                  # Controller Global Account Name
    API_KEY="xxxxxxxx-9abc-75db00368c50" 
     

  else

     AccountName="XXXXXX"

     API_KEY="XXXXXX"

  fi

  NOW=`date +"%Y-%m-%d : %T"`

 
  if [[ $entriesFound -eq 0 ]]; then
     Status="Comply"
     Description="Healthy"
     Data=""
     echo  curl -k  -X POST "$URL/publish/INTERNAL_AUDITS" -H"X-Events-API-AccountName:$API_ACCOUNT" -H"X-Events-API-Key:$API_KEY" -H"Content-type: application/vnd.appd.events+json;v=2" -d "[ { \"Environment\": \"$1\", \"Tenant\": \"$appKey\", \"SnapshotType\": \"Browser Record\", \"AuditTime\": \"$NOW\", \"Status\": \"$Status\", \"Description\": \"$Description\", \"SampleData\": \"$Data\" } ]"
     curl -k  -X POST "$URL/publish/INTERNAL_AUDITS" -H"X-Events-API-AccountName:$API_ACCOUNT" -H"X-Events-API-Key:$API_KEY" -H"Content-type: application/vnd.appd.events+json;v=2" -d "[ { \"Environment\": \"$1\", \"Tenant\": \"$appKey\", \"SnapshotType\": \"Browser Record\", \"AuditTime\": \"$NOW\", \"Status\": \"$Status\", \"Description\": \"$Description\", \"SampleData\": \"$Data\" } ]"
  else
     echo "Potential issues requiring further investigation:"
     echo "================================================"
     Status="Investigate"
     Description="Potential issues"
     #Data="'"`eval $cmd | sort -u | tr '\n' ';'`"'"
     #Data="'"`eval $cmd | sort -u | tr '\n' ';'`"'" | sed -e 's/\"//g'
     Data="'"`eval $cmd | sort -u | tr '\n' ';'`"'"
    # echo $Data
     echo curl -k  -X POST "$URL/publish/INTERNAL_AUDITS" -H"X-Events-API-AccountName:$API_ACCOUNT" -H"X-Events-API-Key:$API_KEY" -H"Content-type: application/vnd.appd.events+json;v=2" -d "[ { \"Environment\": \"$1\", \"Tenant\": \"$appKey\", \"SnapshotType\": \"Browser Record\", \"AuditTime\": \"$NOW\", \"Status\": \"$Status\", \"Description\": \"$Description\", \"SampleData\": \"$Data\" } ]"
     curl -k  -X POST "$URL/publish/INTERNAL_AUDITS" -H"X-Events-API-AccountName:$API_ACCOUNT" -H"X-Events-API-Key:$API_KEY" -H"Content-type: application/vnd.appd.events+json;v=2" -d "[ { \"Environment\": \"$1\", \"Tenant\": \"$appKey\", \"SnapshotType\": \"Browser Record\", \"AuditTime\": \"$NOW\", \"Status\": \"$Status\", \"Description\": \"$Description\", \"SampleData\": \"$Data\" } ]"
  fi

done
 
if [ -f "$cookieFile" ]; then
  rm $cookieFile

fi

