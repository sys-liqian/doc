# 内核升级

1. 安装elrepo源

* centos7
```bash
yum -y install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
```
* rockylinux
```bash
yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
```

2. 安装密钥
```bash
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
```

3. 查看可用内核版本
```bash
yum --disablerepo="*" --enablerepo="elrepo-kernel" list available | grep kernel-lt
```

4. 安装内核
```bash
# 内核
yum -y --enablerepo=elrepo-kernel install kernel-lt
# 内核开发包
yum -y --enablerepo=elrepo-kernel install kernel-lt-devel
```

5. 查看系统中可用内核
```bash
grubby --info=ALL | grep ^kernel

# kernel=/boot/vmlinuz-5.4.251-1.el7.elrepo.x86_64
# kernel=/boot/vmlinuz-3.10.0-862.el7.x86_64
# kernel=/boot/vmlinuz-0-rescue-47724f09e8ff4717825c466971f62617
```

6. 查看系统中默认内核
```bash
grubby --default-kernel

#/boot/vmlinuz-3.10.0-862.el7.x86_64
```

7. 设置默认内核
```bash
grubby --set-default /boot/vmlinuz-5.4.251-1.el7.elrepo.x86_64
```

8. 确认默认内核修改成功
```bash
grub2-editenv list
```

9. reboot



