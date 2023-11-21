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

manager_ip=$( ip addr show ${manager_net_dev}|grep inet|grep -v inet6|awk '{split($2, ip, "/"); print ip[1]}')

#############################################
#yum install lvm2 device-mapper-persistent-data -y
#systemctl enable lvm2-lvmetad.service
#systemctl start lvm2-lvmetad.service
systemctl restart lvm2-lvmetad.service
yum install openstack-cinder targetcli python-keystone python2-qpid-proton-0.22.0-1.el7.x86_64 qpid-proton-c-0.22.0-1.el7.x86_64 -y


if [ -e origin/cinder.conf.origin ];then
    cp /etc/cinder/cinder.conf cinder.conf.origin
fi
buffer=$(sed -e "s/<controller>/${controller}/g" -e "s/<my_ip>/${manager_ip}/g" config/cinder.conf)
cat <<EOF > /etc/cinder/cinder.conf
${buffer}
EOF

systemctl enable openstack-cinder-volume.service
systemctl start openstack-cinder-volume.service

echo "install cinder finish"

