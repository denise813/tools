controller_ip='192.168.100.150'

while [ -n "$1" ]
    do
        case "$1" in
            --controller)
                array[${#array[*]}]=$1;array[${#array[*]}]=$2;controller_ip=$2;shift;shift;continue
                ;;
            *)
                array[${#array[*]}]=$1;shift;continue
                ;;
        esac
    done

buffer=$(sed -e "s/<controller>/${controller_ip}/g" config/openrc )
cat <<EOF > ./openrc
${buffer}
EOF
