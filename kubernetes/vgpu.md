# VGPU

## 安装驱动

主机信息

```bash
# 系统
CentOS Linux 8

# 内核
4.18.0-305.3.1.el8.x86_64

# GPU
NVIDIA Corporation GP102GL [Tesla P40]

# CPU
Intel(R) Xeon(R) CPU E5-2650 v4 @ 2.20GHz 4核心

# MEM
32Gi
```

安装驱动

```bash
# 安装驱动需要工具
yum install -y gcc make

# 升级内核，旧版内核可能已经找不到开发包，当前为kernel-lt.x86_64 5.4.302-1.el8.elrepo
# 内核开发包放在/usr/src/kernels/$(uname -r)
yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
yum --disablerepo="*" --enablerepo="elrepo-kernel" list available | grep kernel-lt
yum -y --enablerepo=elrepo-kernel install kernel-lt kernel-lt-devel

# 查看可用内核
grubby --info=ALL | grep ^kernel
# 查看默认内核
grubby --default-kernel
# 设置默认内核
grubby --set-default /boot/vmlinuz-5.4.302-1.el8.elrepo.x86_64 
# 确认默认内核修改成功
grub2-editenv list
# 重启
reboot

# 关闭系统自带的nouveau驱动
sudo bash -c  "echo blacklist nouveau > /etc/modprobe.d/blacklist-nvidia-nouveau.conf"
sudo bash -c "echo options nouveau modeset=0 >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf"
dracut --force
reboot

# 检查nouveau驱动是否禁用成功，无输出则成功
lsmod | grep nouveau

# 安装驱动
wget https://us.download.nvidia.com/tesla/560.35.03/NVIDIA-Linux-x86_64-560.35.03.run
chmod +x NVIDIA-Linux-x86_64-560.35.03.run
./NVIDIA-Linux-x86_64-560.35.03.run

nvidia-smi
```

## 安装Docker26.1.3

```bash
# 查看当前是否已安装Docker
rpm -aq | grep docker
# 安装Docker源
curl -o /etc/yum.repos.d/docker-ce.repo  https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo?spm=a2c6h.25603864.0.0.29d84ca5jvb9YX
# 查看可用Docker版本
yum list docker-ce --showduplicates |sort -r
# 安装docker
yum install docker-ce-26.1.3-1.el8.x86_64
systemctl start docker
systemctl enable docker
```

## 安装Nvidia-container-tool-kit

```bash
# 安装源
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
    tee /etc/yum.repos.d/nvidia-container-toolkit.repo
dnf-config-manager --enable nvidia-container-toolkit-experimental

# 安装nvidia-container-tool
export NVIDIA_CONTAINER_TOOLKIT_VERSION=1.18.1-1
dnf install -y \
    nvidia-container-toolkit-${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
    nvidia-container-toolkit-base-${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
    libnvidia-container-tools-${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
    libnvidia-container1-${NVIDIA_CONTAINER_TOOLKIT_VERSION}

# nvidia工具将docker runtime设置为nvidia 修改了/etc/docker/daemon.json
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker
```

## Docker 启动GPU容器测试

```bash
docker pull registry.cn-hangzhou.aliyuncs.com/liqian35/cuda:12.0.1-runtime-ubuntu22.04
docker run --rm --gpus all  registry.cn-hangzhou.aliyuncs.com/liqian35/cuda:12.0.1-runtime-ubuntu22.04 nvidia-smi
```

## 使用CDI 挂载GPU

```bash
# 生成CDI文件
# /etc/cdi 目录一般用于存放静态CDI设备描述文件
# /如果cdi存在动态更新,一般放在/var/run/cdi
nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
```

如果使用containerd,修改/etc/containerd/config.toml 添加如下配置后重启

```
[plugins."io.containerd.grpc.v1.cri"]
  enable_cdi = true
  cdi_spec_dirs = ["/etc/cdi", "/var/run/cdi"]
```

