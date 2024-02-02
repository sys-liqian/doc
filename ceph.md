# Ceph

## Ceph搭建

搭建工具cephadm

### 系统信息

```
[root@ceph ~]# cat /proc/version
Linux version 4.18.0-477.10.1.el8_8.x86_64 (mockbuild@iad1-prod-build001.bld.equ.rockylinux.org) (gcc version 8.5.0 20210514 (Red Hat 8.5.0-18) (GCC)) #1 SMP Tue May 16 11:38:37 UTC 2023
```
### 网络信息
eth0使用内网交换机

eth1使用默认交换机连接外网

/etc/sysconfig/network-scripts/ifcfg-eth0
```
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=eui64
NAME=eth0
UUID=a81509a7-dc9b-4010-9b45-432d4f5ba737
DEVICE=eth0
ONBOOT=yes
IPADDR=172.25.16.5
```

/etc/sysconfig/network-scripts/ifcfg-eth1
```
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=dhcp
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=eui64
NAME=eth1
UUID=13c820a8-b2cc-496f-9383-973e1002b756
DEVICE=eth1
ONBOOT=yes
```

重启网络
```bash
nmcli c reload
```

### 磁盘信息
```
[root@ceph network-scripts]# lsblk
NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda           8:0    0   10G  0 disk 
sdb           8:16   0   20G  0 disk 
├─sdb1        8:17   0  600M  0 part /boot/efi
├─sdb2        8:18   0    1G  0 part /boot
└─sdb3        8:19   0 18.4G  0 part 
  ├─rl-root 253:0    0 16.4G  0 lvm  /
  └─rl-swap 253:1    0    2G  0 lvm  [SWAP]
sr0          11:0    1 1024M  0 rom
```

### 安装

#### python3
cephadm 需要python3.6+
```bash
yum install wget zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc make
wget http://npm.taobao.org/mirrors/python/3.6.4/Python-3.6.4.tar.xz
xz -d Python-3.6.4.tar.xz
tar -xf Python-3.6.4.tar
cd Python-3.6.4
./configure  prefix=/usr/local/python3
make && make install
ln -s /usr/local/python3/bin/python3.6 /usr/bin/python
ln -s /usr/local/python3/bin/python3.6 /usr/bin/python3
```

#### cephadmin下载 reef版本
```bash
CEPH_RELEASE=18.2.0
curl --silent --remote-name --location https://download.ceph.com/rpm-${CEPH_RELEASE}/el9/noarch/cephadm
chmod +x cephadm
```

