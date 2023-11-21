controller=''

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

buffer=$(sed -e "s/<controller>/${controller}/g" config/openrc )
cat <<EOF > ./openrc
${buffer}
EOF
