
template_file=./ceph.conf
rm -rf ./ceph.conf

while [ $# -gt 0 ];
do
   case $1 in
	-fsid) fsid=$2
		shift
		;;
	-public) public_network=$2
		shift
		;;
	-cluster) cluster_network=$2
		shift
		;;
	-mon) mgr_mon_info=${@:2}
		shift
		;;
	-osd) osd_info=${@:2}
		shift
		;;
   esac
   shift
done

# base 信息
cat >> ${template_file}  << EOF
[global]
cephx sign messages = false
ms crc data = false
ms crc header = false
#ms bind ipv6 = true
ms_type = async
fsid =${fsid}
cluster network = ${cluster_network}
public network = ${cluster_network}

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
admin socket = /var/run/ceph/$cluster-$type.$id.$pid.$cctid.asok
log file = /var/log/ceph/ceph.client.log

EOF

# 添加原始的mon 信息
mons = $(ceph node ls mon | python3 -c "import sys, json; print(json.load(sys.stdin))")
for ((i=0; i<; i++))

if [ ! -n "${mgr_mon_info}" ]
then
# 添加 mon 信息
cat >> ${template_file} << EOF
[mon.${node}]
	host = ${mgr_mon_hosts}

EOF

# 添加 mgr 信息
cat >> ${template_file} << EOF
[mgr.${node}]
	host = ${mgr_mon_hosts}

$mgr_conf
EOF
fi

if [ ! -n "${osd_info}" ]
then
# 添加信息 osd
cat >> ${template_file} << EOF
[osd.${osd_id}]
EOF
fi
