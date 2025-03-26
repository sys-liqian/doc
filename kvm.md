# kvm

## 测试环境

* 宿主机ubuntu22.04,IP 192.168.2.7,设置网桥后192.168.2.6
* vm1 rockylinux8,IP 192.168.2.5

## 环境准备
```bash
# 宿主机安装软件
sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst
sudo systemctl start libvirtd
sudo systemctl enable libvirtd
sudo usermod -aG libvirt $USER
```

```bash
# 宿主机设置静态ip,网桥br0
vim /etc/netplan/01-network-manager-all.yaml
```
```
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    enp2s0:
      dhcp4: false
      addresses: [192.168.2.7/24]
      gateway4: 192.168.2.1
      nameservers:
        addresses:
        - 8.8.8.8
        - 114.114.114.114
  bridges:
    br0:
      interfaces: [enp2s0]
      dhcp4: false
      addresses: [192.168.2.6/24]
      gateway4: 192.168.2.1
      nameservers:
        addresses:
        - 8.8.8.8
        - 114.114.114.114
```
```bash
#重启网络
netplan apply 
```

## 启动虚拟机
```bash
# 创建虚拟硬盘
qemu-img create -f qcow2 vm1.qcow2 20G
# 网络指定网桥br0
sudo virt-install --name=vm1 --ram=1024 --vcpus=1 \
  --disk /opt/vmdata/vm1.qcow2,size=20 \
  --os-type=linux --os-variant=rocky8 --network bridge=br0 \
  --graphics none --console pty,target_type=serial \
  --location='/opt/vmdata/Rocky-8.10-x86_64-minimal.iso' \
  --extra-args='console=ttyS0,115200n8 serial'
```

## 虚拟机配置
```bash
# 虚拟机设置静态IP
vim etc/sysconfig/network-scripts/ifcfg-enp1s0
```
```
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=eui64
NAME=enp1s0
UUID=c93c81ca-3d66-46b6-9c82-b557923e6fdb
DEVICE=enp1s0
ONBOOT=yes
IPADDR=192.168.2.5
NETMASK=255.255.255.0
GATEWAY=192.168.2.1
DNS1=8.8.8.8
DNS2=114.114.114.114
```
```bash
#重启vm1
reboot
```

## 创建虚拟机例子

Ubuntu Lagcy启动
```bash
# 检查default网络是否开启
virsh net-list --all

# 创建虚拟磁盘
qemu-img create -f qcow2 ubuntu22.04-amd64-bios.qcow2 20G

# 使用默认网络启动虚拟机
virt-install \
  --name ubuntu22.04 \
  --ram 2048 \
  --vcpus 2 \
  --disk path=/data/workspace/ubuntu22.04-amd64-bios.qcow2,size=20 \
  --cdrom /data/workspace/ubuntu-22.04.5-live-server-amd64.iso \
  --network network=default \
  --vnc --vncport=5911 --vnclisten=0.0.0.0

# iso安装完成后使用 virsh edit ubuntu22.04移除cdrom

# 默认是lagcy启动
virsh list --all
virsh shutdown ubuntu22.04 
```

Ubuntu UEFI启动

```bash
# 安装UEFI固件
# CentOS/RHEL
dnf install -y edk2-ovmf      
# Ubuntu/Debian /usr/share/OVMF
apt install ovmf 
```

```bash
qemu-img create -f qcow2 ubuntu22.04-amd64-uefi.qcow2 20G

virt-install \
  --name ubuntu22.04uefi \
  --memory 2048 \
  --vcpus 2 \
  --disk path=/data/workspace/ubuntu22.04-amd64-uefi.qcow2,size=20 \
  --cdrom /data/workspace/ubuntu-22.04.5-live-server-amd64.iso \
  --boot loader=/usr/share/OVMF/OVMF_CODE.fd \
  --network network=default \
  --vnc --vncport=5912 --vnclisten=0.0.0.0
```

OpenEuler UEFI启动
```bash
virt-install \
  --name openeuler22.03 \
  --memory 2048 \
  --vcpus 2 \
  --disk path=/data/workspace/openeuler22.03-amd64.qcow2,size=20 \
  --cdrom /data/workspace/openEuler-22.03-LTS-SP4-x86_64-dvd.iso \
  --os-variant generic \
  --os-type linux \
  --boot loader=/usr/share/OVMF/OVMF_CODE.fd \
  --network network=default \
  --vnc --vncport=5913 --vnclisten=0.0.0.0
```

