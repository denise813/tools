
rm -rf /var/www/html/ceph
rm -rf /var/www/html/repo/centos8/ceph.repo
rm -rf /etc/yum.repos.d/ceph.repo

yum install httpd createrepo wget -y
rm -rf /var/www/html/ceph
rm -rf /root/package
mkdir -p /var/www/html/ceph
mkdir -p /var/www/html/repo/centos8
mkdir -p /root/package

systemctl stop httpd.service

cp /root/rpmbuild/RPMS/*/* /root/package/

cp /root/package/* /var/www/html/ceph/

cd /var/www/html/ceph/
createrepo -v /var/www/html/ceph/

systemctl start httpd.service

systemctl stop firewalld.service
mirror_node=$(/sbin/ifconfig eno1 | awk '/inet/ {print $2}' | cut -f2 -d ":" |awk 'NR==1 {print $1}')

cat >> /var/www/html/repo/centos8/ceph.repo <<EOF
[ceph]
name=ceph
baseurl=http://${mirror_node}/ceph/
enabled=1
gpgcheck=0
priority=1
EOF

#wget -P /etc/yum.repos.d/ http://${mirror_node}/repo/centos8/ceph.repo
#yum clean all
#yum makecache

