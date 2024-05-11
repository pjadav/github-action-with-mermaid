
#!/usr/bin/env bash
set -e
set -u


IFS=‘/‘ read -ra commandArgs <<< "$1"

file1=`cat $1`
fileName="'${commandArgs[0]}'"-"'${commandArgs[1]}'"
mermaidMd="'${commandArgs[0]}'"-"'${commandArgs[1]}'"
filePathForMerMaid=${commandArgs[0]}/${commandArgs[1]}/policy.md
echo $fileName

(echo $file1 | jq -sR . | sed -E 's,\\t|\\r|\\n,,g' ) >> $fileName.text
out=`cat $fileName.text`

echo '{
  "policyName": "'${commandArgs[0]}'",
  "policyVersion": "'${commandArgs[1]}'",
  "policyJson": '"$out"'}'

http_response=$(curl --insecure -w "%{http_code}"  -o $mermaidMd.text --header "Content-Type: application/json" \
  --request POST \
  --data '{
  "policyName": "'${commandArgs[0]}'",
  "policyVersion": "'${commandArgs[1]}'",
  "policyJson": '"$out"'}' \
  https://rtdp-kronos-c99-service.ttldata.local/personalisation-config-manager-api/policies/mermaid)


echo "received response code: $http_response"


if [ $http_response -eq "200" ]
then
  echo "got 200"

  echo "\`\`\`mermaid" >> $filePathForMerMaid
  echo `cat $mermaidMd.text`  >> $filePathForMerMaid
  echo "\`\`\`"  >> $filePathForMerMaid

  rm -rf $fileName.text
  rm -rf $mermaidMd.text

  git status
  git add $filePathForMerMaid
  git -c user.email="your@email.com" -c user.name="RTDP" commit -m "add $filePathForMerMaid file"
  git push origin main
  rm -rf $filePathForMerMaid.md
else
  rm -rf $fileName.text
  rm -rf $mermaidMd.text
  exit 1
fi
