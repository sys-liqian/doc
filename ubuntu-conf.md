# Ubuntu 22.04 

## 配置用户免密sudo
```bash
# jupiter用户具有sudo权限
cd /etc/sudoers.d
# 创建的文件名不要带.不要有后缀，这里以用户名jupiter作为文件名
touch jupiter
# 在文件中添加如下行，无需重启
jupiter ALL=(ALL) NOPASSWD: NOPASSWD: ALL
```

### 配置cgroupv2 到 cgroupv1
```bash
vim /etc/default/grup
#修改GRUB_CMDLINE_LINUX_DEFAULT的配置
GRUB_CMDLINE_LINUX_DEFAULT="systemd.unified_cgroup_hierarchy=0"

#更新grup
sudo update-grub
#重启
sudo reboot
#查看是否生效
stat -fc %T /sys/fs/cgroup/
# tmpfs为cgroup v1,cgroup2fs为 v2
```

### 虚拟机双网卡配置
```yaml
# 不要指定默认路由
network:
    ethernets: {}
    version: 2
    ethernets:
      eth0:
        addresses:
        - 192.168.1.102/24
      eth1:
        dhcp4: true
```