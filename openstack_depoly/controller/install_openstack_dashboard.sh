set -x
controller=""

while [ -n "$1" ]
do
	case "$1" in
		--controller)
			array[${#array[*]}]=$1;array[${#array[*]}]=$2;controller=$2;shift;shift;continue
			;;
		*)
			array[${#array[*]}]=$1;shift;continue
			;;
	esac
done

yum install openstack-dashboard -y

if [ ! -e origin/local_settings.conf.origin ];then
    cp /etc/openstack-dashboard/local_settings origin/local_settings.conf.origin
fi
buffer=$(sed "s/<controller>/${controller}/g" config/local_settings)
cat <<EOF > /etc/openstack-dashboard/local_settings
${buffer}

EOF

if [ -e origin/openstack-dashboard.conf.origin ];then
    cp /etc/httpd/conf.d/openstack-dashboard.conf origin/openstack-dashboard.conf.origin
fi
cp config/openstack-dashboard.conf /etc/httpd/conf.d/openstack-dashboard.conf

systemctl restart httpd.service
systemctl restart memcached.service

source ./openrc

echo "install finish dashboard on ${controller}"