使用现有磁盘直接启动
```bash
virt-install \
  --name openeuler22.03 \
  --ram 2048 \
  --vcpus 2 \
  --disk path=/data/workspace/openeuler22.03-amd64-zip.qcow2,size=20 \
  --import \
  --os-variant generic \
  --os-type linux \
  --boot loader=/usr/share/OVMF/OVMF_CODE.fd \
  --network network=default \
  --vnc --vncport=5913 --vnclisten=0.0.0.0
```

无图形化vnc，纯文本模式安装
```bash
virt-install --name rocky8 --memory 2048 --vcpus 2 \
  --disk path=/data/rocky8.10-amd64-uefi.qcow2,size=20 \
  --boot loader=/usr/share/OVMF/OVMF_CODE.fd \
  --network network=default \
  --location /data/Rocky-8.10-x86_64-dvd1.iso \
  --graphics none \
  --console pty,target_type=serial \
  --extra-args='console=ttyS0,115200n8'
```

## 磁盘压缩
```bash
# 虚拟机中执行
dd if=/dev/zero of=/junk  # 创建占满剩余空间的文件
rm -f /junk              # 删除临时文件
sync 

# 宿主机执行
qemu-img convert -O qcow2 -c ubuntu22.04-amd64-uefi.qcow2 ubuntu22.04-amd64-uefi-zip.qcow
```

## 重新生成initramfs
```bash
# 若qcow2中安装的为非ubuntu的系统
# 再将qcow2灌装到nvme硬盘中会无法展开镜像
# 在qcow2系统关机前执行
dracut --force --add-drivers "nvme_core nvme nvme_fabrics megaraid_sas mpt3sas smartpqi sssraid i40e ixgbe txgbe bnxt_en ice mlx5_core mlx4_core" /boot/initramfs-$(uname -r).img $(uname -r)

# centos7 sssraid txgbe无法加载
# centos7 在kvm中可以正常运行，灌装后裸金属无法运行，需要进入救援模式重新生成initramfs
dracut --force --add-drivers "nvme_core nvme nvme_fabrics megaraid_sas mpt3sas smartpqi i40e ixgbe bnxt_en ice mlx5_core mlx4_core" /boot/initramfs-$(uname -r).img $(uname -r)
```

## centos7 修改udev格式网卡名
```bash
# iso CentOS-7-x86_64-DVD-2009.iso
# 增加 net.ifnames=1 biosdevname=0
vi /etc/default/grub
GRUB_CMDLINE_LINUX="crashkernel=auto rd.lvm.lv=centos/root rhgb net.ifnames=1 biosdevname=0 quiet"

# 重新生成grub
# lagcy
grub2-mkconfig -o /boot/grub2/grub.cfg
# uefi
grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
```



## PCI-网卡直通
```bash
# os: ubuntu 22.04 amd64
# kernal: 5.15.0-134-generic
# 网卡：Intel X550T 10G

# bios 开启cpu虚拟化

# 开启IOMMU GRUB_CMDLINE_LINUX 中添加 intel_iommu=on
vi /etc/default/grub
GRUB_CMDLINE_LINUX="intel_iommu=on"

# 如果是lagcy启动
# grub-mkconfig -o /boot/grub/grub.cfg

# uefi启动
grub-mkconfig -o /boot/efi/EFI/ubuntu/grub.cfg
reboot

# 开启iommu后 /sys/kernel/iommu_groups/ 目录下会初始化iommu_group
ls /sys/kernel/iommu_groups/

# 查询网口对应的pci地址
grep PCI_SLOT_NAME /sys/class/net/{网口}/device/uevent
# PCI_SLOT_NAME=0000:06:00.0

# 5.15.0 内核中已经默认开启了vfio,不需要手动加载
cat /boot/config-5.15.0-134-generic | grep -i vfio
cat /lib/modules/$(uname -r)/modules.builtin | grep vfio

# 查看当前pci设备使用的驱动
lspci -Dknnv  | grep 0000:06:00.0 -A 30
#Kernel driver in use: ixgbe
#Kernel modules: ixgbe

# 解绑原生驱动并绑定到vfio-pci,绑定后重新查看pci设备使用的驱动
echo 0000:06:00.0 > /sys/bus/pci/devices/0000:06:00.0/driver/unbind
echo vfio-pci > /sys/bus/pci/devices/0000:06:00.0/driver_override
echo 0000:06:00.0 > /sys/bus/pci/drivers_probe
# 或者强制指定
echo 0000:06:00.0 > /sys/bus/pci/drivers/vfio-pci/bind

# 编辑rocky8xml,在<devices>中增加hostdev
<hostdev mode='subsystem' type='pci' managed='yes'>
  <source>
    <address domain='0x0000' bus='0x06' slot='0x00' function='0x0'/>
  </source>
</hostdev>


# 恢复环境，解除虚拟机直通,重新绑定ixgbe驱动
echo 0000:06:00.0 > /sys/bus/pci/devices/0000:06:00.0/driver/unbind
echo ixgbe > /sys/bus/pci/devices/0000:06:00.0/driver_override
echo 0000:06:00.0 > /sys/bus/pci/drivers_probe
```

