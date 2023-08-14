# NfS 

## 命令
```bash
#关闭防火墙
systemctl stop firewalld.service
systemctl disable firewalld.service

#创建share目录
mkdir /home/nfs
chmod 755 -R /home/nfs

#安装
yum install -y rpcbind nfs-utils
echo "/home/nfs *(rw,no_root_squash,no_all_squash,sync)">> /etc/exports
exportfs -r
systemctl start rpcbind
systemctl start nfs
systemctl enable rpcbind
systemctl enable nfs
```

## 脚本
```bash
#!/bin/bash

nfs_share_dir="/home/nfs"

echo "create nfs share dir /home/nfs!"

if [[ -d "$nfs_share_dir" ]];then
  echo "nfs share dir already existed!"
else
  mkdir /home/nfs
  chmod 755 -R /home/nfs
  echo "create nfs share dir success!"
fi

echo "start install nfs"

yum install -y rpcbind nfs-utils

echo "nfs install success"


echo "/home/nfs *(rw,no_root_squash,no_all_squash,sync)">> /etc/exports
exportfs -r
systemctl start rpcbind
systemctl start nfs
systemctl enable rpcbind
systemctl enable nfs


echo "stop and disable firewalld!"
systemctl stop firewalld.service
systemctl disable firewalld.service
echo "stop and disable firewalld success!"
```