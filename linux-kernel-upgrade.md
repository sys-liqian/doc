# 内核升级


## rockylinux8,centos7
```bash
#yum -y install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
yum --disablerepo="*" --enablerepo="elrepo-kernel" list available | grep kernel-lt
yum -y --enablerepo=elrepo-kernel install kernel-lt kernel-lt-devel
```

```bash
# 查看可用内核
grubby --info=ALL | grep ^kernel
# 查看默认内核
grubby --default-kernel
```
设置默认内核
```bash
grubby --set-default /boot/vmlinuz-5.4.251-1.el7.elrepo.x86_64
```
确认默认内核修改成功
```bash
grub2-editenv list
```
重启



