#!/bin/bash
yum -y update
yum -y install --disablerepo=amzn-main --enablerepo=epel libwebp

hash jq || yum -y install jq
hash git || yum -y install git

[ ! -e /opt/local ] && mkdir -p /opt/local
cd /opt/local
[ -e /opt/local/chef-repo ] && rm -rf /opt/local/chef-repo
git clone git://github.com/opscode/chef-repo.git
cd /opt/local/chef-repo/cookbooks/
git clone git://github.com/Launch-with-1-Click/lw1-amimoto.git amimoto

cd /opt/local
[ ! -f /opt/local/solo.rb ] && echo 'file_cache_path "/tmp/chef-solo"
cookbook_path ["/opt/local/chef-repo/cookbooks"]' > /opt/local/solo.rb
[ ! -f /opt/local/amimoto.json ] && cp /opt/local/chef-repo/cookbooks/amimoto/amimoto.json /opt/local/amimoto.json

curl -L http://www.opscode.com/chef/install.sh | bash

echo '#!/bin/bash
/sbin/service monit stop
[ -f /usr/bin/python2.7 ] && /usr/sbin/alternatives --set python /usr/bin/python2.7
/opt/chef/bin/chef-solo -c /opt/local/solo.rb -j /opt/local/amimoto.json -l error' > /opt/local/provision
if [ -f /opt/local/amimoto-managed.json ]; then
  sed -i -e 's/amimoto.json/amimoto-managed.json/g' /opt/local/provision
fi
chmod +x /opt/local/provision

rm -f /usr/bin/wp; rm -f /usr/local/bin/wp; rm -rf /usr/share/wp-cli/

service monit stop; service php-fpm stop; service mysql stop
yum remove -y php php54-* php55-* php56-* php-* Percona-* httpd*
[ -f /usr/bin/python2.7 ] && /usr/sbin/alternatives --set python /usr/bin/python2.7
if [ ! -f /opt/local/amimoto-managed.json ]; then
  chef-solo -c /opt/local/solo.rb -j /opt/local/amimoto.json -l error
else
  chef-solo -c /opt/local/solo.rb -j /opt/local/amimoto-managed.json -l error
fi
yum -y update
/opt/local/provision

mysql_upgrade -u root
curl -L -s http://bugs.mysql.com/file.php?id=19725\&bug_id=67179\&text=1 > innodb_stats_fix.sql
#mysql -u root mysql < innodb_stats_fix.sql
service monit stop; service mysql restart; service monit start