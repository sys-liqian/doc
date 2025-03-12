# kvm

## 测试环境

* 宿主机ubuntu22.04,IP 192.168.2.7,设置网桥后192.168.2.6
* vm1 rockylinux8,IP 192.168.2.5

## 环境准备
```bash
# 宿主机安装软件，创建虚拟机硬盘
sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst
sudo systemctl start libvirtd
sudo systemctl enable libvirtd
sudo usermod -aG libvirt $USER
qemu-img create -f qcow2 vm1.qcow2 20G
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
# 网络指定网桥br0
sudo virt-install --name=vm1 --ram=1024 --vcpus=1 \
  --disk /opt/vmdata/vm1.qcow2,size=20 \
  --os-type=linux --os-variant=rocky8 --network bridge=br0 \
  --graphics none --console pty,target_type=serial \
  --location='/opt/vmdata/Rocky-8.10-x86_64-minimal.iso' \
  --extra-args='console=ttyS0,115200n8 serial'
```

## 虚拟机安装系统



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



```bash
# 检查default网络是否开启
virsh net-list --all

# 创建虚拟磁盘
qemu-img create -f qcow2 ubuntu22.04-amd64-uefi.qcow2 20G

# 使用默认网络启动虚拟机
virt-install \
  --name ubuntu22.04 \
  --ram 2048 \
  --vcpus 2 \
  --disk path=/home/jupiter/workspace/ubuntu22.04-amd64-uefi.qcow2,size=20 \
  --cdrom /home/jupiter/workspace/ubuntu-22.04.5-live-server-amd64.iso \
  --network network=default \
  --vnc --vncport=5911 --vnclisten=0.0.0.0

# vnc连接

# 分区
```


 
 
