# rockylinux8 编译内核

## 安装依赖软件
```bash
dnf install -y ncurses-devel gcc make bison openssl-devel elfutils-libelf-devel flex 
```

* rockylinx 安装[dwarves](https://developer.aliyun.com/packageSearch?word=dwarves)，可以直接下载rpm包或者通过源码编译


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

## 编译

选择对应版本内核源码[下载](https://www.kernel.org/)

### kernel-5.4.268

拷贝.config内核编译文件，或者通过`make menuconfig`手动配置
```bash
tar xf linux-5.4.268.tar.xz 
cd linux-5.4.268
cp -v /boot/config-$(uname -r) .config
```

* 编译

-j 指定线程数，一般为cpu核心2倍
```
make -j 4
```

* 安装modules
```bash
make modules_install
```

* 安装内核
```bash
make install
```

* 制作rpm,rpm输出在/root/rpmbuild/RPMS/x86_64
```bash
make rpm-pkg
```

### kernel-6.7.5

[源码阿里镜像](https://mirrors.aliyun.com/linux-kernel/)

下载linux-6.7.5.tar.gz

编译6.7.5需要perl和pyton3
```bash
dnf install -y perl python3
```

编译kernel-6.7.5需要初始化git仓库
```bash
cd linux-6.7.5
git init 
git add .
git commit -m 'Init Commit'
```

```bash
make rpm-pkg -j 8
```


