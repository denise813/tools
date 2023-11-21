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

yum install mariadb mariadb-server python2-PyMySQL -y 

cat <<EOF > /etc/my.cnf.d/openstack.cnf
[mysqld]
bind-address = ${controller}
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOF

systemctl enable mariadb.service
systemctl start mariadb.service

echo "install finish db on ${controller}"
