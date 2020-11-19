yum install httpd createrepo -y
mkdir -p /var/www/html/ceph
cd /var/www/html/ceph/

#cp /root/cephadm-15.2.5-0.el8.x86_64.rpm ./
createrepo -v /var/www/html/ceph/
systemctl start httpd.service
cp ./ceph.repo /etc/yum.repos.d/
yum list

#yum install cephadm
