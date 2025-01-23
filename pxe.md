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
  --dhcp-match=set:bios,option:client-arch,0 \
  --dhcp-boot=tag:bios,pxelinux.0 \
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

## Ubuntu pxe

* Ubuntu pxe cloud init 使用内存较多,至少8g,要保证Subiquity服务启动成功

```bash
# 在ubuntu下载引导文件，在ubuntu22.04下载，可能不支持24.04
apt-get download shim.signed
apt-get download grub-efi-amd64-signed
mkdir shim-signed
mkdir grub-efi-amd64-signed
dpkg -x shim-signed_1.40.10+15.8-0ubuntu1_amd64.deb shim-signed
dpkg -x grub-efi-amd64-signed_1.187.9~20.04.1+2.06-2ubuntu14.6_amd64.deb grub-efi-amd64-signed
# 挂载镜像
mount -o loop /data/ubuntu-22.04.5-live-server-amd64.iso /mnt/ubuntu
# 拷贝引导文件到tftp,并且重命名
cp ./shim-signed/user/lib/shim/shimx64.efi.signed.latest /var/lib/tftpboot/bootx64.efi
cp ./grub-efi-amd64-signed/usr/lib/grub/x86_64-efi-signed/grubnetx64.efi.signed /var/lib/tftpboot/grubx64.efi
cp /mnt/ubuntu/casper/vmlinuz /var/lib/tftpboot/
cp /mnt/ubuntu/casper/initrd /var/lib/tftpboot/
# 注意目录结构
mkdir /var/lib/tftpboot/grub
cp /mnt/ubuntu/boot/grub/grub.cfg /var/lib/tftpboot/grub/
cp /mnt/ubuntu/boot/grub/fonts/unicode.pf2 /var/lib/tftpboot/
chmod -R 755 /var/lib/tftpboot

# 修改引导菜单

# 配置文件服务,使用http,ftp都可以
mkdir -p /var/ftp/ubuntu/{autoinstall,iso}
cp /data/ubuntu-22.04.5-live-server-amd64.iso /var/ftp/ubuntu/iso
# 创建文件,cloud init 格式要求
touch /var/ftp/ubuntu/autoinstall/user-data
touch /var/ftp/ubuntu/autoinstall/meta-data
touch /var/ftp/ubuntu/autoinstall/vendor-data

# 生成密码 123456
python3 -c 'import crypt; print(crypt.crypt("123456", crypt.mksalt(crypt.METHOD_SHA512)))'

```

修改 /var/lib/tftpboot/grup/grub.cfg如下:
```
set timeout=30
set pager=1

loadfont unicode

set menu_color_normal=white/black
set menu_color_highlight=black/light-gray

menuentry "Try or Install Ubuntu Server" {
        set gfxpayload=keep
        linux   vmlinuz ip=dhcp url=ftp://192.168.1.100/ubuntu/iso/ubuntu-22.04.5-live-server-amd64.iso autoinstall ds=nocloud-net\;s=ftp://192.168.1.100/ubuntu/autoinstall/
        initrd  initrd
}
grub_platform
if [ "$grub_platform" = "efi" ]; then
menuentry 'Boot from next volume' {
        exit 1
}
menuentry 'UEFI Firmware Settings' {
        fwsetup
}
else
menuentry 'Test memory' {
        linux16 /boot/memtest86+x64.bin
}
fi
```

修改/var/ftp/ubuntu/autoinstall/user-data如下
```yaml
#cloud-config
autoinstall:
  apt:
    geoip: true
    preserve_sources_list: false
    primary:
    - arches: [amd64, i386]
      uri: http://in.archive.ubuntu.com/ubuntu
    - arches: [default]
      uri: http://ports.ubuntu.com/ubuntu-ports
  identity: {hostname: ubuntu-server, password: $6$j0PHK3qwmxGKhA4W$b5YBMQGlEsIE/QBGrkCWRqs4I7fJn1C9PbbKe51RcDm6iXEVinR/uNt4L7Vb3EvsfJN7c87pNNAEtpuhTCJ9C1,
    realname: Deepak, username: deepak}
  keyboard: {layout: us, toggle: null, variant: ''}
  locale: en_US.UTF-8
  network:
    ethernets:
      eth0:
        critical: true
        dhcp-identifier: mac
        dhcp4: true
    version: 2
  updates: security
  version: 1
  packages:
  - openssh-server
  ssh_pwauth: true
  runcmd:
  - systemctl enable ssh
  - systemctl start ssh
```

