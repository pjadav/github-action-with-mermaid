
#!/usr/bin/env bash
set -e
set -u

IFS=‘/‘ read -ra commandArgs <<< "$1"

file1=`cat $1`
fileName="'${commandArgs[0]}'"-"'${commandArgs[1]}'"
errorFileName="'${commandArgs[0]}'"-"'${commandArgs[1]}-error'"
echo $fileName

(echo $file1 | jq -sR . | sed -E 's,\\t|\\r|\\n,,g' ) >> $fileName.text
out=`cat $fileName.text`

echo '{
  "policyName": "'${commandArgs[0]}'",
  "policyVersion": "'${commandArgs[1]}'",
  "policyJson": '"$out"'}'

http_response=$(curl --insecure -w "%{http_code}"  -o $errorFileName --header "Content-Type: application/json" \
  --request POST \
  --data '{
  "policyName": "'${commandArgs[0]}'",
  "policyVersion": "'${commandArgs[1]}'",
  "policyJson": '"$out"'}' \
  https://rtdp-kronos-c99-service.ttldata.local/personalisation-config-manager-api/policies)


echo "received response code: $http_response"
echo "failure reason: `cat $errorFileName`"

rm -rf $fileName.text
rm -rf $errorFileName
  
if [ $http_response -eq "200" ]
then
  echo "got 200"
else
  exit 1
fi
