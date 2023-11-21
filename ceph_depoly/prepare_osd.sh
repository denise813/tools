#! /bin/bash
set -x

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
	-sid) start_osd_id=$2
		shift
		;;
   esac
   shift
done

bdisks=${data_disks//,/ }
echo "cache=${cache_disk} meta=${meta_disk} wal_size=${wal_disk_size} db_size=${db_disk_size} block=${blocks}"

# cache 不为空
if [ ${cache_disk} ]
then
	sdparm -s WCE=0 /dev/${cache_disk}
	dd if=/dev/zero of=/dev/${cache_disk} bs=1M count=10
	parted /dev/${cache_disk} --script mktable gpt
fi

# meta 不为空
if [ ${meta_disk} ]
then
	sdparm -s WCE=0 /dev/${meta_disk}
	dd if=/dev/zero of=/dev/${meta_disk} bs=1M count=10
	parted /dev/${meta_disk} --script mktable gpt
fi

# block 处理
for disk in ${bdisks[*]}
do
	sdparm -s WCE=0 /dev/${disk}
	dd if=/dev/zero of=/dev/${disk} bs=1M count=10
done

tmp_link_dir=/tmp/osd/link
mkdir -p ${tmp_link_dir}
rm -rf /${tmp_link_dir}/*
function split_cache_disk
{
	start=0
	end=0
	i=0
	cdisk=$1
	disk_size=$2
	for disk in ${bdisks[*]}
	do
		let "i+=1"
		let "start=end"
		let "end=start + cache_size"
		parted /dev/${cdisk} --script mkpart primary ${start}G ${end}G
		ln -s /dev/${cdisk}p${i} /${tmp_link_dir}/cache_${disk}
	done
}

# 将缓存盘分成多个区
if [ ${cache_disk} ]
then
	split_cache_disk ${cache_disk} ${cache_size}
fi

function split_meta_disk
{
	echo $1 $2 $3 $4
	end=0
	start=0
	i=0
	mdisk=$1
	wal_size=$2
	db_size=$3
	for disk in ${bdisks[*]}
	do
		let "i+=1"
		let "start=end"
		let "end=start + wal_size"
		parted /dev/${mdisk} --script mkpart primary ${start}G ${end}G
		ln -s /dev/${mdisk}p${i} /${tmp_link_dir}/wal_${disk}
		let "i+=1"
		let "start=end"
		let "end=start + db_size"
		parted /dev/${mdisk} --script mkpart primary ${start}G ${end}G
		ln -s /dev/${mdisk}p${i} /${tmp_link_dir}/db_${disk}
	done
}

# 将元数据划分为多个分区
if [ ${meta_disk} ]
then
	split_meta_disk ${meta_disk} ${wal_disk_size} ${db_disk_size}
fi

function clean_osd
{
	osd_curr_id=$1
	$(ceph osd down osd.${osd_curr_id})
	$(ceph osd out osd.${osd_curr_id})
        $(ceph osd crush remove osd.${osd_curr_id})
	$(ceph auth del osd.${osd_curr_id})
	$(ceph osd rm osd.${osd_curr_id})
	rm -rf /var/lib/ceph/osd/ceph-${osd_curr_id}
}

# 获取当前空闲osd
osd_id=${start_osd_id}
for disk in ${bdisks[*]}
do
	clean_osd ${osd_id}
	let "osd_id += 1"
done

osd_id=${start_osd_id}
for disk in ${bdisks[*]}
do
	cache_param=""
	wal_param=""
	db_param=""
	if [ -L /${tmp_link_dir}/cache_${disk} ]; then
		divice=$(readlink /${tmp_link_dir}/cache_${disk})
		cache_param="--block.cache ${divice}"
	fi

	if [ -L /${tmp_link_dir}/wal_${disk} ]; then
		divice=$(readlink /${tmp_link_dir}/wal_${disk})
		wal_param="--block.wal ${divice}"
	fi

	if [ -L /${tmp_link_dir}/db_${disk} ]; then
		divice=$(readlink /${tmp_link_dir}/db_${disk})
		db_param="--block.db ${divice}"
	fi

    	/bin/bash -c ulimit -n 32768;ceph-volume raw prepare --bluestore --data /dev/${disk} ${wal_param} ${db_param} ${cache_param} --osd_id ${osd_id} --no-tmpfs
	let "osd_id += 1"
done

# 激活 osd磁盘
for disk in ${bdisks[*]}
do
	cache_param=""
	wal_param=""
	db_param=""
	if [ -L /${tmp_link_dir}/cache_${disk} ]; then
		divice=$(readlink /${tmp_link_dir}/cache_${disk})
		cache_param="--block.cache ${divice}"
	fi

	if [ -L /${tmp_link_dir}/wal_${disk} ]; then
		divice=$(readlink /${tmp_link_dir}/wal_${disk})
		wal_param="--block.wal ${divice}"
	fi      

	if [ -L /${tmp_link_dir}/db_${disk} ]; then
		divice=$(readlink /${tmp_link_dir}/db_${disk})
		db_param="--block.db ${divice}"
	fi

	# ceph-volume lvm activate -h
	/bin/bash -c ulimit -n 32768;ceph-volume raw activate --device /dev/${disk} ${wal_param} ${db_param} ${cache_param} --no-tmpfs --no-systemd
done

rm -rf /${tmp_link_dir}/*

osd_id=${start_osd_id}
for disk in ${bdisks[*]}
do
	systemctl enable ceph-osd@${osd_id}
        systemctl start ceph-osd@${osd_id}
	let "osd_id += 1"
done