tftp 目录结构
```
[root@master tftpboot]# tree
.
├── bootx64.efi
├── grub
│   └── grub.cfg
├── grubx64.efi
├── initrd
├── mmx64.efi
├── unicode.pf2
└── vmlinuz

1 directory, 7 files
```

htt文件服务器 目录结构
```
[root@master ftp]# tree ubuntu/
ubuntu/
├── autoinstall
│   ├── meta-data
│   └── user-data
└── iso
    └── ubuntu-22.04.5-live-server-amd64.iso

2 directories, 3 files
```

## 使用Ubuntu作为Live System灌装

修改qcow2默认密码

```bash
virt-customize -a ubuntu-20.04-server-cloudimg-amd64.img --root-password password:123456
```

制作qemu-utils deb包
```bash
cd cd /var/cache/apt/archives/
# 当前为中文系统，所以grep 中文
sudo apt-get install --reinstall -d `apt-cache depends qemu-img | grep "依赖" | cut -d: -f2 |tr -d "<>"`
sudo apt-get download qemu-img
mkdir qemu-utils
mv ./*.deb qemu-utils
tar -czvf qemu-utils.tar.gz qemu-utils
```

目录结构
```
[root@dnsmasq data]# tree pxeboot/
pxeboot/
├── base
│   ├── image
│   │   ├── Rocky-8-GenericCloud.latest.x86_64.qcow2
│   │   └── ubuntu-22.04-server-cloudimg-amd64.img
│   ├── script
│   │   ├── filling.sh.temp
│   │   ├── host1.sh
│   │   ├── host2.sh
│   └── tools
│       ├── pxe-agent-x86_64
│       └── qemu-utils-x86_64.tar.gz
├── grub
│   └── grub.cfg
├── grubx64.efi
├── initrd
├── os
│   └── x86_64
│       ├── autoinstall
│       │   ├── meta-data
│       │   ├── user-data
│       │   └── vendor-data
│       └── iso
│           └── ubuntu-22.04.5-live-server-amd64.iso
├── unicode.pf2
└── vmlinu
```

filling.sh.temp
```bash
#!/bin/bash
# 由程序动态渲染，为每台裸金属生成自己的灌装脚本
file_server_addr={{ .FileServerAddr }}
image_name={{ .ImageName }}
arch=$(arch)
clean_disk={{ .CleanDisk }}
clean_boot_item={{ .CleanBootItem }}
target_disk_name={{ .TargetDiskName }}

boot_label={{ .BootLabel }}
boot_part_number={{ .BootPartNumber }}
root_part_number={{ .RootPartNumber }}
boot_loader={{ .BootLoader }}


echo "make work dir /qemu-utils /image"
mkdir /qemu-utils
mkdir /image

echo "download qemu-utils and image file."
wget -O /tmp/qemu-utils.tar.gz "$file_server_addr/base/tools/qemu-utils-$arch.tar.gz" &>/dev/null
wget -O /image/target.img "$file_server_addr/base/image/$image_name" &>/dev/null

echo "unzip qemu-utils."
cd /qemu-utils
tar -zxvf /tmp/qemu-utils.tar.gz &>/dev/null

echo "install qemu-utils."
dpkg -i /qemu-utils/qemu-utils/*.deb &>/dev/null


#  清理磁盘
if [ "$clean_disk" = true ]; then
    echo "clean disk $target_disk_name ......"
    parted /dev/$target_disk_name -s -- mklabel msdos
    dd if=/dev/zero of=/dev/$target_disk_name bs=512
    wipefs -a /dev/$target_disk_name
    echo "disk $target_disk_name cleaned successfully."
else
    echo "disk cleaning skipped."
fi

# 灌装
echo "convert image to /dev/$target_disk_name"
qemu-img convert -p -O raw /image/target.img /dev/$target_disk_name

lsblk

sleep 10

# 挂载 / 分区
echo "mount root part /dev/$target_disk_name$root_part_number to /mnt"
mount /dev/$target_disk_name$root_part_number /mnt


# 执行自定义脚本
echo "start execute custom script."

{{ .CustomizeShell }}

echo "end of execute custom script."

echo "umount /mnt"
umount /mnt

# 清理boot item
if [ "$clean_boot_item" = true ]; then
  echo "clean old boot items"
  efibootmgr -v
  boot_entries=$(efibootmgr -v | grep '.efi' | awk '{print $1}')
  for entry in "${boot_entries[@]}"; do
    tmp="${entry#Boot}"
    flag="${tmp::-1}"
    echo "delete boot entry: $flag"
    sleep 1
    efibootmgr -b "$flag" -B
    if [ $? -ne 0 ]; then
      echo "error deleting boot entry: $entry"
    else
      echo "successfully deleted boot entry: $entry"
    fi
  done
fi

# 需要提前获取qcow2 的root分区和 efi 分区编号
efibootmgr -c -d /dev/$target_disk_name -p $boot_part_number -L "$boot_label" -l "$boot_loader"
efibootmgr -v 
sleep 10

echo "reboot"
reboot
```



