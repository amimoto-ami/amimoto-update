#!/bin/bash -x

TMP_JSON=$(mktemp)
AMIMOTO_JSON='/opt/local/amimoto.json'
git -C /opt/local/chef-repo/cookbooks/amimoto/ pull origin 2016.01
jq '.phpfpm = "72"' /opt/local/amimoto.json > ${TMP_JSON}
mv -f ${TMP_JSON} /opt/local/amimoto.json