#### 安装ceph
```bash
./cephadm add-repo --release reef
./cephadm install
which cephadm
cephadm bootstrap --mon-ip 172.25.16.5
```
输出如下
```text
Creating directory /etc/ceph for ceph.conf
Verifying podman|docker is present...
Verifying lvm2 is present...
Verifying time synchronization is in place...
Unit chronyd.service is enabled and running
Repeating the final host check...
podman (/usr/bin/podman) version 4.4.1 is present
systemctl is present
lvcreate is present
Unit chronyd.service is enabled and running
Host looks OK
Cluster fsid: d93a8098-7f9a-11ee-a7a0-00155d58d032
Verifying IP 172.25.16.5 port 3300 ...
Verifying IP 172.25.16.5 port 6789 ...
Mon IP `172.25.16.5` is in CIDR network `172.25.0.0/16`
Mon IP `172.25.16.5` is in CIDR network `172.25.0.0/16`
Internal network (--cluster-network) has not been provided, OSD replication will default to the public_network
Pulling container image quay.io/ceph/ceph:v18...
Ceph version: ceph version 18.2.0 (5dd24139a1eada541a3bc16b6941c5dde975e26d) reef (stable)
Extracting ceph user uid/gid from container image...
Creating initial keys...
Creating initial monmap...
Creating mon...
firewalld ready
Enabling firewalld service ceph-mon in current zone...
Waiting for mon to start...
Waiting for mon...
mon is available
Assimilating anything we can from ceph.conf...
Generating new minimal ceph.conf...
Restarting the monitor...
Setting mon public_network to 172.25.0.0/16
Wrote config to /etc/ceph/ceph.conf
Wrote keyring to /etc/ceph/ceph.client.admin.keyring
Creating mgr...
Verifying port 9283 ...
Verifying port 8765 ...
Verifying port 8443 ...
firewalld ready
Enabling firewalld service ceph in current zone...
firewalld ready
Enabling firewalld port 9283/tcp in current zone...
Enabling firewalld port 8765/tcp in current zone...
Enabling firewalld port 8443/tcp in current zone...
Waiting for mgr to start...
Waiting for mgr...
mgr not available, waiting (1/15)...
mgr not available, waiting (2/15)...
mgr is available
Enabling cephadm module...
Waiting for the mgr to restart...
Waiting for mgr epoch 4...
mgr epoch 4 is available
Setting orchestrator backend to cephadm...
Generating ssh key...
Wrote public SSH key to /etc/ceph/ceph.pub
Adding key to root@localhost authorized_keys...
Adding host ceph...
Deploying mon service with default placement...
Deploying mgr service with default placement...
Deploying crash service with default placement...
Deploying ceph-exporter service with default placement...
Deploying prometheus service with default placement...
Deploying grafana service with default placement...
Deploying node-exporter service with default placement...
Deploying alertmanager service with default placement...
Enabling the dashboard module...
Waiting for the mgr to restart...
Waiting for mgr epoch 8...
mgr epoch 8 is available
Generating a dashboard self-signed certificate...
Creating initial admin user...
Fetching dashboard port number...
firewalld ready
Ceph Dashboard is now available at:

             URL: https://ceph.mshome.net:8443/
            User: admin
        Password: 12345678

Enabling client.admin keyring and conf on hosts with "admin" label
Saving cluster configuration to /var/lib/ceph/d93a8098-7f9a-11ee-a7a0-00155d58d032/config directory
Enabling autotune for osd_memory_target
You can access the Ceph CLI as following in case of multi-cluster or non-default config:

        sudo /usr/sbin/cephadm shell --fsid d93a8098-7f9a-11ee-a7a0-00155d58d032 -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.client.admin.keyring

Or, if you are only running a single cluster on this host:

        sudo /usr/sbin/cephadm shell 

Please consider enabling telemetry to help improve Ceph:

        ceph telemetry on

For more information see:

        https://docs.ceph.com/en/latest/mgr/telemetry/

Bootstrap complete.
```

查看镜像和容器
```bash
[root@ceph ~]# podman image ls
REPOSITORY                        TAG         IMAGE ID      CREATED        SIZE
quay.io/ceph/ceph                 v18         ca080bc5ec34  8 days ago     1.28 GB
quay.io/ceph/ceph-grafana         9.4.7       2c41d148cca3  7 months ago   647 MB
quay.io/prometheus/prometheus     v2.43.0     a07b618ecd1d  7 months ago   235 MB
quay.io/prometheus/alertmanager   v0.25.0     c8568f914cd2  10 months ago  66.5 MB
quay.io/prometheus/node-exporter  v1.5.0      0da6a335fe13  11 months ago  23.9 MB
[root@ceph ~]# podman ps
CONTAINER ID  IMAGE                                                                                      COMMAND               CREATED         STATUS         PORTS       NAMES
e483edfaa62e  quay.io/ceph/ceph:v18                                                                      -n mon.ceph -f --...  44 minutes ago  Up 44 minutes              ceph-d93a8098-7f9a-11ee-a7a0-00155d58d032-mon-ceph
13ac07aa9f58  quay.io/ceph/ceph:v18                                                                      -n mgr.ceph.uzpgx...  44 minutes ago  Up 44 minutes              ceph-d93a8098-7f9a-11ee-a7a0-00155d58d032-mgr-ceph-uzpgxd
9d665b3026e7  quay.io/ceph/ceph@sha256:4adccfea879f70293ded4130b5cee5092b2f499df41b7ecd5d3c31e5afc84b4b  -n client.ceph-ex...  43 minutes ago  Up 43 minutes              ceph-d93a8098-7f9a-11ee-a7a0-00155d58d032-ceph-exporter-ceph
9be90c385245  quay.io/ceph/ceph@sha256:4adccfea879f70293ded4130b5cee5092b2f499df41b7ecd5d3c31e5afc84b4b  -n client.crash.c...  43 minutes ago  Up 43 minutes              ceph-d93a8098-7f9a-11ee-a7a0-00155d58d032-crash-ceph
0c3d1094269d  quay.io/prometheus/node-exporter:v1.5.0                                                    --no-collector.ti...  43 minutes ago  Up 43 minutes              ceph-d93a8098-7f9a-11ee-a7a0-00155d58d032-node-exporter-ceph
ff9e344fbf48  quay.io/prometheus/prometheus:v2.43.0                                                      --config.file=/et...  32 minutes ago  Up 32 minutes              ceph-d93a8098-7f9a-11ee-a7a0-00155d58d032-prometheus-ceph
a79ffc25cae7  quay.io/prometheus/alertmanager:v0.25.0                                                    --cluster.listen-...  31 minutes ago  Up 31 minutes              ceph-d93a8098-7f9a-11ee-a7a0-00155d58d032-alertmanager-ceph
ba937ec01944  quay.io/ceph/ceph-grafana:9.4.7                                                            /bin/bash             31 minutes ago  Up 31 minutes              ceph-d93a8098-7f9a-11ee-a7a0-00155d58d032-grafana-ceph
```

