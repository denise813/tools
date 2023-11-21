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

#############################################
local_host_name=$(hostname)
mysql -h ${controller} -u root -e "DROP DATABASE cinder;"
mysql -h ${controller} -u root -e "CREATE DATABASE cinder;"

mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'CINDER_DBPASS';"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'${controller}' IDENTIFIED BY 'CINDER_DBPASS';"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'${local_host_name}' IDENTIFIED BY 'CINDER_DBPASS';"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'CINDER_DBPASS';"

openstack user create --domain default --password  CINDER_PASS cinder
openstack role add --project service --user cinder admin
openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3
openstack endpoint create --region RegionOne volumev2 public http://${controller}:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev2 internal http://${controller}:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev2 admin http://${controller}:8776/v2/%\(project_id\)s

openstack endpoint create --region RegionOne volumev3 public http://${controller}:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 internal http://${controller}:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 admin http://${controller}:8776/v3/%\(project_id\)s

yum install openstack-cinder -y

mkdir -p origin

if [ -e origin/cinder.origin ];then
    cp /etc/glance/cinder.conf cinder.conf.origin
fi

buffer=$(sed -e "s/<controller>/${controller}/g" -e "s/<my_ip>/${controller}/g" config/cinder.conf)
cat <<EOF > /etc/cinder/cinder.conf
${buffer}

EOF
su -s /bin/sh -c "cinder-manage db sync" cinder

buffer=$(sed "s/\[cinder\]/"#"/g" /etc/nova/nova.conf )
cat <<EOF > /etc/nova/nova.conf
${buffer}

[cinder]
os_region_name = RegionOne
EOF

systemctl restart openstack-nova-api.service

systemctl enable openstack-cinder-api.service
systemctl enable openstack-cinder-scheduler.service
systemctl start openstack-cinder-api.service
systemctl start openstack-cinder-scheduler.service

echo "install finish cinder on ${controller}"
