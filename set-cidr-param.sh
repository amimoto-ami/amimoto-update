#!/bin/bash
set -eu

hash jq || yum -y install jq
cidr=$(curl -L -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -L -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/)subnet-ipv4-cidr-block)
tmpfile=`mktemp`
tmpfile2=`mktemp`
json='/opt/local/amimoto.json'
if [ -f /opt/local/amimoto-managed.json ]; then
  json='/opt/local/amimoto-managed.json'
fi

echo "{\"nginx\":{\"config\":{\"vpc_ips\":[\"${cidr}\"]}}}" > $tmpfile
jq -s '.[0] * .[1]' $tmpfile $json > $tmpfile2
cat $tmpfile2 > $json

rm -f $tmpfile
rm -f $tmpfile2