host1.sh (由程序渲染所得)

```bash
#!/bin/bash
file_server_addr=http://192.168.1.101:5000
image_name=Rocky-8-GenericCloud.latest.x86_64.qcow2
arch=$(arch)
clean_disk=true
clean_boot_item=true
target_disk_name=sda

boot_label=rocky
boot_part_number=1
root_part_number=5
boot_loader=/EFI/rocky/shimx64.efi


echo "make work dir /qemu-utils /image"
mkdir /qemu-utils
mkdir /image

echo "download qemu-utils and image file."
wget -O /tmp/qemu-utils.tar.gz "$file_server_addr/base/tools/qemu-utils-$arch.tar.gz" &>/dev/null
wget -O /image/target.img "$file_server_addr/base/image/$image_name" &>/dev/null

echo "unzip qemu-utils."
cd /qemu-utils
tar -zxvf /tmp/qemu-utils.tar.gz &>/dev/null

echo "install qemu-utils."
dpkg -i /qemu-utils/qemu-utils/*.deb &>/dev/null

if [ "$clean_disk" = true ]; then
    echo "clean disk $target_disk_name ......"
    parted /dev/$target_disk_name -s -- mklabel msdos
    dd if=/dev/zero of=/dev/$target_disk_name bs=512
    wipefs -a /dev/$target_disk_name
    echo "disk $target_disk_name cleaned successfully."
else
    echo "disk cleaning skipped."
fi

echo "convert image to /dev/$target_disk_name"
qemu-img convert -p -O raw /image/target.img /dev/$target_disk_name

lsblk

sleep 10

echo "mount root part /dev/$target_disk_name$root_part_number to /mnt"
mount /dev/$target_disk_name$root_part_number /mnt

echo "start execute custom script."



echo "end of execute custom script."

echo "umount /mnt"
umount /mnt


if [ "$clean_boot_item" = true ]; then
  echo "clean old boot items"
  efibootmgr -v
  boot_entries=$(efibootmgr -v | grep '.efi' | awk '{print $1}')
  for entry in "${boot_entries[@]}"; do
    tmp="${entry#Boot}"
    flag="${tmp::-1}"
    echo "delete boot entry: $flag"
    sleep 1
    efibootmgr -b "$flag" -B
    if [ $? -ne 0 ]; then
      echo "error deleting boot entry: $entry"
    else
      echo "successfully deleted boot entry: $entry"
    fi
  done
fi

efibootmgr -c -d /dev/$target_disk_name -p $boot_part_number -L "$boot_label" -l "$boot_loader"
efibootmgr -v 
sleep 10

echo "reboot"
reboot
```

