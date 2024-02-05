# rockylinux8 编译内核

## 安装依赖软件
```bash
dnf install -y ncurses-devel gcc make bison openssl-devel elfutils-libelf-devel flex 
```

* rockylinx 源码安装[dwarves](https://developer.aliyun.com/packageSearch?word=dwarves) 

```bash
dnf install -y rpm-build cmake
dnf --enablerepo=powertools install -y libdwarves1
```

* 源码[下载](https://mirrors.aliyun.com/rockylinux/8.9/devel/source/tree/Packages/d/dwarves-1.22-1.el8.src.rpm?spm=a2c6h.13651111.0.0.7f152f70m7OUI2&file=dwarves-1.22-1.el8.src.rpm)

* 编译
```bash
rpmbuild --rebuild dwarves-1.22-1.el8.src.rpm 
```

* 安装
```bash
cd /root/rpmbuild/RPMS/x86_64/
rpm -ivh dwarves-1.22-1.el8.x86_64.rpm 
```

## 内核源码[下载](https://www.kernel.org/)

选择对应版本内核tarball下载

* 解压
```bash
tar xf linux-5.4.268.tar.xz 
```

* 拷贝配置
```bash
# 按需要修改.config
cp -v /boot/config-$(uname -r) .config
```

* 编译
```
# -j 指定线程数，一般为cpu核心2倍
make -j 4
```


