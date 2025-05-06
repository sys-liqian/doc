# unshare

```bash
unshare --ipc --uts --net  --mount --root /home/unshare_test/ubuntu --pid --mount-proc --fork bash
```

--mount 用于创建新的mount namespace

--root 指定文件系统的根目录

--mount-proc 专门用于挂载 /proc 文件系统到新的namespace

注：如果unshare 版本过低没有 --root参数,需要安装最新版本的util-linux
[Github](https://github.com/util-linux/util-linux)

Namespace:

* IPC ： System V IPC(信号量，消息队列和共享内存) 和 POSIX message queues
* NetWork ：Network Devices, stacks, ports (网络设备，网络栈，端口)
* Mount : Mount points (文件系统与挂载点)
* PID ： Process IDs (进程ID,使不同namespece可以拥有相同的PID)
* User : User and Group IDs (用户和用户组)
* UTS : Hostname and NIS domian name (主机名和NIS域名)
* Cgroup ：Cgroup root dir (Cgroup根目录)，kernel 4.6 以后添加

---

## 测试

本机系统环境
```bash
cat /proc/version
Linux version 5.15.0-116-generic (buildd@lcy02-amd64-015) (gcc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0, GNU ld (GNU Binutils for Ubuntu) 2.38) #126-Ubuntu SMP Mon Jul 1 10:14:24 UTC 2024
```
制作目标系统rockylinx
```bash
docker run -d --name rockylinux quay.io/rockylinux/rockylinux:8
docker export rockylinux -o rockylinux.tar
docker rm -f rockylinux
tar -xvf rockylinux.tar -C {目标地址}
```
使用unshare进行隔离，在ubuntu上模拟rockylinux
```bash
unshare --ipc --uts --net  --mount --pid --mount-proc --fork --root {刚才解压的目标地址}  bash
```

# nsenter

```bash
root@installerdev03:/proc/1414429/ns# nsenter --help

Usage:
 nsenter [options] [<program> [<argument>...]]

Run a program with namespaces of other processes.

Options:
 -a, --all              enter all namespaces
 -t, --target <pid>     target process to get namespaces from
 -m, --mount[=<file>]   enter mount namespace
 -u, --uts[=<file>]     enter UTS namespace (hostname etc)
 -i, --ipc[=<file>]     enter System V IPC namespace
 -n, --net[=<file>]     enter network namespace
 -p, --pid[=<file>]     enter pid namespace
 -C, --cgroup[=<file>]  enter cgroup namespace
 -U, --user[=<file>]    enter user namespace
 -T, --time[=<file>]    enter time namespace
 -S, --setuid <uid>     set uid in entered namespace
 -G, --setgid <gid>     set gid in entered namespace
     --preserve-credentials do not touch uids or gids
 -r, --root[=<dir>]     set the root directory
 -w, --wd[=<dir>]       set the working directory
 -F, --no-fork          do not fork before exec'ing <program>
 -Z, --follow-context   set SELinux context according to --target PID
```

可以在/proc/{pid}/ns 下查询进程的namespace文件描述符
```bash
# 查看容器 minio的进程ID,进程ID为3595
[earthgod@sldzl7tfqjt /]$ docker inspect minio | jq .[0].State.Pid
3595
```
mount namespce
* 宿主机
```bash
[earthgod@sldzl7tfqjt /]$ pwd 
/
[earthgod@sldzl7tfqjt /]$ ls
bin    cybereason.server.ipc      dev   lib    mnt   root             sbin  tmp  WATCH_DOG_SIM_FILE.empty
boot   cybereason.server.ipc_ctl  etc   lib64  opt   run              srv   usr
build  data                       home  media  proc  sacp_salt_agent  sys   var
```
* 容器
```bash
[root@sldzl7tfqjt ~]# sudo nsenter -m -t 3595
[root@sldzl7tfqjt /]# pwd
/
[root@sldzl7tfqjt /]# ls
bin   data  etc   lib    licenses    media  opt   root  sbin  sys  usr
boot  dev   home  lib64  lost+found  mnt    proc  run   srv   tmp  var
```
uts namespace
* 宿主机
```bash
[root@sldzl7tfqjt ~]# hostname
sldzl7tfqjt
```
* 容器
```bash
[root@sldzl7tfqjt ~]# sudo nsenter -u -t 3595
[root@a26372cf5e37 ~]# hostname
a26372cf5e37
```
ipc namespace
* 宿主机
```bash
[root@sldzl7tfqjt ~]# ipcs

------ Message Queues --------
key        msqid      owner      perms      used-bytes   messages    

------ Shared Memory Segments --------
key        shmid      owner      perms      bytes      nattch     status      
0x00000000 0          zabbix     600        657056     9          dest         
0x00000000 2          zabbix     600        101288     3                       

------ Semaphore Arrays --------
key        semid      owner      perms      nsems     
0x00000000 3          zabbix     600        14
```
* 容器
```bash
[root@sldzl7tfqjt ~]# sudo nsenter -i -t 3595
[root@sldzl7tfqjt ~]# ipcs

------ Message Queues --------
key        msqid      owner      perms      used-bytes   messages    

------ Shared Memory Segments --------
key        shmid      owner      perms      bytes      nattch     status      

------ Semaphore Arrays --------
key        semid      owner      perms      nsems  
```
network namespace
* 宿主机
```bash
[root@sldzl7tfqjt ~]# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether fa:16:3e:93:e4:a8 brd ff:ff:ff:ff:ff:ff
    inet 10.122.166.104/24 brd 10.122.166.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::f816:3eff:fe93:e4a8/64 scope link 
       valid_lft forever preferred_lft forever
3: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:6a:41:83:68 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:6aff:fe41:8368/64 scope link 
       valid_lft forever preferred_lft forever
```
* 容器
```bash
[root@sldzl7tfqjt ~]# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
10: eth0@if11: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:ac:11:00:03 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.17.0.3/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:acff:fe11:3/64 scope link 
       valid_lft forever preferred_lft forever
```
pid namespace

* 待验证，允许不同namespace存在相同的PID

# cgroup



```bash
# 运行一个容器限制cpu和内存
docker run -it -m 512m --cpus 1 --name tst centos:centos7

# 查看容器id
docker inspect tst | jq .[0].Id -r


# 若docker使用systemd管理cgroup
# 则容器的的cgroup的文件地址在/sys/fs/cgroup/cpu/system.slice/docker-{containerId}.scope目录下
cat /etc/docker/daemon.json 
{
  "registry-mirrors":["https://registry.docker-cn.com"],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "insecure-registries":[],
  "data-root": "/data/docker"
}


# 查看cpu限制 /sys/fs/cgroup/cpu/system.slice/docker-{containerId}.scope
# 100000 单位ns = 100ms 表示在 100ms内可以使用 100ms的cpu 即 100% ，即 1个cpu
cd /sys/fs/cgroup/cpu/system.slice/docker-d3b139e99dee1fb59c1796bbf9d2ad729a4e4fd298fb32529fbb9c632a30c4af.scope
cat cpu.cfs_quota_us
100000

# 查看memory限制 /sys/fs/cgroup/memory//system.slice/docker-{containerId}.scope
# memory.limit_in_bytes=536870912=512m
cd /sys/fs/cgroup/memory/system.slice/docker-d3b139e99dee1fb59c1796bbf9d2ad729a4e4fd298fb32529fbb9c632a30c4af.scope
cat memory.limit_in_bytes 
536870912 

# 若使用docker管理cgroup
# 则容器的cgroup文件默认在/sys/fs/cgroup/cpu/docker/{containerId}目录下
cat /etc/docker/daemon.json 
{
    "storage-driver": "overlay2",
    "log-opts": {
      "max-file": "2",
      "max-size": "256m"
    },
    "data-root": "/data/docker",
    "live-restore": true
}

# 查看该cgroup下的所有进程id
cat cgroup.procs 
```