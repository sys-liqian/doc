# PXE

## 测试环境

* PXE server rockylinux8
* PXE client rockylinux8
* 虚拟机 HyperV
* Gateway 192.168.1.1 掩码 255.255.255.0

## EFI引导


```bash
systemctl stop firewalld
# 注意无法获取ftp文件，需要关闭SELinux
setenforce 0

# 挂载镜像
mkdir /mnt/rocky8
mount -o loop /root/Rocky-8.10-x86_64-dvd1.iso /mnt/rocky8/

# 安装软件
yum install -y tftp-server dhcp-server vsftpd
systemctl start tftp
sytemctl start dhcpd
systemctl start vsftpd
systemctl enable tftp
systemctl enable dhcpd
systemctl enable vsftpd




# ---------配置tftp-----------

# 修改tftp配置,文件不存在则新建
cat <<EOF >/etc/xinetd.d/tftp 
service tftp
{
    socket_type             = dgram
    protocol                = udp
    wait                    = yes
    user                    = root
    server                  = /usr/sbin/in.tftpd
    server_args             = -s /var/lib/tftpboot
    disable                 = no
    per_source              = 11
    cps                     = 100 2
    flags                   = IPv4
}
EOF

# ---------配置dhcp-----------
cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak
cat <<EOF >/etc/dhcp/dhcpd.conf
subnet 192.168.1.0 netmask 255.255.255.0 {
  range 192.168.1.120 192.168.1.130;
  option routers 192.168.1.1;
  next-server 192.168.1.100;
  filename "grubx64.efi";
}
EOF


# ---------配置vsftp-----------
# 配置免密
cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.bak
cat <<EOF >/etc/vsftpd/vsftpd.conf
anonymous_enable=YES
no_anon_password=YES
anon_root=/var/ftp
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
listen=NO
listen_ipv6=YES
pam_service_name=vsftpd
userlist_enable=YES
EOF

# 重启服务
systemctl restart tftp
sytemctl restart dhcpd
systemctl restart vsftpd
```

UEFI引导
```bash
# 拷贝内核和初始化镜像,引导文件到tftp目录
cp /mnt/rocky8/isolinux/initrd.img /var/lib/tftpboot/
cp /mnt/rocky8/isolinux/vmlinuz /var/lib/tftpboot/
cp -r  /mnt/rocky8/EFI/BOOT/* /var/lib/tftpboot/
chmod +w /var/lib/tftpboot/grub.cfg
# 需要有读写权限，重新拷贝文件后需要重新赋权
chmod -R 755 /var/lib/tftpboot

# 修改文件 Install Rocky Linux 8.8 部分如下,// TODO inst.stage2和inst.repo区别
menuentry 'Install Rocky Linux 8.10' --class fedora --class gnu-linux --class gnu --class os {
        linuxefi vmlinuz inst.stage2=ftp://192.168.1.100/rocky8 inst.ks=ftp://192.168.1.100/rocky8/rocky8.cfg quiet
        initrdefi initrd.img
}

# 拷贝所有镜像文件到ftp
mkdir -p /var/ftp/rocky8
# 注意隐藏文件.treeinfo
cp -rf /mnt/rocky8/* /var/ftp/rocky8
cp /mnt/rocky8/.treeinfo /var/ftp/rocky8/
cp /mnt/rocky8/.discinfo /var/ftp/rocky8/
# 设置文件权限
chmod -R 755 /var/ftp/rocky8
```

创建kickstart文件到ftp

```bash
# 生成密码
openssl passwd -1 "123456"
# $1$qwDusr1A$l0nteRMZCkRAyJOtMcms..

cat <<EOF >/var/ftp/rocky8/rocky8.cfg
# 全新安装或是升级
install

# 键盘设置
keyboard --xlayouts="us"

# root密码
rootpw --iscrypted $1$qwDusr1A$l0nteRMZCkRAyJOtMcms..
#采用明文记录
#rootpw --plaintext 123456

# 系统语言
lang en_US

# 时区设置
timezone Asia/Shanghai

# 配置系统中用户密码的加密算法和存储位置
auth  --useshadow  --passalgo=sha512

# 配置安装方式,graphical图形化,text文本
# graphical
text

# 禁用系统首次启动设置向导
firstboot --disable

# 关闭selinux
selinux --disabled

# 关闭firewalld
firewall --disabled

# 网络配置,这里的device名称好像也可以成功
network  --bootproto=dhcp --device=eth0 --onboot=yes
# 设置主机名
network  --hostname=dev

# 安装完之后重启
reboot

# 网络软件源,指向ftp,根据ftp中.treeinfo文件获取软件包位置
url --url="ftp://192.168.1.100/rocky8"

# 系统引导加载配置
bootloader --location=mbr

# 擦除磁盘上的分区并初始化
zerombr
clearpart --all --initlabel

# 磁盘分区,默认单位是M,--grow --size=1代表剩余的都分给它
part /boot --fstype="xfs" --size=1024
part /boot/efi --fstype="vfat" --size=600
part swap --fstype="swap" --size=2048
part / --fstype="xfs" --grow --size=1

# 安装软件包和相关组，支持传递参数，--ignoremissing:忽略所有在这个安装源中缺少的软件包、组及环境
%packages --ignoremissing
@^minimal-environment
authselect-compat
bash-completion
net-tools
vim
%end

# 安装完毕运行的命令，这里写的是更新安装源
%post --interpreter=/bin/bash
echo "hellp pxe" > /root/hello_pxe.txt
%end
EOF
```

