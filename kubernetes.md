# Rocky8 kubernetes 1.25.x

## 环境准备

关闭swap，注释掉/etc/fstab中swap配置
```bash
systemctl stop firewalld  
systemctl disable firewalld
sed -i 's/enforcing/disabled/' /etc/selinux/config
setenforce 0
```
然后重启机器

## 内核参数修改
```bash
modprobe br_netfilter

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl -p /etc/sysctl.d/k8s.conf
```

## 安装Cri-dockerd[下载地址](https://github.com/Mirantis/cri-dockerd/releases)
```bash
tar -xf cri-dockerd-0.3.4.amd64.tgz 
mv cri-dockerd/cri-dockerd /usr/bin/
chmod +x /usr/bin/cri-dockerd
```
### 配置启动文件
pause:3.8 具体使用哪个版本可以用以下命令确认
```bash
kubeadm config images list
```

```bash
cat <<"EOF" > /usr/lib/systemd/system/cri-docker.service
[Unit]
Description=CRI Interface for Docker Application Container Engine
Documentation=https://docs.mirantis.com
After=network-online.target firewalld.service docker.service
Wants=network-online.target
Requires=cri-docker.socket
[Service]
Type=notify
ExecStart=/usr/bin/cri-dockerd --network-plugin=cni --pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.8
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutSec=0
RestartSec=2
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
[Install]
WantedBy=multi-user.target
EOF
```
### 配置Socket文件
```bash
cat <<"EOF" > /usr/lib/systemd/system/cri-docker.socket
[Unit]
Description=CRI Docker Socket for the API
PartOf=cri-docker.service
[Socket]
ListenStream=%t/cri-dockerd.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker
[Install]
WantedBy=sockets.target
EOF
```
### 启动cri-dockerd
```bash
systemctl daemon-reload
systemctl enable cri-docker --now
systemctl is-active cri-docker
```


## 安装kubeadm、kubelet、kubectl

### 安装源
```bash
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

### 安装软件
```bash
yum install kubelet-1.25.12 kubeadm-1.25.12 kubectl-1.25.12  --nogpgcheck
systemctl enable kubelet && systemctl start kubelet
```
### 生成kubeadm-config文件
只在主节点操作
```bash
kubeadm config print init-defaults  > kubeadm-config.yaml
```

### 修改kubeadm-config.yaml
只在主节点操作
```yaml
apiVersion: kubeadm.k8s.io/v1beta3
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 10.120.68.68 #master节点ip
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///var/run/cri-dockerd.sock #cri-dockerd socket地址
  imagePullPolicy: IfNotPresent
  name: peklppaasv100-kvm1 #hostname
  taints: null
---
apiServer:
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta3
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager: {}
dns: {}
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.aliyuncs.com/google_containers #阿里镜像库
kind: ClusterConfiguration
kubernetesVersion: 1.25.12 #k8s版本
networking:
  dnsDomain: cluster.local
  serviceSubnet: 10.96.0.0/12
scheduler: {}
```

### 初始化
只在主节点操作
```bash
kubeadm init --config=./kubeadm-config.yaml 
```

### JOIN
只在从节点操作
```bash
kubeadm join 10.120.68.68:6443 --token abcdef.0123456789abcdef --discovery-token-ca-cert-hash sha256:855a5a7df823abbe6eb50bd5450874f9310de156d7585b8cd41576f8a1fce83e  --cri-socket /var/run/cri-dockerd.sock 
```

### kubectl bash补全
```bash
yum install bash-completion
source /usr/share/bash-completion/bash_completion
echo 'source <(kubectl completion bash)' >>~/.bashrc
source /usr/share/bash-completion/bash_completion
```

### 拷贝kubeconfig
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## 安装calico

[文档地址](https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises#install-calico-with-kubernetes-api-datastore-50-nodes-or-less) 使用Manifest安装

当前安装版本为3.26.1,并且k8s pod使用的是默认的cidr(192.168.0.0/16),如果不是默认需要修改(CALICO_IPV4POOL_CIDR)

## kubernets清理
```bash
sudo yum remove -y kubeadm kubectl kubelet kubernetes-cni kube*   
sudo yum autoremove -y

systemctl stop kubelet
systemctl disable kubelet
rm -rf /etc/systemd/system/kubelet.service
rm -rf /etc/systemd/system/kube*

sudo rm -rf ~/.kube
sudo rm -rf /etc/kubernetes/
sudo rm -rf /var/lib/kube*

sudo rm -rf /etc/lib/etcd
sudo rm -rf /var/lib/etcd
```