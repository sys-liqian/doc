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
