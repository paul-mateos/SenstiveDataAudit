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
# To configure:  Supply the correct API Account detail.
# 


#refer to config file
. ./controller.config

if [ $# -gt 0 ]; then
   env=$1
else
   echo "Usage ./auditSnapshots.sh <env> <tenant> <duration> <snapshot-type>"
   exit
fi
 
if [ "$env" == "Prod" ]; then
  eventsURL=$Prod_eventsURL
  GLOBAL_ACCOUNT=$Prod_API_ACCOUNT             # Controller Global Account Name
  API_KEY=$Prod_API_KEY
  ProxyHost=$Prod_ProxyServer
  ProxyPort=$Prod_ProxyPort
elif [ "$env" == "Test" ]; then
  eventsURL=$Test_eventsURL
  GLOBAL_ACCOUNT=$Test_API_ACCOUNT             # Controller Global Account Name
  API_KEY=$Test_API_KEY
  ProxyHost=$Test_ProxyServer
  ProxyPort=$Test_ProxyPort
else
  echo "Invalid environment specified"
  exit
fi

# Delete existing schema
curl -v -k -X DELETE --proxy $ProxyHost:$ProxyPort "$eventsURL/events/schema/INTERNAL_AUDITS" -H"X-Events-API-AccountName:$GLOBAL_ACCOUNT" -H"X-Events-API-Key:$API_KEY"

# Wait for the schema to disappear. 
sleep 30

#Create new schema 
curl -v -k -X POST --proxy $ProxyHost:$ProxyPort "$eventsURL/events/schema/INTERNAL_AUDITS" -H"X-Events-API-AccountName:$GLOBAL_ACCOUNT" -H"X-Events-API-Key:$API_KEY" -H"Content-type: application/vnd.appd.events+json;v=2" -d "{\"schema\" : { \"AuditTime\": \"string\", \"Environment\": \"string\", \"Tenant\": \"string\", \"SnapshotType\": \"string\", \"Status\": \"string\", \"Description\": \"string\", \"SampleData\": \"string\"} }"
