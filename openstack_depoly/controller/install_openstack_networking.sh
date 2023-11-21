set -x

controller=""
manager_net_dev=""
pubic_net_dev=""
private_net_dev=""
while [ -n "$1" ]
do
    case "$1" in
        --manager_net_dev)
          array[${#array[*]}]=$1;array[${#array[*]}]=$2;manager_net_dev=$2;shift;shift;continue
            ;;
        --public_net_dev)
          array[${#array[*]}]=$1;array[${#array[*]}]=$2;public_net_dev=$2;shift;shift;continue
            ;;
        --private_net_dev)
          array[${#array[*]}]=$1;array[${#array[*]}]=$2;private_net_dev=$2;shift;shift;continue
            ;;
        --controller)
            array[${#array[*]}]=$1;array[${#array[*]}]=$2;controller=$2;shift;shift;continue
            ;;
        *)
          array[${#array[*]}]=$1;shift;continue
            ;;
    esac
done

manager_ip=$( ip addr show ${manager_net_dev}|grep inet|grep -v inet6|awk '{split($2, ip, "/"); print ip[1]}')
public_ip=$( ip addr show ${public_net_dev}|grep inet|grep -v inet6|awk '{split($2, ip, "/"); print ip[1]}')
private_ip=$( ip addr show ${private_net_dev}|grep inet|grep -v inet6|awk '{split($2, ip, "/"); print ip[1]}')
local_host_name=$(hostname)


mysql -h ${controller} -u root -e "DROP DATABASE neutron;"

mysql -h ${controller} -u root -e "CREATE DATABASE neutron;"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'NEUTRON_DBPASS';"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'${controller}' IDENTIFIED BY 'NEUTRON_DBPASS';"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'${local_host_name}' IDENTIFIED BY 'NEUTRON_DBPASS';"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'lt01' IDENTIFIED BY 'NEUTRON_DBPASS';"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'NEUTRON_DBPASS';"

source ./openrc

openstack token issue
openstack user create --domain default --password NEUTRON_PASS neutron
openstack role add --project service --user neutron  admin
openstack service create --name neutron --description "OpenStack Networking" network

openstack endpoint create --region RegionOne network public http://${controller}:9696
openstack endpoint create --region RegionOne network internal http://${controller}:9696
openstack endpoint create --region RegionOne network admin http://${controller}:9696


yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge openstack-neutron-openvswitch ebtables -y

mkdir -p origin
sysctl -w "net.ipv4.ip_forward=1"
sysctl -w "net.bridge.bridge-nf-call-iptables=1"
cp /etc/sysctl.conf origin/sysctl.conf 
cp config/sysctl.conf /etc/sysctl.conf 
net_dev="ens192"
#agent_type="openvswitch"
agent_type="linuxbridge"

if [ ${agent_type}  == "openvswitch" ]; then
    if [ ! -e origin/openvswitch_agent.ini.origin ]; then
        cp /etc/neutron/plugins/ml2/openvswitch_agent.ini origin/openvswitch_agent.ini.origin
    fi
    buffer=$(sed -e "s/<net_dev>/${public_net_dev}/g" -e "s/<local_ip>/${private_ip}/g" config/openvswitch_agent.ini )
cat <<EOF > /etc/neutron/plugins/ml2/openvswitch_agent.ini
${buffer}
EOF
fi

if [ ${agent_type}  == "linuxbridge" ]; then
    if [ ! -e origin/linuxbridge_agent.ini.origin ]; then
        cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini origin/linuxbridge_agent.ini.origin
    fi
    buffer=$(sed -e "s/<net_dev>/${public_net_dev}/g" -e "s/<local_ip>/${private_ip}/g" config/linuxbridge_agent.ini )
cat <<EOF > /etc/neutron/plugins/ml2/linuxbridge_agent.ini
${buffer}
EOF
fi

if [ ! -e origin/neutron.conf.origin ]; then
    cp /etc/neutron/neutron.conf origin/neutron.conf.origin
fi
buffer=$(sed "s/<controller>/${controller}/g" config/neutron.conf )
cat <<EOF > /etc/neutron/neutron.conf
${buffer}
EOF

if [ ! -e origin/ml2_conf.ini.origin ]; then
    cp /etc/neutron/plugins/ml2/ml2_conf.ini origin/ml2_conf.ini.origin
fi
buffer=$(sed -e "s/<dirver_type>/${agent_type}/g" config/ml2_conf.ini )
cat <<EOF > /etc/neutron/plugins/ml2/ml2_conf.ini
${buffer}
EOF
if [ ! -e origin/l3_agent.ini.origin ]; then
    cp /etc/neutron/l3_agent.ini origin/l3_agent.ini.origin
fi
buffer=$(sed -e "s/<dirver_type>/${agent_type}/g" config/l3_agent.ini )
cat <<EOF > /etc/neutron/l3_agent.ini
${buffer}
EOF

if [ ! -e origin/dhcp_agent.ini.origin ]; then
    cp /etc/neutron/dhcp_agent.ini origin/dhcp_agent.ini.origin
fi
buffer=$(sed -e "s/<dirver_type>/${agent_type}/g" config/dhcp_agent.ini )
cat <<EOF > /etc/neutron/dhcp_agent.ini
${buffer}
EOF

if [ ! -e origin/metadata_agent.ini.origin ]; then
    cp /etc/neutron/metadata_agent.ini origin/metadata_agent.ini.origin
fi
buffer=$(sed "s/<controller>/${controller}/g" config/metadata_agent.ini )
cat <<EOF > /etc/neutron/metadata_agent.ini
${buffer}
EOF

buffer=$(sed "s/\[neutron\]/"#"/g" /etc/nova/nova.conf )
cat <<EOF > /etc/nova/nova.conf
${buffer}

[neutron]
auth_url = http://${controller}:9696
auth_url = http://${controller}:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = NEUTRON_PASS
service_metadata_proxy = true
metadata_proxy_shared_secret = METADATA_SECRET
EOF

ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
systemctl restart openstack-nova-api.service

systemctl enable neutron-server.service 
systemctl enable neutron-dhcp-agent.service
systemctl enable neutron-metadata-agent.service
systemctl enable neutron-l3-agent.service
if [ ${agent_type}  == "openvswitch" ]; then
    systemctl enable openvswitch
    systemctl start openvswitch
    ovs-vsctl add-br br-provider
    ovs-vsctl add-port br-provider ${ext_net_dev}
    ovs-vsctl show
    systemctl enable neutron-openvswitch.service
fi

if [ ${agent_type}  == "linuxbridge" ]; then
    systemctl enable neutron-linuxbridge-agent.service
fi

systemctl start neutron-server.service
systemctl start neutron-dhcp-agent.service
systemctl start neutron-metadata-agent.service
systemctl start neutron-l3-agent.service
if [ ${agent_type}  == "openvswitch" ]; then
    systemctl start neutron-openvswitch.service
fi

if [ ${agent_type}  == "linuxbridge" ]; then
    systemctl start neutron-linuxbridge-agent.service
fi

source ./openrc

echo "install finish networking"

