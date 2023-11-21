ys_downloaddir="/root/pkgs/sources"
yum install centos-release-openstack-queens -y
yum install --downloadonly --downloaddir=${ys_downloaddir} python-openstackclient python2-qpid-proton-0.22.0-1.el7.x86_64 qpid-proton-c-0.22.0-1.el7.x86_64 -y
yum install --downloadonly --downloaddir=${ys_downloaddir} python3-openstackclient -y
yum install --downloadonly --downloaddir=${ys_downloaddir} openstack-selinux -y
yum install --downloadonly --downloaddir=${ys_downloaddir} openstack-neutron-linuxbridge openstack-neutron-openvswitch ebtables ipset -y
yum install --downloadonly --downloaddir=${ys_downloaddir} openstack-cinder -y
yum install --downloadonly --downloaddir=${ys_downloaddir} openstack-dashboard -y
yum install --downloadonly --downloaddir=${ys_downloaddir} mariadb mariadb-server python2-PyMySQL -y
yum install --downloadonly --downloaddir=${ys_downloaddir} openstack-glance python2-qpid-proton-0.22.0-1.el7.x86_64 qpid-proton-c-0.22.0-1.el7.x86_64 -y
yum install --downloadonly --downloaddir=${ys_downloaddir} openstack-keystone httpd mod_wsgi -y
yum install --downloadonly --downloaddir=${ys_downloaddir} memcached python-memcached -y
yum install --downloadonly --downloaddir=${ys_downloaddir} memcached python3-memcached -y
yum install --downloadonly --downloaddir=${ys_downloaddir} openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge openstack-neutron-openvswitch ebtables -y
yum install --downloadonly --downloaddir=${ys_downloaddir} openstack-nova-api openstack-nova-conductor  openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler openstack-nova-placement-api -y
yum install --downloadonly --downloaddir=${ys_downloaddir} chrony -y
yum install --downloadonly --downloaddir=${ys_downloaddir} rabbitmq-server -y
yum install --downloadonly --downloaddir=${ys_downloaddir} lvm2 device-mapper-persistent-data -y
yum install --downloadonly --downloaddir=${ys_downloaddir} openstack-cinder targetcli python-keystone python2-qpid-proton-0.22.0-1.el7.x86_64 qpid-proton-c-0.22.0-1.el7.x86_64 -y

