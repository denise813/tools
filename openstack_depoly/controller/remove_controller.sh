set -x
controller_ip="192.168.100.150"
net_nodes="192.168.100.0/24"
dis_ver='queens'
os_name="centos7"

current_dir=$(cd $(dirname $0); pwd)
worker_space="${current_dir}/.."
source ${worker_space}/config/config

controller_ip=${ys_controller_ip}
net_nodes=${ys_controller_ip}
dis_ver=${ys_dis_ver}
os_name=${ys_os_name}

systemctl stop openvswitch
systemctl disable openvswitch
#ovs-vsctl add-br br-provider
#ovs-vsctl add-port br-provider ${net_dev}
#ovs-vsctl show

systemctl stop neutron-server.service
systemctl stop neutron-dhcp-agent.service
systemctl stop neutron-metadata-agent.service
systemctl stop neutron-linuxbridge-agent.service

yum remove openstack-dashboard -y
rm -rf /etc/openstack-dashboard
rm -rf /etc/httpd/conf.d/openstack-dashboard.conf
rm -rf /usr/share/openstack-dashboard

yum remove openstack-cinder -y
rm -rf /etc/cinder
rm -rf /var/log/cinder
rm -rf /var/lib/cinder



yum remove openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge openstack-neutron-openvswitch openvswitch ebtables -y
rm -rf rf /etc/neutron
rm -rf /var/log/neutron
rm -rf /var/lib/neutron

yum remove openstack-nova-api openstack-nova-conductor python36-websockify openstack-nova-console novnc python-websockify openstack-nova-novncproxy openstack-nova-scheduler openstack-nova-placement-api -y
rm -rf /var/log/nova
rm -rf /etc/nova
rm -rf /var/lib/nova

yum remove openstack-glance -y
rm -rf /etc/glance
rm -rf /var/log/glance
rm -rf /var/lib/glance

yum remove openstack-keystone httpd mod_wsgi -y
rm -rf /etc/keystone
rm -rf /etc/httpd
rm -rf /usr/share/keystone
rm -rf /var/log/keystone
rm -rf /var/log/httpd
rm -tf /var/lib/keystone
rm -rf /var/run/httpd

yum remove chrony -y
rm -rf /etc/chrony.conf

yum remove rabbitmq-server -y

yum remove mariadb mariadb-server python2-PyMySQL -y
rm -rf /var/lib/mysql
rm -rf /etc/my.cnf.d
if [ ${os_name} == "centos7" ]; then
    yum remove memcached python-memcached -y
elif [ ${os_name} == "cnetos8" ]; then
    yum remove memcached python3-memcached -y
else
   exit 22
fi
rm -rf /etc/sysconfig/memcached


sh ${worker_space}/base/remove_openstack_pkg.sh --dis ${dis_ver} --os ${os_name}
