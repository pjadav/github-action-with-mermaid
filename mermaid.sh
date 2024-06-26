
#!/usr/bin/bash -e {0}
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
pwd

if [ $http_response -eq "200" ]
then
  echo "got 200"

  echo "\`\`\`mermaid" >> $filePathForMerMaid
  echo `cat $mermaidMd.text`  >> $filePathForMerMaid
  echo "\`\`\`"  >> $filePathForMerMaid

  rm -rf $fileName.text
  rm -rf $mermaidMd.text

  git add .
  git config --local user.email "97456030+pjadav@users.noreply.github.com"
  git config --local user.name "pjadav"
  git commit -a -m "Add changes"
  git push

else
  rm -rf $fileName.text
  rm -rf $mermaidMd.text
  exit 1
fi