如果使用Docker,修改/etc/docker/daemon.json 如下后重启

```json
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "args": [],
            "path": "nvidia-container-runtime"
        }
    },
    "features": {
        "cdi": true
    }
}
```

使用cdi启动容器


```bash
docker run --device nvidia.com/gpu=all registry.cn-hangzhou.aliyuncs.com/liqian35/cuda:12.0.1-runtime-ubuntu22.04 nvidia-smi
docker run --device nvidia.com/gpu=0 registry.cn-hangzhou.aliyuncs.com/liqian35/cuda:12.0.1-runtime-ubuntu22.04 nvidia-smi
docker run --device nvidia.com/gpu=GPU-07f83f9b-4f2f-6c91-791e-293817b026c0 registry.cn-hangzhou.aliyuncs.com/liqian35/cuda:12.0.1-runtime-ubuntu22.04 nvidia-smi
```

## 安装go开发环境

```bash
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.25.3.linux-amd64.tar.gz
```

编辑/etc/profile
```env
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/root/go
export PATH=$PATH:/root/go/bin

export GOPROXY=https://goproxy.cn,direct
export GO111MODULE=auto
export CGO_ENABLED=1
```

## FAQ

### 业务pod启动后报错libcuda.so.1 not found

#### 原因1： GPU Operater 和 volcano-vgpu-device-plugin 都在节点上部署，互相影响

#### 原因2： nvidia-container-runtime配置了accept-nvidia-visible-devices-envvar-when-unprivileged = false 

默认`accept-nvidia-visible-devices-envvar-when-unprivileged`的值为`true`, 允许非特权容器访问`NVIDIA_VISIBLE_DEVICES`环境变量。如果将其设置为`false`，则非特权容器将无法访问该环境变量，从而导致容器内的应用程序无法识别和使用GPU设备。

设置`accept-nvidia-visible-devices-envvar-when-unprivileged = false` 是因为在直通模式中（使用GPU Operator），防止在一个pod中获取到所有的GPU卡。

#### 相关ISSUES

[文档 ](https://docs.google.com/document/d/1zy0key-EL6JH50MZgwg96RPYxxXXnVUdxLZwGiyqLd8/edit?pli=1&tab=t.0)

[ISSUES](https://github.com/NVIDIA/k8s-device-plugin/issues/61)

### volcano-vgpu-device-plugin 上报 volcano.sh/vgpu-memory 为 0

#### 原因: gpu-memory-factor 设置过小

gpu-memory-factor 默认为1M，H800,V100等大显存卡，使用vgpu会虚拟出非常多虚拟设备，导致kubelet和device-plugin通信时，调用ListAndWathc的消息体返回超过4M限制，kubelet会忽略掉这次更新，导致上报的资源为0


kubelet log
```
listAndWatch ended unexpected: rpc error: code = ResourceExhausted desc = grpc: received message larger than max (6291456 vs. 4194304)
```


#### 相关ISSUES

[ISSUES1](https://github.com/Project-HAMi/volcano-vgpu-device-plugin/issues/18)


[ISSUES1](https://github.com/volcano-sh/devices/issues/19)

### 查询GPU uuid

```bash
nvidia-smi --query-gpu=uuid --format=csv
```

### kubelet 报错找不到nvidia runtime

```
Error syncing pod, skipping" err="failed to "CreatePodSandbox" for "pod1_default(50ff3801-020f-4179-b5d6-3d2cb38e8892)" with CreatePodSandboxError: "Failed to create sandbox for pod "pod1_default(50ff3801-020f-4179-b5d6-3d2cb38e8892)": rpc error: code = Unknown desc = RuntimeHandler "nvidia" not supported" pod="default/pod1" podUID="50ff3801-020f-4179-b5d6-3d2cb38e8892"
```

解决办法: 设置docker默认runtime为nvidia

/etc/docker/daemon.json
```
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "args": [],
            "path": "nvidia-container-runtime"
        }
    }
}
```