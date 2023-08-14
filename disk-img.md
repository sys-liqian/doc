# linux制作虚拟磁盘镜像

## 制作虚拟磁盘镜像文件

dd命令参数介绍
```
of 输出文件名
bs 同时设置读入/输出的块大小为bytes个字节
count bs个数
```
```bash
dd if=/dev/zero of=/root/1g.img bs=10M count=100

# 100+0 records in
# 100+0 records out
# 1048576000 bytes (1.0 GB) copied, 1.67327 s, 627 MB/s
```
## 挂载虚拟磁盘镜像文件

* 查看本地是否已经存在loop设备,若loop0已经存在，则使用/dev/loop1,依此类推
```bash
lsblk

# NAME                        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
# sda                           8:0    0  100G  0 disk 
# ├─sda1                        8:1    0  300M  0 part /boot/efi
# ├─sda2                        8:2    0  1.4G  0 part /boot
# └─sda3                        8:3    0 98.3G  0 part 
#   ├─centos-root             253:0    0 93.5G  0 lvm  /
#   └─centos-swap             253:1    0    4G  0 lvm  [SWAP]
# sdb                           8:16   0   50G  0 disk 
# └─vol_sldzl7tfqjt_01-volume 253:2    0   50G  0 lvm  /data
# sr0                          11:0    1  470K  0 rom  

losetup /dev/loop0
```

* 将文件虚拟成块设备
```bash
losetup /dev/loop0 /root/1g.img
```

* 查看硬盘
 
* 卸载loop设备
```bash
losetup -d /dev/loop0
```

