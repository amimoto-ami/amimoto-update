#!/bin/bash -x
AMIMOTO_JSON='/opt/local/amimoto.json'
[ -f /opt/local/amimoto-managed.json ] && \
  AMIMOTO_JSON='/opt/local/amimoto-managed.json'

: update packages
/usr/bin/yum clean all
/bin/rm -f /etc/yum.repos.d/amimoto-nginx-mainline.repo*
/bin/rm -f /etc/yum.repos.d/opsrock-*.repo*
/bin/rm -f /etc/yum.repos.d/hop5.repo
/bin/rm -f /etc/yum.repos.d/remi*.repo*
/bin/rm -f /etc/yum.repos.d/Percona.repo*
/bin/rm -f /etc/yum.repos.d/percona-release.repo*
/bin/rm -f /etc/yum.repos.d/*.rpmsave
/bin/rm -rf /usr/share/phpMyAdmin*
/bin/rpm --rebuilddb
/usr/bin/yum -y update
/usr/bin/yum -y install --disablerepo=amzn-main --enablerepo=epel libwebp --skip-broken

hash wget || /usr/bin/yum -y install wget
hash jq   || /usr/bin/yum -y install jq
hash git  || /usr/bin/yum -y install git

: update chef-solo recipes
[ ! -e /opt/local ] && \
  mkdir -p /opt/local
[ -e /opt/local/chef-repo ] && \
  rm -rf /opt/local/chef-repo
cd /opt/local
/usr/bin/git clone git://github.com/opscode/chef-repo.git
cd /opt/local/chef-repo/cookbooks/
/usr/bin/git clone git://github.com/Launch-with-1-Click/lw1-amimoto.git amimoto

cd /opt/local
[ ! -f /opt/local/solo.rb ] && \
  echo 'file_cache_path "/tmp/chef-solo"
cookbook_path ["/opt/local/chef-repo/cookbooks"]' > /opt/local/solo.rb
[ ! -f /opt/local/amimoto.json ] && \
  cp /opt/local/chef-repo/cookbooks/amimoto/amimoto.json /opt/local/amimoto.json

: install chef-solo
/usr/bin/curl -L -s http://www.opscode.com/chef/install.sh | /bin/bash

echo "#!/bin/bash
/sbin/service monit stop
[ -f /usr/bin/python2.7 ] && /usr/sbin/alternatives --set python /usr/bin/python2.7
/usr/bin/git -C /opt/local/chef-repo/cookbooks/amimoto pull origin 2016.01
/opt/chef/bin/chef-solo -c /opt/local/solo.rb -j ${AMIMOTO_JSON} -l error" > /opt/local/provision
chmod +x /opt/local/provision

: remove old wp-cli
rm -f /usr/bin/wp; rm -f /usr/local/bin/wp; rm -rf /usr/share/wp-cli/

: update Nginx, PHP, MySQL...
/sbin/service monit stop
/sbin/service php-fpm stop
/sbin/service mysql stop
/usr/bin/yum remove -y php php54-* php55-* php56-* php-* Percona-* httpd* hhvm* nginx nginx-*
[ -f /usr/bin/python2.7 ] && \
  /usr/sbin/alternatives --set python /usr/bin/python2.7
/opt/chef/bin/chef-solo -c /opt/local/solo.rb -j ${AMIMOTO_JSON} -l error
/usr/bin/yum -y update
/opt/local/provision

: upgrade MySQL DB
/usr/bin/mysql_upgrade -u root
#/usr/bin/curl -L -s http://bugs.mysql.com/file.php?id=19725\&bug_id=67179\&text=1 > innodb_stats_fix.sql
#/usr/bin/mysql -u root mysql < innodb_stats_fix.sql

: service restart
/sbin/service monit stop
/sbin/service nginx restart
/sbin/service mysql restart
/sbin/service php-fpm restart
/sbin/service monit start

cat /etc/motd