gurb.cfg
```bash
set timeout=300
set pager=1
set default=0

loadfont unicode

set menu_color_normal=white/black
set menu_color_highlight=black/light-gray

menuentry "Try or Install x86_64 Server" {
        set gfxpayload=keep
        linux   vmlinuz ip=dhcp url=http://192.168.1.101:5000/os/x86_64/iso/ubuntu-22.04.5-live-server-amd64.iso autoinstall ds=nocloud-net\;s=http://192.168.1.101:5000/os/x86_64/autoinstall/
        initrd  initrd
}

menuentry "Try or Install aarch64 Server" {
        set gfxpayload=keep
        linux   vmlinuz ip=dhcp url=http://192.168.1.101:5000/os/aarch64/iso/ubuntu-22.04.5-live-server-arm64.iso autoinstall ds=nocloud-net\;s=http://192.168.1.101:5000/os/aarch64/autoinstall/
        initrd  initrd
}
```

user-data, pxe-agent会根据自己的唯一信息获取自己的setup.sh,如bmcip,主板序列号等

```
#cloud-config
autoinstall:
  early-commands:
    - wget -O /usr/bin/pxe-agent http://192.168.1.101:5000/base/tools/pxe-agent-$(uname -m)
    - chmod +x /usr/bin/pxe-agent
    - pxe-agent --ip 192.168.1.101 --fakeid host1
    - wget -O /usr/bin/setup.sh http://192.168.1.101:5000/base/script/host1.sh
    - chmod +x /usr/bin/setup.sh
    - /usr/bin/setup.sh
  version: 1
```

## IPXE

编译IPXE固件
```bash
yum install xz-devel git
git clone https://github.com/ipxe/ipxe.git
cd ipxe/src
make bin/undionly.kpxe
make bin-x86_64-efi/ipxe.efi
# 复制到tftp根目录
mv bin/undionly.kpxe /data/pxeboot/
mv bin-x86_64-efi/ipxe.efi /data/pxeboot/
```
dnsmasq.sh

```bash
#!/bin/bash
docker rm -f pxe-dnsmasq
sleep 2
docker run -d --cap-add=NET_ADMIN \
  --net=host \
  --name pxe-dnsmasq \
  -v /data/pxeboot:/var/lib/tftpboot \
  dnsmasq:latest \
  -d -q \
  --dhcp-range=192.168.1.120,192.168.1.250 \
  --enable-tftp --tftp-root=/var/lib/tftpboot \
  --dhcp-match=set:efi64,option:client-arch,9 \
  --dhcp-boot=tag:efi64,ipxe.efi \
  --dhcp-match=set:efibc,option:client-arch,7 \
  --dhcp-boot=tag:efibc,ipxe.efi \
  --dhcp-match=set:bios,option:client-arch,0 \
  --dhcp-boot=tag:bios,pxelinux.0 \
  --dhcp-boot=tag:ipxe,http://192.168.1.101:5000/boot.ipxe \
  --port=0 \
  --log-queries \
  --log-dhcp
```

目录结构

* centos7.9目录为CentOS-7-x86_64-DVD-2009.iso内容解压后拷贝
* 2eb5e140-03e3-4611-ba5f-5fca34e1dfcc和ab052818-397a-4852-9588-20b997cef939为两台主机的product_uuid

```
[root@dnsmasq data]# tree pxeboot/
pxeboot/
├── boot
│   ├── 2eb5e140-03e3-4611-ba5f-5fca34e1dfcc
│   │   ├── meta-data
│   │   ├── user-data
│   │   └── vendor-data
│   ├── ab052818-397a-4852-9588-20b997cef939.ks
│   ├── uuid-2eb5e140-03e3-4611-ba5f-5fca34e1dfcc.ipxe
│   └── uuid-ab052818-397a-4852-9588-20b997cef939.ipxe
├── boot.ipxe
├── boot.ipxe.cfg
├── init
│   ├── initrd
│   └── vmlinuz
├── ipxe.efi
├── iso
│   ├── centos7.9
│   └── ubuntu-22.04.5-live-server-amd64.iso
├── menu.ipxe
└── undionly.kpxe
```

