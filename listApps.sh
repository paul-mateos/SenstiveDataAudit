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
# List of all Applications in AppDynamics that must be excluded, example Discontinued Applications
 
excludedApps=''
export AUDITHOME=`pwd`
echo $AUDITHOME
cookieFile=$AUDITHOME'/out/audit/cookies/cookie.appd.'$$
filter=$AUDITHOME'/out/audit/config/sensitiveFilters.config'

#refer to config file
. ./controller.config

if [ $# -gt 0 ]; then
   env=$1
else
   echo "Usage ./listApps.sh <env>"
   exit
fi

if [ "$env" == "Prod" ]; then
  controllerURL=$Prod_controllerURL 
  hashedCredentials=$Prod_hashedCredentials
  API_ACCOUNT=$Prod_API_ACCOUNT             # Controller Global Account Name
  API_KEY=$Prod_API_KEY 
  ProxyServer=$Prod_ProxyServer
  ProxyPort=$Prod_ProxyPort
elif [ "$env" == "Test" ]; then
  controllerURL=$Test_controllerURL
  hashedCredentials=$Teset_hashedCredentials
  API_ACCOUNT=$Test_API_ACCOUNT             # Controller Global Account Name
  API_KEY=$Test_API_KEY 
  ProxyServer=$Test_ProxyServer
  ProxyPort=$Test_ProxyPort  
else
  echo "Invalid environment specified"
  exit
fi


if [ $# -gt 1 ]; then
  report="1"
else
  report="0"
fi
 
if [ $# -gt 2 ]; then
  email="1"
else
  email="0"
fi
 
#
#  Strings to extract from the XML output
#
xmltag1=id;                                 # Business hans.p.botha ID
xmltag2=name;                               # Business Application Name
xmltag3=internalName;                       # Business Transaction Name
 
#configure all your connection details
echo $controllerURL
 curl -v -c $cookieFile --proxy $ProxyHost:$ProxyPort --header "Authorization: Basic ${hashedCredentials}" $controllerURL/auth?action=login
 echo "Cookiefile:"$cookieFile
 X_CSRF_TOKEN="$(grep X-CSRF-TOKEN $cookieFile|rev|cut -d$'\t' -f1|rev)"
 echo "Token:"$X_CSRF_TOKEN
 X_CSRF_TOKEN_HEADER="`if [ -n "$X_CSRF_TOKEN" ]; then echo "X-CSRF-TOKEN:$X_CSRF_TOKEN"; else echo ''; fi`"
 
 #
 #Once your cookie is available, please look at these two examples to extract Events and Problems (Health Rules that raised alerts)
 #

 curl -v -i -b $cookieFile --proxy $ProxyHost:$ProxyPort -H "$X_CSRF_TOKEN_HEADER" "$controllerURL/rest/applications" |sed -n '/<'"${xmltag1}"'>/,/<\/'"$xmltag2"'>/ {
 s/^.*<'"$xmltag1"'>//
 s/<\/'"$xmltag1"'>.*$//
 s/^.*<'"$xmltag2"'>//
 s/<\/'"$xmltag2"'>.*$//
 p
 }'  | while read line1; do read line2; application=`echo $line2 | tr ' ' '_'`; echo "$application|$line1"; done | sort --ignore-case > $AUDITHOME/out/audit/apps/AppsList$env.txt



  
 if [ -f "$cookieFile" ]; then
   rm $cookieFile
 fi

