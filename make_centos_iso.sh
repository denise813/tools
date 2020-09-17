#定制镜像完整步骤
ios_name="CentOS-8.2.2004-x86_64-dvd1"
top_path=$(pwd)
dest_path="${top_path}/target/${ios_name}"
mnt_path="${top_path}/mount/${ios_name}"
out_path="${top_path}/out/"
iso_path="${top_path}/iso/${ios_name}.iso"
rpm_path="${top_path}/resource/"

#1、安装必要工具
yum -y install createrepo mkisofs isomd5sum rsync

#2、复制操作系统镜像内容
mkdir -p ${dest_path}
mkdir -p ${mnt_path}
mkdir -p ${out_path}

mount ${iso_path} ${mnt_path}
#rsync -a ${mnt_path}/ ${dest_path}/
cp -r ${mnt_path}/*  ${dest_path}/
cp ${mnt_path}/.discinfo ${mnt_path}/.treeinfo ${dest_path}/

# 3 修改启动选项
#sed -i 's/timeout=60/timeout=1/g' ${dest_path}/EFI/BOOT/grub.cfg
#sed -i 's#CentOS-8-2-2004-x86_64-dvd quiet#CentOS-8-2-2004-x86_64-dvd quiet ks=cdrom:/ks7_mini.cfg#g' ${dest_path}/EFI/BOOT/grub.cfg
#sed -i 's/timeout 600/timeout 10/g' ${dest_path}/isolinux/isolinux.cfg
sed -i 's/label linux/
label linux
  menu label ^Install lenovo Centos 8
  kernel vmlinuz
  append initrd=initrd.img inst.stage2=hd:LABEL=CentOS7 ks=cdrom:/isolinux/ks.cfg
label linux/g' ${dest_path}/isolinux/isolinux.cfg

# 4 拷贝安装包
echo "copy do"
# 4.1 查询当前主机安装的软件包
#rpm -qa > ./install.log
# 4.2 删除原来的 iso中的 rpm
#rm -f ${dest_path}/BaseOS/Packages/*
# 4.3 拷贝本机安装的需要的包
#cat /root/instal.log|awk '{print $0}' |xargs -i cp ${mnt_path}/Packages/{}.rpm ${dest_path}/Packages/
# 4.4 拷贝可以下载的安装包
#yum -y install --downloadonly --downloaddir=${dest_path}/Packages/

# 4.5 拷贝自己不能系在的安装包
#cp ${rpm_path}/* ${dest_path}/BaseOS/Packages/
#cp ${rpm_path}/kernel-* ${dest_path}/BaseOS/Packages/
# 4.5.1 拷贝内核包
#rm -rf ${dest_path}/BaseOS/Packages/kernel-*
#cp ${rpm_path}/kernel-4.18.0* ${dest_path}/BaseOS/Packages/
#cp ${rpm_path}/kernel-modules-4.18.0* ${dest_path}/BaseOS/Packages/
#cp ${rpm_path}/kernel-core-4.18.0* ${dest_path}/BaseOS/Packages/
#cp ${rpm_path}/kernel-devel-4.18.0* ${dest_path}/BaseOS/Packages/
#cp ${rpm_path}/kernel-tools-libs-4.18.0* ${dest_path}/BaseOS/Packages/
#cp ${rpm_path}/kernel-headers-4.18.0* ${dest_path}/BaseOS/Packages/
#cp ${rpm_path}/kernel-tools-4.18.0* ${dest_path}/BaseOS/Packages/
# 4.5.2 ceph 依赖包

echo "copy done"

# 5 生成依赖文件
cp ${dest_path}/BaseOS/repodata/*x86_64*.xml ${dest_path}/
rm -rf ${dest_path}/BaseOS/repodata/*
mv ${dest_path}/*x86_64-comps.xml ${dest_path}/BaseOS/repodata/
createrepo -g ${dest_path}/BaseOS/repodata/*x86_64-comps.xml ${dest_path}/
pushd ${dest_path}

# 6 Kickstart配置

# 7 定制设计
#https://www.cnblogs.com/panyouming/p/8401038.html

genisoimage -joliet-long -V "CentOS 8 x86_64 Minimal" -o ${out_path}/${ios_name}.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -R -J -v -cache-inodes -T -eltorito-alt-boot -e images/efiboot.img -no-emul-boot ${dest_path}/
popd
#umount ${mnt_path}
echo "end" 
echo ${out_path}
