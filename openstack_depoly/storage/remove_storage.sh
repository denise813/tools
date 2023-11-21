
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


yum remove python-openstackclient python2-qpid-proton qpid-proton-c -y
yum remove openstack-cinder targetcli -y
rm -rf /etc/cinder
rm -rf /var/log/cinder

systemctl stop lvm2-lvmetad.service
vgremove cinder-volumes -f
pvremove /dev/${block_dev}

yum remove lvm2 device-mapper-persistent-data -y

