template_file=/tmp/ceph.conf
rm -rf ${template_file}

while [ $# -gt 0 ];
do
   case $1 in
	-fsid) fsid=$2
		shift
		;;
	-public) public_interface=$2
		shift
		;;
	-cluster) cluster_interface=$2
		shift
		;;
	-netmask) netmask=$2
		shift
		;;
   esac
   shift
done

public_addr=$(/sbin/ifconfig ${public_interface} | awk '/inet/ {print $2}' | cut -f2 -d ":" |awk 'NR==1 {print $1}')
public_network=${public_addr}/${netmask}
cluster_addr=$(/sbin/ifconfig ${cluster_interface} | awk '/inet/ {print $2}' | cut -f2 -d ":" |awk 'NR==1 {print $1}')
cluster_network=${cluster_addr}/${netmask}
node_name=$(hostname)

# base 信息
cat >> ${template_file}  << EOF
[global]
cephx sign messages = false
ms crc data = false
ms crc header = false
#ms bind ipv6 = true
ms_type = async
fsid =${fsid}
public network = ${public_network}
cluster network = ${cluster_network}
mon initial members = ${node_name}
mon host = ${public_addr}

[mon]
mon clock drift allowed = 2
mon osd down out subtree limit = root
mon osd min in ratio = 0.5
mon debug dump transactions = false
mon osd max split count = 10000
mon allow pool delete = true
mon osd adjust down out interval = false
mon osd down out interval = 300
mon op complaint time = 100000000

[mgr]
mgr modules = dashboard

[osd]
osd crush update on start = false
osd recovery sleep hdd = 0.1
osd recovery max active = 1
osd max backfills = 1
osd deep scrub interval = 209018880000
osd scrub begin hour = 0
osd scrub end hour = 8
osd deep scrub primary write = false
osd deep scrub replica write = false
osd scrub auto repair = true
osd scrub chunk min = 3
osd scrub chunk max = 3
osd_mon_get_authorizer_timeout = 1
osd_scrub_sleep = 3
osd_deep_scrub_stride = 65536
#rocksdb_perf = true
bluestore_rocksdb_options = "compression=kNoCompression,max_write_buffer_number=4,min_write_buffer_number_to_merge=1,recycle_log_file_num=4,write_buffer_size=268435456,writable_file_max_buffer_size=0,compaction_readahead_size=2097152,max_background_compactions=2,two_write_queues=true,num_levels=3"
#max_write_buffer_number=16,min_write_buffer_number_to_merge=1,recycle_log_file_num=4,write_buffer_size=67108864,writable_file_max_buffer_size=0,compaction_readahead_size=2097152,level0_file_num_compaction_trigger=8,max_background_compactions=4,max_bytes_for_level_base=2147483648,max_bytes_for_level_multiplier=16,two_write_queues=true,num_levels=3"

[client]
rbd cache = false
client cache size = 16384000
admin socket = /var/run/ceph/\$cluster-\$type.\$id.\$pid.\$cctid.asok
log file = /var/log/ceph/ceph.client.log

EOF

