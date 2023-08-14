# Go-ceph库使用

项目地址 [Github](https://github.com/ceph/go-ceph)

## 在系统中安装Ceph开发库

当前使用的系统

```bash
uname -a
Linux vm 5.10.0-23-amd64 #1 SMP Debian 5.10.179-2 (2023-07-14) x86_64 GNU/Linux
```

按文档说明安装Ceph开发库
```bash
apt install libcephfs-dev librbd-dev librados-dev
```

编译使用Go-ceph项目后出现error
```bash
undefined: rados.errnotconnected
```

出现该错误的原因是Go-Ceph需要使用CGO,故需要开启CGO_ENABLE,注意必须是在go env中开启此选项，编译时使用 CGO_ENABLE=1 go build 方式不行

解决上述错误后新的错误为
```bash
go-ceph@v0.15.0/rados/ioctx_octopus.go:24:2: could not determine kind of name for C.rados_set_pool_full_try
```

这是由于本地C库头文件与go-ceph不兼容,本地源版本过低无法下载高版本C库,需要更换镜像源,[参考文章](https://developer.aliyun.com/mirror/ceph?spm=a2c6h.13651102.0.0.529c1b111zMfqV)

## 安装Ceph源
```bash
apt-get install software-properties-common
wget -q -O- 'https://mirrors.aliyun.com/ceph/keys/release.asc' | sudo apt-key add -
#安装对应Ceph版本的源
apt-add-repository 'deb https://mirrors.aliyun.com/ceph/debian-pacific/ buster main'
apt update
```

安装后重新安装Ceph开发库

编译项目
```bash
#编译时指定cpeh版本
go build  -tags pacific -o csi-plugin
```