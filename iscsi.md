# centos 配置iscsi

## 环境描述

服务端 ip 172.25.16.11

客户端 ip 172.25.16.12

服务端 /dev/sdb 为目标disk设备

## 安装软件

* 服务端
```bash
yum install -y targetcli
```

* 客户端
```bash
yum install -y iscsi-initiator-utils
```

## 服务端创建iscsi设备
```bash
# targetcli进入交互shell
targetcli
/backstores/block create m_block /dev/sdb  
/iscsi create iqn.2023-03.com.example:mdisk
/iscsi/iqn.2023-03.com.example:mdisk/tpg1/acls create iqn.2023-03.com.example:client
/iscsi/iqn.2023-03.com.example:mdisk/tpg1/luns  create /backstores/block/m_block
```

## 客户端修改iscsi配置文件
```bash
vim /etc/iscsi/initiatorname.iscsi
InitiatorName=iqn.2023-03.com.example:client
```

## 客户端操作iscsi设备 

* 客户端查找可用设备
```bash
iscsiadm -m discovery -t sendtargets -p 172.25.16.11
```

* 客户端登录(只发现一个target可以不指定targetname)
```bash
iscsiadm -m node --login --targetname iqn.2023-03.com.example:mdisk
```

* 客户端卸载iscsi设备
```bash
iscsiadm -m node --targetname iqn.2023-03.com.example:mdisk -u
```

* 客户端删除发现记录
```bash
iscsiadm -m node -o delete -T iqn.2023-03.com.example:mdisk
```