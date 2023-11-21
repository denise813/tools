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
block_dev=${ys_storage_file_dev}
#############################################
mkdir -p origin
sh get_openstack_rc.sh  --controller ${controller_ip}
sh install_openstack_pkg.sh --dis ${dis_ver} --os ${os_name}
source ./openrc
sh install_disk.sh --controller ${controller_ip}--blockdev ${block_dev}
sleep 3
sh install_openstack_cinder.sh --controller ${controller_ip} \
    --manager_net_dev ${manager_net_dev}
sleep 3
cinder service-list
openstack volume service list
