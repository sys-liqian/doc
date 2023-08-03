## 内核升级

```bash
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
yum install -y https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
yum --enablerepo=elrepo-kernel list | grep kernel-lt
yum --enablerepo=elrepo-kernel install kernel-lt
```

编译驱动需要内核开发包
```bash
yum --enablerepo=elrepo-kernel install kernel-lt-devel
```
elrepo库中只包含当前最新的驱动和开发包，若需指定版本使用该地址下载地址
```
http://193.49.22.109/elrepo/kernel/el7/x86_64/RPMS/
```

## GCC升级
安装nvidia驱动时，应保持编译内核的gcc版本与系统当前gcc版本一致

### 查看当前内核gcc版本
```bash
cat /proc/version
#Linux version 5.4.186-1.el7.elrepo.x86_64 (mockbuild@Build64R7) (gcc version 9.3.1 20200408 (Red Hat 9.3.1-2) (GCC)) #1 SMP Fri Mar 18 09:17:21 EDT 2022
```

### 升级gcc,只在当前bash有效
```bash
yum install -y centos-release-scl
yum list | grep gcc
yum install -y devtoolset-9-gcc
source /opt/rh/devtoolset-9/enable
```

## 驱动安装

### NVIDIA-驱动、CUDA下载地址
```
# 驱动
https://www.nvidia.cn/Download/index.aspx?lang=cn
# cuda(非必须,编译GPU-manager项目需要)
https://developer.nvidia.com/cuda-downloads
```

### 查看PCI设备-NVIDIA显卡是否安装
```bash
lspci | grep NVIDIA
#04:00.0 3D controller: NVIDIA Corporation GV100GL [Tesla V100 PCIe 32GB] (rev a1)
```

### 查看NVIDIA驱动是否已经存在
```bash
lsmod | grep nvidia
# nvidia_drm             61440  0 
# nvidia_modeset       1150976  1 nvidia_drm
# nvidia              39129088  1 nvidia_modeset
# drm_kms_helper        176128  4 qxl,nvidia_drm
# drm                   495616  6 drm_kms_helper,qxl,nvidia,nvidia_drm,ttm
```

### 查看NVIDIA驱动文件是否存在
```bash
#查看系统当前内核
uname -r
#5.4.186-1.el7.elrepo.x86_64

#查看内核中驱动目录
ll /lib/modules/5.4.186-1.el7.elrepo.x86_64/kernel/drivers/video/
# drwxr-xr-x 2 root root     4096 Dec 22  2022 backlight
# drwxr-xr-x 3 root root       93 Dec 22  2022 fbdev
# -rw-r--r-- 1 root root  5877904 Aug  2 18:16 nvidia-drm.ko
# -rw-r--r-- 1 root root 59219432 Aug  2 18:16 nvidia.ko
# -rw-r--r-- 1 root root  2227456 Aug  2 18:16 nvidia-modeset.ko
# -rw-r--r-- 1 root root   391536 Aug  2 18:16 nvidia-peermem.ko
# -rw-r--r-- 1 root root 53215432 Aug  2 18:16 nvidia-uvm.ko
```

### NVIDIA驱动安装
驱动安装要求系统以非UEFI方式安装
```bash
#内核版本:5.4.186-1.el7.elrepo.x86_64,驱动版本: NVIDIA-Linux-x86_64-510.108.03.run，CUDA Version: 11.6 
chmod +x  NVIDIA-Linux-x86_64-510.108.03.run
./NVIDIA-Linux-x86_64-510.108.03.run
#内核版本:3.10.0-1160.53.1.el7.x86_64，驱动版本:NVIDIA-Linux-x86_64-470.199.02.run ,CUDA Version: 11.4 
```

### 查看NVIDIA显卡运行信息
```bash
nvidia-smi
#如果该命令有任何错误输出,尝试重新加载驱动
modeprobe nvidia
```

## 查看系统是否以UEFI方式安装
```bash
dmesg | grep EFI
```