#### 安装ceph-common
```bash
cephadm install ceph-common
```

#### 查看可用硬盘
```bash
[root@ceph ~]# ceph orch device ls
HOST  PATH      TYPE  DEVICE ID                                       SIZE  AVAILABLE  REFRESHED  REJECT REASONS  
ceph  /dev/sda  hdd   Virtual_Disk_6002248052a296d1211ce4198335f4cc  10.0G  Yes        22m ago  
```

#### 修改ceph.conf
我这里只有一块盘，ceph osd默认最少为3，所以修改配置文件如下


```text
[global]
  fsid = d93a8098-7f9a-11ee-a7a0-00155d58d032
  mon_host = [v2:172.25.16.5:3300/0,v1:172.25.16.5:6789/0]
  osd_pool_default_size = 1
  osd_pool_default_min_size = 1
  global_mon_warn_on_pool_no_redundancy = false
```

```bash
ceph config set global_osd_pool_default_size  1
ceph config set osd_pool_default_min_size 1
ceph config set global_mon_warn_on_pool_no_redundancy false
```

重启mon和mgr
```bash
podman restart {monid} {mgrid}
```

查看当前服务
```
[root@ceph ~]#  ceph orch ls
NAME           PORTS        RUNNING  REFRESHED  AGE  PLACEMENT  
alertmanager   ?:9093,9094      1/1  8m ago     92m  count:1    
ceph-exporter                   1/1  8m ago     92m  *          
crash                           1/1  8m ago     92m  *          
grafana        ?:3000           1/1  8m ago     92m  count:1    
mgr                             1/2  8m ago     92m  count:2    
mon                             1/5  8m ago     92m  count:5    
node-exporter  ?:9100           1/1  8m ago     92m  *          
prometheus     ?:9095           1/1  8m ago     92m  count:1
```

重启服务
```bash
ceph orch restart mgr
ceph orch restart mon
```

#### 可用硬盘安装osd
```bash
ceph orch apply osd --all-available-devices
```

## Ceph常用操作

### osd pool

```bash
# 创建名为rbd的osd pool,当osd个数小于5个,官方推荐pg_num=128
# 这里我只有1个osd,设置为64
ceph osd pool create rbd 64

# 查看osd pool列表
ceph osd pool ls

# 查看osd pool详情
ceph osd pool ls detail

# 给pool打rbd标识 ceph osd pool application enable {pool name} rbd
ceph osd pool application enable rbd rbd
```

### rbd

```bash
# 创建rbd块
rbd create image0 --size 10M --pool rbd --image-feature layering

# 查看rbd块详情 rbd info {pool name}/{image name}
rbd info rbd/image0

# 查看rbd块列表 rbd ls -l {poo name}
rbd ls -l rbd

# 在本机使用客户端挂载测试
sudo rbd map --image rbd/image0

# 查看rbd映射列表
rbd showmapped

# 解除rbd映射
rbd unmap rbd/image0

# 删除rbd块
rbd remove image0 --pool rbd

# 若挂载失败是因为rbd块存在内核不支持的features,可以通过如下命令禁用
sudo rbd feature disable rbd/image0 object-map fast-diff deep-flatten

# 创建加密块
echo "123456" > passphrase.txt
rbd create --size 2G rbd/luks2test
rbd encryption format rbd/luks2test luks2 passphrase.txt

# 挂载加密块，需要安装 rbd-nbd
yum install rbd-nbd
rbd -p rbd device map --image rbd/luks2test  -t nbd -o encryption-format=luks2,encryption-passphrase-file=passphrase.txt

# 卸载
rbd device unmap -t nbd  rbd/luks2test
``` 

