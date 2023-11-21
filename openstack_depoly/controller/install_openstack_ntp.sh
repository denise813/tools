set -x

controller="192.168.100.150"
net_nodes="192.168.100.0/24"

while [ -n "$1" ]
do
    case "$1" in
        --controller)
            array[${#array[*]}]=$1;array[${#array[*]}]=$2;controller=$2;shift;shift;continue
            ;;
        --net)
            array[${#array[*]}]=$1;array[${#array[*]}]=$2;net_nodes=$2;shift;shift;continue
            ;;
        *)
            array[${#array[*]}]=$1;shift;continue
            ;;
    esac
done

#############################################
#
yum install chrony -y

if [ ! -e origin/chrony.conf.origin ]; then
    cp /etc/chrony.conf origin/chrony.conf.origin
fi
buffer=$(cat config/httpd.conf)

cat <<EOF > /etc/chrony.conf
${buffer_out}

#server ${controller} iburst
allow ${net_nodes}
EOF

systemctl enable chronyd.service
systemctl start chronyd.service

echo "install ntp finish on ${controller}"