boot.ipxe
```bash
#!ipxe

# chain boot.ipxe.cfg加载全局配置文件
chain --autofree boot.ipxe.cfg

# 通过主机的product_uuid获取 uuid-${uuid}.ipxe 文件
# 如果获取到了就执行，没有获取到则执行下一个chain
isset ${uuid} && chain --replace --autofree ${boot-dir}uuid-${uuid}.ipxe ||

# 默认走到menu.ipxe
chain --replace --autofree ${menu-url} ||
```
boot.ipxe.cfg
```bash
#!ipxe

# http文件服务器地址
set file-server http://192.168.1.101:5000
# ipxe所需文件在文件服务器路径
set file-server-root /
# 组装ipxe服务器地址
set boot-url ${file-server}${file-server-root}
# 存放每台主机.ipxe配置文件所在目录
set boot-dir boot/
# 安装系统目录菜单
set menu-url ${boot-url}menu.ipxe
```
menu.ipxe
```bash
#!ipxe

set menu-timeout 600000
isset ${menu-default} || set menu-default exit
 
:start
menu boot from iPXE server
item --gap --             -------------Operating Systems----------------
item centos-7.9       BOOT Centos 7.9
item ubuntu-22.04     BOOT Ubuntu 22.04
item rockylinux-8.10  BOOT RockyLinux 8.10
item --gap --             -------------Advanced Options-----------------
item config           Configure settings
item shell            Drop to IPXE shell
item reboot           Reboot computer
item
item exit             Exit IPXE and continue BIOS boot
choose --default ${menu-default} --timeout ${menu-timeout} selected || goto cancel
goto ${selected}
 
:cancel
echo You cancelled the menu, dropping you to a shell

:shell
echo Type 'exit' to get the back to the menu
shell
set menu-timeout 0
set submenu-timeout 0
goto start

:reboot
reboot

:exit
exit

:config
config
goto start

############## MAIN MENU ITEMS  #################################

:ubuntu-22.04
echo Selected Ubuntu 22.04
initrd ${file-server}/init/initrd
kernel ${file-server}/init/vmlinuz ip=dhcp url=${file-server}/iso/ubuntu-22.04.5-live-server-amd64.iso autoinstall ds=nocloud-net;s=${file-server}/boot/${uuid}
boot

:centos-7.9
echo Selected Centos 7.9
initrd ${file-server}/iso/centos7.9/isolinux/initrd.img
kernel ${file-server}/iso/centos7.9/isolinux/vmlinuz inst.stage2=${file-server}/iso/centos7.9 ks=${file-server}/boot/${uuid}.ks quiet
boot
```
boot/uuid-2eb5e140-03e3-4611-ba5f-5fca34e1dfcc.ipxe
```bash
#!ipxe
# 2eb5e140-03e3-4611-ba5f-5fca34e1dfcc menu-设置为ubuntu-22.04
set menu-default ubuntu-22.04
chain --replace --autofree ${menu-url}
```

boot/uuid-ab052818-397a-4852-9588-20b997cef939.ipxe
```bash
#!ipxe
set menu-default centos-7.9
chain --replace --autofree ${menu-url}
```
boot/2eb5e140-03e3-4611-ba5f-5fca34e1dfcc/user-data
```bash
#cloud-config
autoinstall:
  apt:
    geoip: true
    preserve_sources_list: false
    primary:
    - arches: [amd64, i386]
      uri: http://in.archive.ubuntu.com/ubuntu
    - arches: [default]
      uri: http://ports.ubuntu.com/ubuntu-ports
  identity: {hostname: jupiter, password: $6$0NLe1hnjoEaCUlat$edClT7amesXSCmyv8fvyJJqRn1nDj2eqp8XO08gYVDwlRRwuuYpklqsAsIIvfKAC9n12yFB.gSNX6pCoOkev31,
    realname: jupiter, username: jupiter}
  keyboard: {layout: us, toggle: null, variant: ''}
  locale: en_US.UTF-8
  network:
    ethernets:
      eth0:
        critical: true
        dhcp-identifier: mac
        dhcp4: true
    version: 2
  updates: security
  version: 1
  packages:
  - openssh-server
  ssh_pwauth: true
runcmd:
  - systemctl enable ssh
  - systemctl start ssh
```
boot/ab052818-397a-4852-9588-20b997cef939.ks
```bash
install
keyboard --xlayouts="us"
rootpw --iscrypted $1$qwDusr1A$l0nteRMZCkRAyJOtMcms..
#rootpw --plaintext 123456
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
url --url="http://192.168.1.100:5000/iso/centos7.9"
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
```