## 容器PXE server

```bash
# PXE server ip 192.168.1.101
setenforce 0

docker pull quay.io/poseidon/dnsmasq:v0.5.0-38-ga731ddd
docker pull sigoden/dufs:latest

mkdir -p /data/{dufs,tftp}
mount -o loop /root/Rocky-8.10-x86_64-dvd1.iso /mnt/rocky8/

# tftp数据
cp /mnt/rocky8/isolinux/initrd.img /data/tftp
cp /mnt/rocky8/isolinux/vmlinuz /data/tftp
cp -r  /mnt/rocky8/EFI/BOOT/* /data/tftp
chmod +w /data/tftp/grub.cfg
chmod -R 755 /data/tftp

# ftp数据
cp -rf /mnt/rocky8/* /data/dufs
cp /mnt/rocky8/.treeinfo /data/dufs
cp /mnt/rocky8/.discinfo /data/dufs

cat <<EOF >/data/dufs/rocky8.cfg
install
keyboard --xlayouts="us"
rootpw --plaintext 123456
lang en_US
timezone Asia/Shanghai
auth  --useshadow  --passalgo=sha512
text
firstboot --disable
selinux --disabled
firewall --disabled
network  --bootproto=dhcp --device=eth0 --onboot=yes
network  --hostname=dev
reboot
url --url="http://192.168.1.101:5000"
bootloader --location=mbr
zerombr
clearpart --all --initlabel
part /boot --fstype="xfs" --size=1024
part /boot/efi --fstype="vfat" --size=600
part swap --fstype="swap" --size=2048
part / --fstype="xfs" --grow --size=1

%packages --ignoremissing
@^minimal-environment
authselect-compat
bash-completion
net-tools
vim
%end

%post --interpreter=/bin/bash
%end
EOF

chmod -R 755 /data/dufs


# 修改文件tftp grub.cfg 
menuentry 'Install Rocky Linux 8.10' --class fedora --class gnu-linux --class gnu --class os {
        linuxefi vmlinuz inst.stage2=http://192.168.1.101:5000 inst.ks=http://192.168.1.101:5000/rocky8.cfg quiet
        initrdefi initrd.img

# 启动dufs
docker run -v /data/dufs:/data -p 5000:5000 -d dufs:latest /data -A
# 启动dnsmasq
docker run -d --cap-add=NET_ADMIN \
  --net=host \
  -v /data/tftp:/var/lib/tftpboot \
  dnsmasq:latest \
  -d -q \
  --dhcp-range=192.168.1.120,192.168.1.130 \
  --enable-tftp --tftp-root=/var/lib/tftpboot \
  --dhcp-match=set:efibc,option:client-arch,7 \
  --dhcp-boot=tag:efibc,grubx64.efi \
  --port=0 \
  --log-queries \
  --log-dhcp
```


## Legacy引导,测试未通过

```bash
# 关闭SELinux
setenforce 0

# 安装syslinux
yum -y install syslinux

# 清空tftp
rm -rf /var/lib/tftpboot/*

# 清空ftp
rm -rf /var/ftp/rocky8/*

# 拷贝syslinux
cp /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/

# 拷贝内核，启动文件等
cp /mnt/rocky8/isolinux/* /var/lib/tftpboot/
mkdir /var/lib/tftpboot/pxelinux.cfg
cp /var/lib/tftpboot/isolinux.cfg /var/lib/tftpboot/pxelinux.cfg/default

# 修改权限
chmod -R 755 /var/lib/tftpboot

# 修改pxelinux.cfg/default文件 label linux 内容如下
label linux
  menu label ^Install Rocky Linux 8.10
  kernel vmlinuz
  append initrd=initrd.img inst.stage2=ftp://192.168.1.100/rocky8 inst.ks=ftp://192.168.1.100/rocky8/rocky8.cfg quiet

# 拷贝镜像文件到ftp
cp -rf /mnt/rocky8/* /var/ftp/rocky8
cp /mnt/rocky8/.treeinfo /var/ftp/rocky8/
cp /mnt/rocky8/.discinfo /var/ftp/rocky8/
# 设置文件权限
chmod -R 755 /var/ftp/rocky8

# 修改dhcp.conf如下
cat <<EOF >/etc/dhcp/dhcpd.conf
subnet 192.168.1.0 netmask 255.255.255.0 {
  range 192.168.1.120 192.168.1.130;
  option routers 192.168.1.1;
  next-server 192.168.1.100;
  filename "pxelinux.0";
}
EOF

# 重启dhcp
systemctl restart dhcpd

# 创建 kickstart文件到 /var/ftp/rocky8/rocky8.cfg，和EFI引导使用文件一致
```