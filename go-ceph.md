# go-ceph库使用


## Debian安装go-ceph

```bash
uname -a
Linux vm 5.10.0-23-amd64 #1 SMP Debian 5.10.179-2 (2023-07-14) x86_64 GNU/Linux
```
安装Ceph开发库
```bash
apt install libcephfs-dev librbd-dev librados-dev
```
编译使用go-ceph项目后出现error
```bash
undefined: rados.errnotconnected
```
出现该错误的原因是go-ceph需要使用CGO,故需要开启CGO_ENABLE,注意必须是在go env中开启此选项，编译时使用 CGO_ENABLE=1 go build 方式不行

若出现以下错误：
```bash
go-ceph@v0.15.0/rados/ioctx_octopus.go:24:2: could not determine kind of name for C.rados_set_pool_full_try
```
这是由于本地C库头文件与go-ceph不兼容,本地源版本过低无法下载高版本C库,需要更换镜像源,[参考文章](https://developer.aliyun.com/mirror/ceph?spm=a2c6h.13651102.0.0.529c1b111zMfqV)

安装Ceph源,选择对应版本，安装后重新安装Ceph开发库
```bash
apt-get install software-properties-common
wget -q -O- 'https://mirrors.aliyun.com/ceph/keys/release.asc' | sudo apt-key add -
apt-add-repository 'deb https://mirrors.aliyun.com/ceph/debian-pacific/ buster main'
apt update
apt install libcephfs-dev librbd-dev librados-dev
```
编译项目，编译时指定cpeh版本
```bash
go build -tags pacific -o csi-plugin
```

## 在ARM麒麟或Rocylinux中安装Ceph开发库
NeoKylin
```bash
uname -a
Linux earthgod 4.19.90-25.16.v2101.ky10.aarch64 #1 SMP Tue Jun 7 11:41:28 CST 2022 aarch64 aarch64 aarch64 GNU/Linux
```
Rocylinux
```bash
Linux cnoc 4.18.0-477.10.1.el8_8.x86_64 #1 SMP Tue May 16 11:38:37 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux
```

Ceph和go-ceph版本支持对应关系，可在[Github](https://github.com/ceph/go-ceph)查看

按需更改一下ceph.repo中rpm包版本，[镜像源](https://mirrors.ustc.edu.cn/ceph/)

```bash
cat <<EOF >/etc/yum.repos.d/ceph.repo
[ceph]
name=Ceph packages for $basearch
baseurl=https://mirrors.ustc.edu.cn/ceph/rpm-16.2.7/el8/$basearch
enabled=1
priority=2
gpgcheck=1
gpgkey=https://mirrors.ustc.edu.cn/ceph/keys/release.asc

[ceph-noarch]
name=Ceph noarch packages
baseurl=https://mirrors.ustc.edu.cn/ceph/rpm-16.2.7/el8/noarch
enabled=1
priority=2
gpgcheck=1
gpgkey=https://mirrors.ustc.edu.cn/ceph/keys/release.asc

[ceph-source]
name=Ceph source packages
baseurl=https://mirrors.ustc.edu.cn/ceph/rpm-16.2.7/el8/SRPMS
enabled=0
priority=2
gpgcheck=1
gpgkey=https://mirrors.ustc.edu.cn/ceph/keys/release.asc
EOF
```

```bash
dnf install libcephfs-devel librbd-devel librados-devel
```