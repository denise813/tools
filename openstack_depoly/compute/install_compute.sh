
worker_space=""
current_dir=$(cd $(dirname $0); pwd)
worker_space="${current_dir}/.."

source ${worker_space}/config/config


controller_ip=${ys_controller_ip}
manager_net_nodes=${ys_manager_net_nodes}
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

mkdir -p origin
sh ${worker_space}/base/get_openstack_rc.sh --controller ${controller_ip}
source ./openrc

sh ${worker_space}/base/install_openstack_pkg.sh --dis ${dis_ver} --os ${os_name}
sh ${worker_space}/compute/install_openstack_nova.sh --controller ${controller_ip} \
    --manager_net_dev ${manager_net_dev}
sh ${worker_space}/compute/install_openstack_networking.sh --controller ${controller_ip} \
    --manager_net_dev ${manager_net_dev} \
    --public_net_dev ${public_net_dev} \
    --private_net_dev ${private_net_dev}

sleep 5
nova service-list
openstack network agent list
