# Hyper-v虚拟机根分区扩容

## 前置要求
1. 虚拟机磁盘扩容前删除检查点，并且处于关机状态
2. HyperV管理界面编辑磁盘给磁盘扩容

当前根分区大小
```bash
[root@localhost /]# lsblk
# NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
# sda               8:0    0   20G  0 disk 
# ├─sda1            8:1    0  200M  0 part /boot/efi
# ├─sda2            8:2    0    1G  0 part /boot
# └─sda3            8:3    0 18.8G  0 part 
#   ├─centos-root 253:0    0 16.8G  0 lvm  /
#   └─centos-swap 253:1    0    2G  0 lvm  [SWAP]
# sr0              11:0    1 1024M  0 rom 
```

## 扩容过程

* 当前磁盘大小为30G,根分区16.8G
```bash
[root@localhost ~]# lsblk
# NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
# sda               8:0    0   30G  0 disk 
# ├─sda1            8:1    0  200M  0 part /boot/efi
# ├─sda2            8:2    0    1G  0 part /boot
# └─sda3            8:3    0 18.8G  0 part 
#   ├─centos-root 253:0    0 16.8G  0 lvm  /
#   └─centos-swap 253:1    0    2G  0 lvm  [SWAP]
# sr0              11:0    1 1024M  0 rom 
```

* 创建新分区
```bash
[root@localhost ~]# fdisk /dev/sda
# WARNING: fdisk GPT support is currently new, and therefore in an experimental phase. Use at your own discretion.
# Welcome to fdisk (util-linux 2.23.2).

# Changes will remain in memory only, until you decide to write them.
# Be careful before using the write command.


# Command (m for help): n
# Partition number (4-128, default 4): 
# First sector (34-41943006, default 41940992): 
# Last sector, +sectors or +size{K,M,G,T,P} (41940992-41943006, default 41943006): 
# Created partition 4


# Command (m for help): w
# fdisk: cannot write disk label: Invalid argument
```
* 该错误修复
```bash
[root@localhost ~]# parted -l
[root@localhost ~]# reboot
```
* 重新创建分区
* 当前分区情况如下,sda4被创建
```bash
# NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
# sda               8:0    0   30G  0 disk 
# ├─sda1            8:1    0  200M  0 part /boot/efi
# ├─sda2            8:2    0    1G  0 part /boot
# ├─sda3            8:3    0 18.8G  0 part 
# │ ├─centos-root 253:0    0 16.8G  0 lvm  /
# │ └─centos-swap 253:1    0    2G  0 lvm  [SWAP]
# └─sda4            8:4    0   10G  0 part 
# sr0              11:0    1 1024M  0 rom 
```
* 在新分区上创建pv
```bash
[root@localhost ~]# pvcreate /dev/sda4 
#   Physical volume "/dev/sda4" successfully created.
```
* 获取根分区vg name为centos
```bash
[root@localhost ~]# vgs
#   VG     #PV #LV #SN Attr   VSize  VFree
#   centos   1   2   0 wz--n- 18.80g    0 
```
* 将新的pv加入原根分区的vg中
```bash
[root@localhost ~]# vgextend centos /dev/sda4
#   Volume group "centos" successfully extended
```
* 将centos vg中剩余空间添加到根分区的lv中
```bash
[root@localhost ~]# lvextend -l +100%FREE /dev/centos/root 
#   Size of logical volume centos/root changed from 16.80 GiB (4301 extents) to <26.80 GiB (6860 extents).
#   Logical volume centos/root successfully resized.
```
* 同步文件系统
```bash
[root@localhost ~]# xfs_growfs /dev/centos/root
# meta-data=/dev/mapper/centos-root isize=512    agcount=4, agsize=1101056 blks
#          =                       sectsz=4096  attr=2, projid32bit=1
#          =                       crc=1        finobt=0 spinodes=0
# data     =                       bsize=4096   blocks=4404224, imaxpct=25
#          =                       sunit=0      swidth=0 blks
# naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
# log      =internal               bsize=4096   blocks=2560, version=2
#          =                       sectsz=4096  sunit=1 blks, lazy-count=1
# realtime =none                   extsz=4096   blocks=0, rtextents=0
# data blocks changed from 4404224 to 7024640
```
* 结果
```bash
[root@localhost ~]# df -h
# Filesystem               Size  Used Avail Use% Mounted on
# /dev/mapper/centos-root   27G  1.3G   26G   5% /
# devtmpfs                 876M     0  876M   0% /dev
# tmpfs                    887M     0  887M   0% /dev/shm
# tmpfs                    887M  8.4M  879M   1% /run
# tmpfs                    887M     0  887M   0% /sys/fs/cgroup
# /dev/sda2               1014M  134M  881M  14% /boot
# /dev/sda1                200M  9.8M  191M   5% /boot/efi
# tmpfs                    178M     0  178M   0% /run/user/0
```

