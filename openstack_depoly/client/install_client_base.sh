set -x

worker_space=""
current_dir=$(cd $(dirname $0); pwd)
worker_space="${current_dir}/.."

source ${worker_space}/config/config

controller_ip=${ys_controller_ip}
manager_net_nodes=${ys_manager_net_nodes}
dis_ver=${ys_dis_ver}
os_name=${ys_os_name}
public_start_ip=${ys_public_start_ip}
public_end_ip=${ys_public_start_ip}
public_gateway=${ys_public_gateway}
public_network=${ys_public_network}
public_dns=${ys_public_dns}
private_gateway=${ys_private_gateway}
private_network=${ys_private_network}
private_dns=${ys_private_dns}

sh ${worker_space}/base/get_openstack_rc.sh --controller ${controller_ip}

#sh ${worker_space}/base/install_openstack_pkg.sh --dis ${dis_ver} --os ${os_name}

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

openstack image create "cirros" --file ./images/cirros-0.4.0-x86_64-disk.img --disk-format qcow2 \
       --container-format bare --public
openstack image create "centos7" --file ./images/CentOS-7-x86_64-Minimal-2009.iso \
	--disk-format iso --container-format bare --public
openstack image create "CentOS-7-x86_64-GenericCloud-2009-changed" \
	--file ./images/CentOS-7-x86_64-GenericCloud-2009.qcow2.changed \
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

#openstack server create --flavor demo_m1.nano --image cirros --nic net-id=SELFSERVICE_NET_ID --security-group default --key-name demo_key demo_001

#openstack server add volume 8cc07bf6-31d2-4a1b-8d9b-fea9a7cc6e84 897e6798-555f-46e8-b846-18fc153391b2
#openstack console url show c519b863-1205-4184-8256-ce4c21ca99d7
