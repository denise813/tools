#! /bin/bash
#set -x

while [ $# -gt 0 ];
do
   case $1 in
	-c) cache_disk=$2
		shift
		;;
	-m) meta_disk=$2
		shift
		;;
	 -b) data_disks=${@:2}
		shift
		;;
	-cs) cache_size=$2
		shift
		;;
	-ws) wal_disk_size=$2
		shift
		;;
	-ds) db_disk_size=$2
		shift
		;;
   esac
   shift
done

blocks=${data_disks//,/ }
echo "cache=${cache_disk} meta=${meta_disk} wal_size=${wal_disk_size} db_size=${db_disk_size} block=${blocks}"

# cache 不为空
if [ ! -n "${cache_disk}" ]
then
	sdparm -s WCE=0 /dev/${cache_disk}
	parted /dev/${cache_disk} --script mktable gpt
fi

# meta 不为空
if [ ! -n "${meta_disk}" ]
then
	sdparm -s WCE=0 /dev/${meta_disk}
	parted /dev/${meta_disk} --script mktable gpt
fi

# block 处理
for block in blocks
do
	sdparm -s WCE=0 /dev/${block}
	parted /dev/${block} --script mktable gpt
done

function split_cache_disk
{
	start=0
	end=0
	i=0
	cache_disk=$1
	disk_size=$2
	for block in ${blocks[*]}
	do
		let "i+=1"
		let "start=end"
		let "end=start + cache_size"
		parted /dev/${cache_disk} --script mkpart primary ${start}G ${end}G
		ln -s /dev/${cache_disk}p${i} dev/cache_${block}
	done
}

# 将缓存盘分成多个区
if [ ! -n "${cache}" ]
then
	split_cache_disk ${cache_disk} ${cache_size}
fi

function split_meta_disk
{
	echo $1 $2 $3 $4
	end=0
	start=0
	i=0
	meta_disk=$1
	wal_size=$2
	db_size=$3
	for block in ${blocks[*]}
	do
		let "i+=1"
		let "start=end"
		let "end=start + wal_size"
		parted /dev/${meta_disk} --script mkpart primary ${start}G ${end}G
		ln -s /dev/${meta_disk}p${i} /dev/wal_${block}
		let "i+=1"
		let "start=end"
		let "end=start + db_size"
		parted /dev/${meta_disk} --script mkpart primary ${start}G ${end}G
		ln -s /dev/${meta_disk}p${i} /dev/db_${block}
	done
}

# 将元数据划分为多个分区
if [ ! -n "${meta}" ]
then
	split_meta_disk ${meta_disk} ${wal_disk_size} ${db_disk_size}
fi

# 获取当前空闲osd
for block in ${blocks[*]}
do
	cache_param=""
	wal_param=""
	db_param=""
	if [ -L /dev/cache_${block} ]; then
		cache_param="--block.cache /dev/cache_${block}"
	fi

	if [ -L /dev/wal_${block} ]; then
		wal_param="--block.wal /dev/wal_${block}"
	fi

	if [ -L /dev/db_${block} ]; then
		db_param="--block.db /dev/db_${block}"
	fi

    	/bin/bash -c ulimit -n 32768;ceph-volume raw prepare --bluestore --data ${block} ${wal_param} ${db_param} ${cache_param}  --no-tmpfs
done

# 激活 osd磁盘
for block in ${blocks[*]}
do
	cache_param=""
	wal_param=""
	db_param=""
	if [ -L /dev/cache_${block} ]; then
		cache_param="--block.cache /dev/cache_${block}"
	fi

	if [ -L /dev/wal_${block} ]; then
		wal_param="--block.wal /dev/wal_${block}"
	fi      

	if [ -L /dev/db_${block} ]; then
		db_param="--block.db /dev/db_${block}"
	fi

	# ceph-volume lvm activate -h
	/bin/bash -c ulimit -n 32768;ceph-volume raw activate --device ${block} ${wal_param} ${db_param} ${cache_param} --no-tmpfs --no-systemd
done