挂载后磁盘信息如下
```text
[root@ceph ~]# lsblk
NAME                                                                                                  MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                                                                                                     8:0    0   10G  0 disk 
└─ceph--92ef9037--e062--438f--879d--d01dbdc9d719-osd--block--ca1a1c6d--a7b3--4d60--b60e--7a6f6436f718 253:2    0   10G  0 lvm  
sdb                                                                                                     8:16   0   20G  0 disk 
├─sdb1                                                                                                  8:17   0  600M  0 part /boot/efi
├─sdb2                                                                                                  8:18   0    1G  0 part /boot
└─sdb3                                                                                                  8:19   0 18.4G  0 part 
  ├─rl-root                                                                                           253:0    0 16.4G  0 lvm  /
  └─rl-swap                                                                                           253:1    0    2G  0 lvm  [SWAP]
sr0                                                                                                    11:0    1 1024M  0 rom  
rbd0                                                                                                  252:0    0   10M  0 disk 
```

### cephfs

```bash
# cephfs_data poll存储数据
ceph osd pool create cephfs_data 64

# cephfs_metadata存储元数据
ceph osd pool create cephfs_metadata 64

# 创建名为cephfs的文件系统
ceph fs new cephfs cephfs_metadata cephfs_data
```

创建后集群状态如下,这是因为cephfs需要mds组件
```text
[root@ceph ~]# ceph -s
  cluster:
    id:     d93a8098-7f9a-11ee-a7a0-00155d58d032
    health: HEALTH_ERR
            1 filesystem is offline
            1 filesystem is online with fewer MDS than max_mds
 
  services:
    mon: 1 daemons, quorum ceph (age 31m)
    mgr: ceph.uzpgxd(active, since 4d)
    mds: 0/0 daemons up
    osd: 1 osds: 1 up (since 4d), 1 in (since 4d)
 
  data:
    volumes: 1/1 healthy
    pools:   4 pools, 193 pgs
    objects: 6 objects, 449 KiB
    usage:   27 MiB used, 10 GiB / 10 GiB avail
    pgs:     193 active+clean
```

部署mds
```bash
# ceph orch apply mds {cephfs name} --placement={mds服务个数 主机名1 主机名2}
ceph orch apply mds cephfs --placement="1 ceph"
```
部署后服务如下
```text
[root@ceph ~]# ceph orch ls
NAME                       PORTS        RUNNING  REFRESHED  AGE  PLACEMENT     
alertmanager               ?:9093,9094      1/1  5s ago     4d   count:1       
ceph-exporter                               1/1  5s ago     4d   *             
crash                                       1/1  5s ago     4d   *             
grafana                    ?:3000           1/1  5s ago     4d   count:1       
mds.cephfs                                  1/1  5s ago     9s   ceph;count:1  
mgr                                         1/2  5s ago     4d   count:2       
mon                                         1/5  5s ago     4d   count:5       
node-exporter              ?:9100           1/1  5s ago     4d   *             
osd.all-available-devices                     1  5s ago     4d   *             
prometheus                 ?:9095           1/1  5s ago     4d   count:1   
```


```bash
# 挂载cephfs
mount -t ceph 172.25.16.5:6789:/ /mnt -o name=admin,secret=AQAF3E1l4CIGLRAA6/Y9tvHEdNT2sy4YvgElrA==

# 解除挂载
umount /mnt
```
```text
[root@ceph ~]# mount | grep /mnt
172.25.16.5:6789:/ on /mnt type ceph (rw,relatime,seclabel,name=admin,secret=<hidden>,fsid=d93a8098-7f9a-11ee-a7a0-00155d58d032,acl)
```

```bash
# 查看cephfs volume
ceph fs volume ls

# 查看 cephfs subvolue
ceph fs subvolume ls cephfs –group_name csi

#查看 subvolume详情
ceph fs subvolume info  cephfs  csi-vol-5a8b99c5-25b7-479a-8ab1-28a6f5ad0960 --group_name csi
```

### 用户操作

```bash
# 创建用户
ceph auth get-or-create client.test mon 'profile rbd' osd 'profile rbd pool=rbd' mgr 'allow rw'

# 修改用户权限
ceph auth caps client.test mon 'profile rbd' osd 'profile rbd pool=rbd'

# 生成用户认证文件
ceph auth get client.test -o /etc/ceph/ceph.client.test.keyring
```


```bash
创建rbd image
rbd -k /etc/ceph/ceph.client.test.keyring --id f4bbd9b8-7476-11ee-99e1-f72ccce79a2f -m 10.122.159.174:6789,10.122.159.125:6789,10.122.159.122:6789  create data-img2 --size 3G --pool pool-test --image-format 2 --image-feature layering
```





