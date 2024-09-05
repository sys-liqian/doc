# Samba

Rocylinux9.4
```bash
dnf -y install samba
adduser samba
passwd samba
smbpasswd -a samba
setenforce 0
mkdir -p /home/samba/share
chmod -R 777 share/
systemctl start smb
systemctl enable smb
```

/etc/samba/smb.conf 文件末尾添加
```
[samba]
        comment = all
        path = /home/samba/share
        browseable = Yes
        writable = Yes
        valid users = @samba
        write list = @samba
        read only = No
```