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

local_host_name=$(hostname)
mysql -h ${controller} -u root -e "DROP DATABASE keystone;"
mysql -h ${controller} -u root -e "CREATE DATABASE keystone;"

mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'KEYSTONE_DBPASS';"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'${local_host_name}' IDENTIFIED BY 'KEYSTONE_DBPASS';"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'${controller}' IDENTIFIED BY 'KEYSTONE_DBPASS';"
mysql -h ${controller} -u root -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'KEYSTONE_DBPASS';"
yum install openstack-keystone httpd mod_wsgi -y

if [ -e rigin/keystone.conf.origin ];then
    cp /etc/keystone/keystone.conf origin/keystone.conf.origin
fi
buffer=$(sed "s/<controller>/${controller}/g" config/keystone.conf )
cat <<EOF > /etc/keystone/keystone.conf
${buffer}

EOF

su -s /bin/sh -c "keystone-manage db_sync" keystone
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone 
keystone-manage bootstrap --bootstrap-password ADMIN_PASS  --bootstrap-region-id RegionOne --bootstrap-admin-url http://${controller}:5000/v3/ --bootstrap-internal-url http://${controller}:5000/v3/ --bootstrap-public-url http://${controller}:5000/v3/

mkdir -p origin
if [ -e origin/httpd.conf.origin ];then
    cp /etc/httpd/conf/httpd.conf origin/httpd.conf.origin
fi
buffer=$(sed  "s/<controller>/${controller}/g" config/httpd.conf)
cat <<EOF > /etc/httpd/conf/httpd.conf
${buffer}

EOF

ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
systemctl enable httpd.service
systemctl start httpd.service
cat <<EOF > ./openrc
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_DOMAIN_NAME=default
export OS_AUTH_URL=http://${controller}:5000/v3
export OS_IDENTITY_API_VERSION=3
EOF

source  ./openrc
openstack project create --domain default --description "Service Project" service
openstack project create --domain default --description "Demo Project" demo
openstack user create --domain default --password DEMO_PASS demo
openstack role create --domain default user
openstack role add --project demo --user demo user

echo "install finish keystone on ${controller}"
