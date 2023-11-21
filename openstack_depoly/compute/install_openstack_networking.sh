set -x
controller=""
manager_net_dev=""
public_net_dev=""
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
			array[${#array[*]}]=$1;array[${#array[*]}]=$2;controller_ip=$2;shift;shift;continue
			;;
		*)
			array[${#array[*]}]=$1;shift;continue
			;;
	esac
done

yum install openstack-neutron-linuxbridge openstack-neutron-openvswitch ebtables ipset -y


mkdir -p origin

manager_ip=$( ip addr show ${manager_net_dev}|grep inet|grep -v inet6|awk '{split($2, ip, "/"); print ip[1]}')
public_ip=$( ip addr show ${public_net_dev}|grep inet|grep -v inet6|awk '{split($2, ip, "/"); print ip[1]}')
private_ip=$( ip addr show ${private_net_dev}|grep inet|grep -v inet6|awk '{split($2, ip, "/"); print ip[1]}')

if [ ! -e origin/neutron.conf.origin ]; then
    cp /etc/neutron/neutron.conf origin/neutron.conf.origin
fi
buffer=$(sed "s/<controller>/${controller_ip}/g" config/neutron.conf )
cat <<EOF > /etc/neutron/neutron.conf
${buffer}
EOF

if [ ! -e origin/linuxbridge_agent.ini.origin ]; then
    cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini origin/linuxbridge_agent.ini.origin
fi
buffer=$(sed -e "s/<net_dev>/${public_net_dev}/g" -e "s/<local_ip>/${private_ip}/g" config/linuxbridge_agent.ini )
cat <<EOF > /etc/neutron/plugins/ml2/linuxbridge_agent.ini
${buffer}
EOF
# net.bridge.bridge-nf-call-iptables = 1
# net.bridge.bridge-nf-call-ip6tables = 1

#agent_type="openvswitch"
agent_type="linuxbridge"

if [ ${agent_type} == "openvswitch" ];then
    systemctl enable openvswitch
    systemctl start openvswitch
    systemctl status openvswitch
fi

buffer=$(sed "s/\[neutron\]/"#"/g" /etc/nova/nova.conf )
cat <<EOF > /etc/nova/nova.conf
${buffer}

[neutron]
auth_url = http://${controller_ip}:9696
auth_url = http://${controller_ip}:35357
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

systemctl restart openstack-nova-compute.service
if [ ${agent_type} == "openvswitch" ];then
    systemctl enable neutron-openvswitch-agent.service
    systemctl start neutron-openvswitch-agent.service
    ovs-vsctl show
else
    systemctl enable neutron-linuxbridge-agent.service
    systemctl start neutron-linuxbridge-agent.service
fi

echo "install networking finish on ${manager_ip}"
