# PXE

## 测试环境

* PXE server rockylinux8
* PXE client rockylinux8
* 虚拟机 HyperV
* Gateway 192.168.1.1 掩码 255.255.255.0

## 


```bash
systemctl stop firewalld
setenforce 0

# 挂载镜像
mkdir /mnt/rocky8
mount -o loop /root/Rocky-8.8-x86_64-minimal.iso /mnt/rocky8/

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

# 修改文件 Install Rocky Linux 8.8 部分如下
menuentry 'Install Rocky Linux 8.8' --class fedora --class gnu-linux --class gnu --class os {
        linuxefi vmlinuz inst.repo=ftp://192.168.1.100/rocky8 inst.ks=ftp://192.168.1.100/rocky8/rocky8.cfg  quiet
        initrdefi initrd.img
}

# 拷贝所有镜像文件到ftp
mkdir -p /var/ftp/rocky8
cp -rf /mnt/rocky8/* /var/ftp/rocky8
cp -r /var/ftp/rocky8/BaseOS/Packages /var/ftp/rocky8
cp -r /var/ftp/rocky8/BaseOS/repodata /var/ftp/rocky8

```

创建kickstart文件到ftp

```bash
# 生成密码
openssl passwd -1 "123456"
# $1$NAAAcDvm$9aYMh4fRsFKjr1jPsjWXH.

cat <<EOF >/var/ftp/rocky8/rocky8.cfg
install

# 键盘设置
keyboard 'us'

# root密码
rootpw --iscrypted $1$NAAAcDvm$9aYMh4fRsFKjr1jPsjWXH.

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

# 安装完之后重启
reboot

# 网络源,根据自己实际情况填
url --url="ftp://192.168.1.100/rocky8/local.repo"

# 系统引导加载配置
bootloader --location=mbr

# 擦除磁盘上的分区并初始化
zerombr
clearpart --all --initlabel

# 磁盘分区,默认单位是M,--grow --size=1代表剩余的都分给它
part /boot --fstype="xfs" --size=1024
part swap --fstype="swap" --size=4096
part / --fstype="xfs" --grow --size=1

# 安装软件包和相关组
%packages
@^minimal-environment
bash-completion
net-tools
vim
%end

# 安装完毕运行的命令
%post --interpreter=/bin/bash
echo "hellp pxe" > /root/hello_pxe.txt
%end
EOF
```