# LVM

* 当前磁盘
```bash
[root@localhost ~]# lsblk
# NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
# sda               8:0    0   20G  0 disk 
# ├─sda1            8:1    0  200M  0 part /boot/efi
# ├─sda2            8:2    0    1G  0 part /boot
# └─sda3            8:3    0 18.8G  0 part 
#   ├─centos-root 253:0    0 16.8G  0 lvm  /
#   └─centos-swap 253:1    0    2G  0 lvm  [SWAP]
# sr0              11:0    1 1024M  0 rom 
```
* 增加一块5G的硬盘后,可以看到新增sdb disk
```bash
[root@localhost ~]# lsblk
# NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
# sda               8:0    0   20G  0 disk 
# ├─sda1            8:1    0  200M  0 part /boot/efi
# ├─sda2            8:2    0    1G  0 part /boot
# └─sda3            8:3    0 18.8G  0 part 
#   ├─centos-root 253:0    0 16.8G  0 lvm  /
#   └─centos-swap 253:1    0    2G  0 lvm  [SWAP]
# sdb               8:16   0    5G  0 disk 
# sr0              11:0    1 1024M  0 rom  
```
* 创建pv
```bash
[root@localhost ~]# pvcreate /dev/sdb
#   Physical volume "/dev/sdb" successfully created.
```
* 查看pv详情
```bash
[root@localhost ~]# pvdisplay /dev/sdb
#   "/dev/sdb" is a new physical volume of "5.00 GiB"
#   --- NEW Physical volume ---
#   PV Name               /dev/sdb
#   VG Name               
#   PV Size               5.00 GiB
#   Allocatable           NO
#   PE Size               0   
#   Total PE              0
#   Free PE               0
#   Allocated PE          0
#   PV UUID               fJPhwR-jNC2-2e95-O2HN-E2Bo-TGmB-2Mq0o1
```
* 创建vg
```bash
[root@localhost ~]# vgcreate vg01 /dev/sdb
#   Volume group "vg01" successfully created
```
* 查看vg详情
```bash
[root@localhost ~]# vgdisplay vg01
#   --- Volume group ---
#   VG Name               vg01
#   System ID             
#   Format                lvm2
#   Metadata Areas        1
#   Metadata Sequence No  1
#   VG Access             read/write
#   VG Status             resizable
#   MAX LV                0
#   Cur LV                0
#   Open LV               0
#   Max PV                0
#   Cur PV                1
#   Act PV                1
#   VG Size               <5.00 GiB
#   PE Size               4.00 MiB
#   Total PE              1279
#   Alloc PE / Size       0 / 0   
#   Free  PE / Size       1279 / <5.00 GiB
#   VG UUID               6i5Kjt-S1LL-ClTZ-lloi-SVly-yRTJ-lq6DSB
```
* 创建lv
```bash
# -L lv size
# -n lv name

[root@localhost ~]# lvcreate -L 100M -n lv01 vg01
#   Logical volume "lv01" created.
```
* 查看lv详情
```bash
[root@localhost ~]# lvdisplay vg01
#   --- Logical volume ---
#   LV Path                /dev/vg01/lv01
#   LV Name                lv01
#   VG Name                vg01
#   LV UUID                9WYRY2-eiqI-e2Kz-ov07-hw3q-FZNN-ZQeT4S
#   LV Write Access        read/write
#   LV Creation host, time localhost.localdomain, 2023-08-16 03:00:37 -0400
#   LV Status              available
#   # open                 0
#   LV Size                100.00 MiB
#   Current LE             25
#   Segments               1
#   Allocation             inherit
#   Read ahead sectors     auto
#   - currently set to     8192
#   Block device           253:2
```
* 简单命令
```bash
# 查看pv
pvs
# 查看vg
vgs
# 查看lv
lvs
```
* 在lv上格式化文件系统
```bash
[root@localhost ~]# mkfs.ext4 /dev/vg01/lv01 
# mke2fs 1.42.9 (28-Dec-2013)
# Discarding device blocks: done                            
# Filesystem label=
# OS type: Linux
# Block size=1024 (log=0)
# Fragment size=1024 (log=0)
# Stride=4 blocks, Stripe width=4 blocks
# 25688 inodes, 102400 blocks
# 5120 blocks (5.00%) reserved for the super user
# First data block=1
# Maximum filesystem blocks=33685504
# 13 block groups
# 8192 blocks per group, 8192 fragments per group
# 1976 inodes per group
# Superblock backups stored on blocks: 
#         8193, 24577, 40961, 57345, 73729

# Allocating group tables: done                            
# Writing inode tables: done                            
# Creating journal (4096 blocks): done
# Writing superblocks and filesystem accounting information: done 
```
* 挂载
```bash
[root@localhost ~]# mkdir /media/lv01
[root@localhost ~]# mount /dev/vg01/lv01 /media/lv01/
```
* 挂载结果
```bash
[root@localhost ~]# mount | grep /media/lv01
# /dev/mapper/vg01-lv01 on /media/lv01 type ext4 (rw,relatime,seclabel,stripe=4,data=ordered)

[root@localhost ~]# df -h
# Filesystem               Size  Used Avail Use% Mounted on
# /dev/mapper/centos-root   17G  979M   16G   6% /
# devtmpfs                 876M     0  876M   0% /dev
# tmpfs                    887M     0  887M   0% /dev/shm
# tmpfs                    887M  8.4M  879M   1% /run
# tmpfs                    887M     0  887M   0% /sys/fs/cgroup
# /dev/sda2               1014M  134M  881M  14% /boot
# /dev/sda1                200M  9.8M  191M   5% /boot/efi
# tmpfs                    178M     0  178M   0% /run/user/0
# /dev/mapper/vg01-lv01     93M  1.6M   85M   2% /media/lv01
```
* 设置开机自动挂载
```bash
echo "/dev/vg01/lv01 /media/lv01 ext4 defaults 0 0" >> /etc/fstab
```
* lv快照
```bash
[root@localhost lv01]# lvcreate -L 10M -s -n snap-lv01 -p r /dev/vg01/lv01
#   Rounding up size to full physical extent 12.00 MiB
#   Logical volume "snap-lv01" created.
```
* 环境清理
```bash
umount /media/lv01
lvremove /dev/vg01/lv01 -y
vgremove /dev/vg01 -y
pvremove /dev/sdb
```