#! /bin/bash

while [ $# -gt 0 ];
do
   case $1 in
	-c) cache=$2
		shift
		;;
	-cs) cache_size=$2
		shift
		;;
	-m) meta=$2
		shift
		;;
	-ws) wal_size=$2
		shift
		;;
	-ds) db_size=$2
		shift
		;;
	-b) backs=${@:2}
       shift
       ;;
   esac
   shift
done

echo "cache=${cache_dev} meta=${meta_dev} wal_size=${wal_size} db_size=${db_size} block=${backs}"

# cache 不为空
if [ ! -n "${cache}" ]
then
	sdparm -s WCE=0 /dev/${cache}
	parted /dev/${cache} --script mktable gpt
fi

# meta 不为空
if [ ! -n "${meta}" ]
then
	sdparm -s WCE=0 /dev/${meta}
	parted /dev/${meta} --script mktable gpt
fi

# block 处理
blocks=(${backs//,/ })
for((i=0; i< =${#blocks[@]}; i++))
do
	sdparm -s WCE=0 /dev/${i}
	parted /dev/${i} --script mktable gpt
done

# 将缓存盘分成多个区
end=0
for((i=0; i< =${#blocks[@]}; i++))
do
    let start=${end}
	let end=${start} + ${cache_size}
	parted /dev/${cache} --script mkpart primary ${start}G ${end}G
done

# 将元数据划分为多个分区
end=0
for((i=0; i< =${#blocks[@]}; i++))
do
	let start=${end}
	let end=${start} + ${wal_size}
	parted /dev/${meta} --script mkpart primary ${start}G ${end}G
	let start=${end}
	let end=${start} + ${db_size}
	parted /dev/${meta} --script mkpart primary ${start}G ${end}G
done

# 获取当前空闲osd
for((i=0; i< =${#blocks[@]}; i++))
do
	let cache_index= ${i} + 1
	let wal_index = 2 * ${i} + 1
	let db_index = 2 * ${i} + 2
	let osd_id = ${osd_id} + i
    /bin/bash -c ulimit -n 32768;ceph-volume raw prepare --bluestore --data /dev/${i} --block.wal /dev/${meta}p${wal_index} --block.db /dev/${meta}p${db_index} --block.cache /dev/${cache}p${cache_index}  --no-tmpfs --osd_id ${osd_id}
done

# 激活 osd磁盘
for((i=0; i< =${#blocks[@]}; i++))
do
# ceph-volume lvm activate -h
	/bin/bash -c ulimit -n 32768;ceph-volume raw activate --device /dev/${i} --block.wal /dev/${meta}p${wal_index} -block.db /dev/${meta}p${db_index} --block.cache /dev/${cache}p${cache_index} --no-tmpfs --no-systemd
done