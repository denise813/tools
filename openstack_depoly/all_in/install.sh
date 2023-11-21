set -x

worker_space=""
current_dir=$(cd $(dirname $0); pwd)
worker_space="${current_dir}/.."

source ${worker_space}/config/config

controller_ip=192.168.110.4
manager_net_nodes=192.168.110.1/24
dis_ver=${ys_dis_ver}
os_name=${ys_os_name}
manager_net_dev=${ys_manager_net_dev}
public_net_dev=${ys_public_net_dev}
private_net_dev=${ys_private_net_dev}

if [ $controller_ip == "" ]; then
    exit -1
fi
if [ $manager_net_nodes == "" ]; then
    exit -1
fi
if [ $dis_ver == "" ]; then
    exit -1
fi
if [ $os_name == "" ]; then
    exit -1
fi
if [ $manager_net_dev == "" ]; then
    exit -1
fi
if [ $public_net_dev == "" ]; then
    exit -1
fi
if [ $private_net_dev == "" ]; then
    exit -1
fi

enable_controller="false"
enable_compute="false"
enable_storage="false"
enable_client="false"
mkdir -p origin
if [ ${enable_controller} == "true" ]; then
sh ${worker_space}/base/get_openstack_rc.sh --controller ${controller_ip}
sh ${worker_space}/base/install_openstack_pkg.sh --dis ${dis_ver} --os ${os_name}
sh ${worker_space}/controller/install_openstack_ntp.sh --controller ${controller_ip} --net ${manager_net_nodes}
sh ${worker_space}/controller/install_openstack_memcached.sh --controller ${controller_ip} --os ${os_name}
sleep 5
sh ${worker_space}/controller/install_openstack_db.sh --controller ${controller_ip}
sleep 5
sh ${worker_space}/controller/install_openstack_rabbitmq.sh

rabbitmqctl list_users
netstat -ntlp  | grep 5672

sh ${worker_space}/controller/install_openstack_keystone.sh --controller ${controller_ip}
source ./openrc
openstack token issue
sh ${worker_space}/controller/install_openstack_glance.sh     --controller ${controller_ip}
sh ${worker_space}/controller/install_openstack_nova.sh       --controller ${controller_ip}
sh install_openstack_networking.sh --controller ${controller_ip} \
    --manager_net_dev ${manager_net_dev} \
    --public_net_dev ${public_net_dev} \
    --private_net_dev ${private_net_dev}
sh ${worker_space}/controller/install_openstack_cinder.sh     --controller ${controller_ip}
sh ${worker_space}/controller/install_openstack_dashboard.sh  --controller ${controller_ip}
fi

if [ ${enable_compute} == "true" ]; then
sh ${worker_space}/compute/install_openstack_nova.sh --controller ${controller_ip} \
    --manager_net_dev ${manager_net_dev}
sh ${worker_space}/compute/install_openstack_networking.sh --controller ${controller_ip} \
    --manager_net_dev ${manager_net_dev} \
    --public_net_dev ${public_net_dev} \
    --private_net_dev ${private_net_dev}
fi

if [ ${enable_storage} == "true" ]; then
sh install_disk.sh --controller ${controller_ip}--blockdev ${block_dev}
sh install_openstack_cinder.sh --controller ${controller_ip} \
    --manager_net_dev ${manager_net_dev}
fi

sleep 10
if [ ${enable_client} == "true" ]; then
echo "===================================================================================="
source ./openrc
openstack token issue
#cinder type-list
nova-status upgrade check
openstack catalog list
openstack compute service list
openstack network agent list
sleep 3
openstack flavor list
openstack image list
openstack network list
openstack subnet list
openstack router list
openstack keypair list
openstack security group rule list

openstack image create "cirros" --file ${worker_space}/client/images/cirros-0.4.0-x86_64-disk.img --disk-format qcow2 \
	       --container-format bare --public
openstack image create "centos7" --file ${worker_space}/client/images/CentOS-7-x86_64-Minimal-2009.iso \
		--disk-format iso --container-format bare --public
openstack image create "CentOS-7-x86_64-GenericCloud-2009-changed" \
		--file ${worker_space}/client/images/CentOS-7-x86_64-GenericCloud-2009.qcow2.changed \
			--disk-format qcow2 --container-format bare --public

openstack network create --share --external \
		--provider-physical-network public \
			--provider-network-type flat demo_public
openstack subnet create --network demo_public --no-dhcp \
		--allocation-pool start=${public_start_ip},end=${public_end_ip} \
			--gateway ${public_gateway} --dns-nameserver ${public_dns} \
				--subnet-range ${public_network} public

openstack network create demo_private
openstack subnet create --network demo_private \
		--dns-nameserver ${private_dns} --gateway ${private_gateway} \
			--subnet-range ${private_network} private

openstack keypair create --public-key ~/.ssh/id_rsa.pub demo_key
openstack security group create demo
openstack security group rule create --proto icmp demo
openstack security group rule create --proto tcp --dst-port 22 demo
openstack flavor create --vcpus 1 --ram 64 --disk 1 demo.nano
openstack flavor create --vcpus 1 --ram 4096 --disk 10 demo.medium

cinder type-create lvm
cinder type-key lvm set volume_backend_name=LVM
#openstack volume create --size 1 demo_volume_01
cinder extra-specs-list
openstack image list
openstack network list
openstack volume list
openstack keypair list
openstack security group rule list
fi
echo "install finish all on"
