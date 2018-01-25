#!/bin/bash -x

TMP_JSON=$(mktemp)
AMIMOTO_JSON=$(cat /opt/local/amimoto.json)

git -C /opt/local/chef-repo/cookbooks/amimoto/ pull origin 2016.01
jq -s '.[1] * .[0]' <(echo '{"phpfpm":{"version":"72"}}') <(echo $AMIMOTO_JSON) > /opt/local/amimoto.json
mv -f ${TMP_JSON} /opt/local/amimoto.json
