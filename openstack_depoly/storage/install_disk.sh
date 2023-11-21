set -x
controller="192.168.100.150"
block_dev="sdb"
while [ -n "$1" ]
do
    case "$1" in
        --controller)
        array[${#array[*]}]=$1;array[${#array[*]}]=$2;controller=$2;shift;shift;continue
            ;;
        --blockdev)
            array[${#array[*]}]=$1;array[${#array[*]}]=$2;block_dev=$2;shift;shift;continue
            ;;
        *)
        array[${#array[*]}]=$1;shift;continue
            ;;
    esac
done

#############################################

yum install lvm2 device-mapper-persistent-data -y
systemctl enable lvm2-lvmetad.service
systemctl start lvm2-lvmetad.service

dev_entry=${block_dev}
pvcreate /dev/${dev_entry}
vgcreate cinder-volumes /dev/${dev_entry}
#buffer=$(sed "s/<dev>/${dev_entry}/g" config/lvm.conf)
#cat <<EOF > /etc/lvm/lvm.conf
#${buffer}
#EOF

echo "install disk finish on ${controller}"

