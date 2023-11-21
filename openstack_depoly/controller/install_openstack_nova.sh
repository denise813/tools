set -x

controller="192.168.100.150"

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

##################################################
local_host_name=$(hostname)
mysql -h ${controller} -u root -e "DROP DATABASE nova_api;"
mysql -h ${controller} -u root -e "DROP DATABASE nova;"
mysql -h ${controller} -u root -e "DROP DATABASE nova_cell0;"

mysql -h ${controller} -u root -e "CREATE DATABASE nova_api;"
mysql -h ${controller} -u root -e "CREATE DATABASE nova;"
mysql -h ${controller} -u root -e "CREATE DATABASE nova_cell0;"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'NOVA_DBPASS';"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'${controller}' IDENTIFIED BY 'NOVA_DBPASS';"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'${local_host_name}' IDENTIFIED BY 'NOVA_DBPASS';"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';"

mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'NOVA_DBPASS';"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'${controller}' IDENTIFIED BY 'NOVA_DBPASS';"

mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'${local_host_name}' IDENTIFIED BY 'NOVA_DBPASS';"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';"

mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY 'NOVA_DBPASS';"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'${controller}' IDENTIFIED BY 'NOVA_DBPASS';"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'${local_host_name}' IDENTIFIED BY 'NOVA_DBPASS';"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';"

openstack token issue
openstack user create --domain default --password NOVA_PASS nova
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne  compute public http://${controller}:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://${controller}:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://${controller}:8774/v2.1

openstack user create --domain default --password PLACEMENT_PASS placement
openstack role add --project service --user placement admin
openstack service create --name placement --description "Placement API" placement
openstack endpoint create --region RegionOne placement public http://${controller}:8778
openstack endpoint create --region RegionOne placement internal http://${controller}:8778
openstack endpoint create --region RegionOne placement admin http://${controller}:8778

yum install openstack-nova-api openstack-nova-conductor  openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler openstack-nova-placement-api -y

mkdir -p origin
if [ ! -e origin/nova.conf.origin ]; then
    cp /etc/nova/nova.conf origin/nova.conf.origin
fi
buffer=$(sed -e "s/<controller>/${controller}/g" -e "s/<my_ip>/${controller}/g" config/nova.conf )
cat <<EOF > /etc/nova/nova.conf
${buffer}

EOF
su -s /bin/sh -c "nova-manage api_db sync" nova


if [ ! -e origin/00-nova-placement-api.conf.origin ]; then
    cp /etc/httpd/conf.d/00-nova-placement-api.conf origin/00-nova-placement-api.conf.origin
fi
cp config/00-nova-placement-api.conf /etc/httpd/conf.d/00-nova-placement-api.conf
su -s /bin/sh -c "nova-manage api_db sync" nova

systemctl restart httpd
su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
#su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova
su -s /bin/sh -c "nova-manage db sync" nova

nova-manage cell_v2 list_cells
systemctl enable openstack-nova-api.service 
systemctl enable openstack-nova-consoleauth.service
systemctl enable openstack-nova-scheduler.service 
systemctl enable openstack-nova-conductor.service
systemctl enable openstack-nova-novncproxy.service

systemctl start openstack-nova-api.service 
systemctl start openstack-nova-consoleauth.service
systemctl start openstack-nova-scheduler.service 
systemctl start openstack-nova-conductor.service
systemctl start openstack-nova-novncproxy.service

source ./openrc
openstack compute service list

echo "install finish nova on ${controller}"