## SR-IOV VF网卡直通
```bash
# 查看网口支持的总vf
cat /sys/class/net/ens3f0/device/sriov_totalvfs

# 创建4个vf接口
echo 4 > /sys/class/net/ens3f0/device/sriov_numvfs
```
创建vf后如下
```bash
15: ens3f0: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether a0:36:9f:fa:b2:b0 brd ff:ff:ff:ff:ff:ff
    vf 0     link/ether 00:00:00:00:00:00 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off, query_rss off
    vf 1     link/ether 00:00:00:00:00:00 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off, query_rss off
    vf 2     link/ether 00:00:00:00:00:00 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off, query_rss off
    vf 3     link/ether 00:00:00:00:00:00 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off, query_rss off
    altname enp6s0f0
16: ens3f0v0: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 4e:0f:3b:eb:3d:b6 brd ff:ff:ff:ff:ff:ff
    altname enp6s0f0v0
17: ens3f0v1: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 82:13:96:f7:d4:80 brd ff:ff:ff:ff:ff:ff
    altname enp6s0f0v1
18: ens3f0v2: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 2a:1d:19:f2:d6:a3 brd ff:ff:ff:ff:ff:ff
    altname enp6s0f0v2
19: ens3f0v3: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether d2:c9:84:d1:e3:ec brd ff:ff:ff:ff:ff:ff
    altname enp6s0f0v3
```

```bash
# 将ens3f0v0直通到虚拟机
grep PCI_SLOT_NAME /sys/class/net/ens3f0v0/device/uevent
#PCI_SLOT_NAME=0000:06:10.0

lspci -Dknnv  | grep 0000:06:10.0 -A 30
# Kernel driver in use: ixgbevf
# Kernel modules: ixgbevf

echo 0000:06:10.0 > /sys/bus/pci/devices/0000:06:10.0/driver/unbind
echo vfio-pci > /sys/bus/pci/devices/0000:06:10.0/driver_override
echo 0000:06:10.0 > /sys/bus/pci/drivers_probe

# 修改虚拟机xml
<hostdev mode='subsystem' type='pci' managed='yes'>
  <driver name='vfio'/>
  <source>
    <address domain='0x0000' bus='0x06' slot='0x10' function='0x0'/>
  </source>
  <mac address='00:11:22:33:44:55'/>
</hostdev>

# 恢复环境,删除vf
echo 0 > /sys/class/net/ens3f0/device/sriov_numvfs
```

## kvm虚拟机添加nvme硬盘

```bash
qemu-img create -f qcow2 /data/workspace/nvme_local.qcow2 20G
qemu-img create -f raw  /data/workspace/nvme.raw 10G

virt-install \
  --name nvme \
  --memory 2048 \
  --vcpus 2 \
  --disk path=/data/workspace/nvme_local.qcow2,size=20 \
  --cdrom /data/workspace/ubuntu-22.04.5-live-server-amd64.iso \
  --os-variant ubuntu22.04 \
  --boot loader=/usr/share/OVMF/OVMF_CODE.fd \
  --network network=default \
  --vnc --vncport=5916 --vnclisten=0.0.0.0

# 安装完成后关闭虚拟机
virsh destory nvme
virsh edit nvme
# 删除cdrom disk

# 增加qemu:commandline
# domain第一行增加 xmlns:qemu
# qemu:commandlinne 一定加在最后
<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
  <qemu:commandline>
    <qemu:arg value='-drive'/>
    <qemu:arg value='file=/data/workspace/nvme.raw,if=none,id=D22,format=raw'/>
    <qemu:arg value='-device'/>
    <qemu:arg value='nvme,drive=D22,serial=1235'/>
  </qemu:commandline>
</domain>

# 问题：
# 1. Could not open '/data/workspace/nvme.raw': Permission denied
chown libvirt-qemu:kvm nvme.raw 

ln -s /etc/apparmor.d/usr.sbin.libvirtd  /etc/apparmor.d/disable/
ln -s /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper  /etc/apparmor.d/disable/
apparmor_parser -R  /etc/apparmor.d/usr.sbin.libvirtd
apparmor_parser -R  /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper

vim /etc/libvirt/qemu.conf
# 设置 security_driver = "none"

systemctl restart libvirtd
```
 
