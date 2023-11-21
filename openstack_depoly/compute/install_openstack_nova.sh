set -x
controller=""
manager_net_dev=""

while [ -n "$1" ]
do
	case "$1" in
       --manager_net_dev)
			array[${#array[*]}]=$1;array[${#array[*]}]=$2;manager_net_dev=$2;shift;shift;continue
            ;;
		--controller)
			array[${#array[*]}]=$1;array[${#array[*]}]=$2;controller=$2;shift;shift;continue
			;;
		*)
			array[${#array[*]}]=$1;shift;continue
			;;
	esac
done

mkdir -p origin
manager_ip=$( ip addr show ${manager_net_dev}|grep inet|grep -v inet6|awk '{split($2, ip, "/"); print ip[1]}')

yum install openstack-nova-compute python2-qpid-proton-0.22.0-1.el7.x86_64 qpid-proton-c-0.22.0-1.el7.x86_64 -y
sleep 3

if [ ! -e origin/nova.conf.origin ];then
    cp /etc/nova/nova.conf origin/nova.conf.origin
fi
buffer=$(sed -e "s/<controller>/${controller}/g" -e "s/<my_ip>/${manager_ip}/g" config/nova.conf )
cat <<EOF > /etc/nova/nova.conf
${buffer}
EOF

systemctl enable libvirtd.service
systemctl enable openstack-nova-compute.service
systemctl start libvirtd.service
systemctl start openstack-nova-compute.service

su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova

source ./openrc
openstack compute service list

echo "install nova finish on ${manager_ip}"
