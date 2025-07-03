# LXCFS

## 测试环境

```bash
OS: Rocky Linux 8.10
Kernel: 5.4.292-1.el8.elrepo.x86_64
```

## 安装LXCFS
```bash
yum install -y epel-release
yum install -y fuse fuse-devel
# 不使用系统自带的lxcfs，版本过低无法实现
# 版本只对procfs文件系统进行了虚拟化，并没有对/sys/devices/system/cpu/online文件进行虚拟化
# 无法实现对top，alpine等
# lxcfs version 3.0.4 
# yum install -y lxcfs

# 源码安装
wget https://github.com/lxc/lxcfs/releases/download/v6.0.4/lxcfs-6.0.4.tar.gz

# python3.6升级,lxcfs编译要求python3.7以上
yum install -y python3.12
rm -f /bin/python3
cd /bin
ln -s python3.12 python3
# 安装pip
python3 -m ensurepip --upgrade
ln -s /usr/local/bin/pip3 pip3

# 使用python3.12重新安装meson，--user安装到~/.local
pip3 install --user meson -i https://pypi.tuna.tsinghua.edu.cn/simple
export PATH=$PATH:/root/.local/bin

# 安装helpman，ninja-build
dnf config-manager --set-enabled powertools
dnf install help2man ninja-build
cd lxcfs-6.0.4

meson setup -Dinit-script=systemd --prefix=/usr build/
meson compile -C build/
sudo meson install -C build/

# 启动lxcfs
mkdir -p /var/lib/lxcfs
lxcfs --enable-cfs /var/lib/lxcfs
```

```bash
# ubutnu 可以正确屏蔽内存
# --cpus 无法真确屏蔽cpu,因为--cpus是基于时间片限制实现的，所以还能看到宿主机物理核数
# 如果使用--cpus 指定cpu lxcfs 启动是可以开启 --enable-cfs
# --cpuset-cpus=0 可以正确屏蔽
docker run -it --rm -m 256m  --cpuset-cpus=0  \
-v /var/lib/lxcfs/proc/cpuinfo:/proc/cpuinfo:rw \
-v /var/lib/lxcfs/proc/diskstats:/procdiskstats:rw \
-v /var/lib/lxcfs/proc/meminfo:/proc/meminfo:rw \
-v /var/lib/lxcfs/proc/stat:/proc/stat:rw \
-v /var/lib/lxcfs/proc/swaps:/proc/swaps:rw \
-v /var/lib/lxcfs/proc/uptime:/proc/uptime:rw \
-v /var/lib/lxcfs/sys/devices/system/cpu/online:/sys/devices/system/cpu/online \
ubuntu:24.04  /bin/sh

# alpine的镜像无法正常处理memory,uptime,这是由于alpine使用系统调用直接获取mem
# see https://github.com/lxc/lxcfs/issues/289
```