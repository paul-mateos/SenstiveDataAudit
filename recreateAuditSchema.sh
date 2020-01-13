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
# To configure:  Supply the correct API Account detail.
# 
GLOBAL_ACCOUNT="customer1_e6e9c99c-938b-47ec-8384-ed85a540ff84"
API_KEY="93515053-8dd5-4bf6-a278-aec3ef3ed02c"
controllerURL="http://enterpriseconsolep-vhpaulmateos-hmpczlps.srv.ravcloud.com"

curl -v -k -X DELETE "$controllerURL:9080/events/schema/INTERNAL_AUDITS" -H"X-Events-API-AccountName:$GLOBAL_ACCOUNT" -H"X-Events-API-Key:$API_KEY"

# Wait for the schema to disappear. 
sleep 30
 
#curl -k --proxy PROXY_HOST:PORT -X POST "$URL/schema/INTERNAL_AUDITS" -H"X-Events-API-AccountName:$API_ACCOUNT" -H"X-Events-API-Key:$API_KEY" -H"Content-type: application/vnd.appd.events+json;v=2" -d "{\"schema\" : { \"AuditTime\": \"string\", \"Environment\": \"string\", \"Tenant\": \"string\", \"SnapshotType\": \"string\", \"Status\": \"string\", \"Description\": \"string\", \"SampleData\": \"string\"} }"
curl -v -k -X POST "$controllerURL:9080/events/schema/INTERNAL_AUDITS" -H"X-Events-API-AccountName:$GLOBAL_ACCOUNT" -H"X-Events-API-Key:$API_KEY" -H"Content-type: application/vnd.appd.events+json;v=2" -d "{\"schema\" : { \"AuditTime\": \"string\", \"Environment\": \"string\", \"Tenant\": \"string\", \"SnapshotType\": \"string\", \"Status\": \"string\", \"Description\": \"string\", \"SampleData\": \"string\"} }"
