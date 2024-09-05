# Rocky8 kubernetes 1.31.x

安装docker
```bash
curl -o /etc/yum.repos.d/docker-ce.repo  https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo?spm=a2c6h.25603864.0.0.29d84ca5jvb9YX
yum list docker-ce --showduplicates |sort -r
yum install -y docker-ce
mkdir /etc/docker
cat <<EOF >/etc/docker/daemon.json 
{
  "registry-mirrors":["https://registry.docker-cn.com","https://docker.mirrors.ustc.edu.cn","https://ustc-edu-cn.mirror.aliyuncs.com","https://qbd2mtyh.mirror.aliyuncs.com"],
  "insecure-registries":[],
  "data-root": "/data/docker"
}
EOF
systemctl daemon-reload
systemctl restart docker
systemctl enable docker
```
---
内核参数修改，关闭swap
```bash
swapoff -a
modprobe br_netfilter
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl -p /etc/sysctl.d/k8s.conf
sed -i 's/enforcing/disabled/' /etc/selinux/config
setenforce 0
```
---
[安装kubernetes源](https://developer.aliyun.com/mirror/kubernetes?spm=a2c6h.13651102.0.0.73281b11k7W5De)
```bash
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.31/rpm/repodata/repomd.xml.key
EOF
```
安装kubeadm,kubelet,kubectl
```bash
yum install -y kubelet-1.31.0 kubeadm-1.31.0 kubectl-1.31.0  --nogpgcheck
systemctl enable kubelet && systemctl start kubelet
```
---
安装[cri-docker](https://github.com/Mirantis/cri-dockerd/releases)
```bash
tar -xf cri-dockerd-0.3.15.amd64.tgz
mv cri-dockerd/cri-dockerd /usr/bin/
chmod +x /usr/bin/cri-dockerd
```

kubernetes-1.31使用pause:3.10
```bash
kubeadm config images list
```

cri-docker配置服务文件
```bash
cat <<EOF > /usr/lib/systemd/system/cri-docker.service
[Unit]
Description=CRI Interface for Docker Application Container Engine
Documentation=https://docs.mirantis.com
After=network-online.target firewalld.service docker.service
Wants=network-online.target
Requires=cri-docker.socket
[Service]
Type=notify
ExecStart=/usr/bin/cri-dockerd --network-plugin=cni --pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.10
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
cri-docker配置Socket文件
```bash
cat <<EOF > /usr/lib/systemd/system/cri-docker.socket
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
启动cri-dockerd
```bash
systemctl daemon-reload
systemctl enable cri-docker --now
systemctl is-active cri-docker
```
---
生成kubeadm-config文件,只在主节点操作
```bash
kubeadm config print init-defaults  > kubeadm-config.yaml
```

### 修改kubeadm-config.yaml
只在主节点操作
```yaml
apiVersion: kubeadm.k8s.io/v1beta4
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
  advertiseAddress: 123.56.15.212 # master ip
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///var/run/cri-dockerd.sock #cri-dockerd

  imagePullPolicy: IfNotPresent
  imagePullSerial: true
  name: iZ2zedls58hdl5j2scl4byZ # 主机名
  taints: null
timeouts:
  controlPlaneComponentHealthCheck: 4m0s
  discovery: 5m0s
  etcdAPICall: 2m0s
  kubeletHealthCheck: 4m0s
  kubernetesAPICall: 1m0s
  tlsBootstrap: 5m0s
  upgradeManifests: 5m0s
---
apiServer: {}
apiVersion: kubeadm.k8s.io/v1beta4
caCertificateValidityPeriod: 87600h0m0s
certificateValidityPeriod: 8760h0m0s
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager: {}
dns: {}
encryptionAlgorithm: RSA-2048
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.aliyuncs.com/google_containers #阿里镜像库
kind: ClusterConfiguration
kubernetesVersion: 1.31.0
networking:
  dnsDomain: cluster.local
  serviceSubnet: 10.96.0.0/12
proxy: {}
```
init,只在主节点操作
```bash
kubeadm init --config=./kubeadm-config.yaml 
```

join,只在从节点操作
```bash
kubeadm join 10.120.68.68:6443 --token abcdef.0123456789abcdef --discovery-token-ca-cert-hash sha256:855a5a7df823abbe6eb50bd5450874f9310de156d7585b8cd41576f8a1fce83e  --cri-socket /var/run/cri-dockerd.sock 
```
kubectl bash补全
```bash
yum install -y bash-completion
source /usr/share/bash-completion/bash_completion
echo 'source <(kubectl completion bash)' >>~/.bashrc
source /usr/share/bash-completion/bash_completion
```

拷贝kubeconfig
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

安装calico

[文档地址](https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises#install-calico-with-kubernetes-api-datastore-50-nodes-or-less) 使用Manifest安装

当前安装版本为3.28.1,并且k8s pod使用的是默认的cidr(192.168.0.0/16),如果不是默认需要修改(CALICO_IPV4POOL_CIDR)

kubernetes清理
```bash
kubeadm reset
systemctl stop kubelet
systemctl disable kubelet
rm -rf /etc/systemd/system/kubelet.service
rm -rf /etc/systemd/system/kube*
sudo yum remove -y kubeadm kubectl kubelet kubernetes-cni kube*   
sudo yum autoremove -y
sudo rm -rf ~/.kube
sudo rm -rf /etc/kubernetes/
sudo rm -rf /var/lib/kube*
sudo rm -rf /etc/lib/etcd
sudo rm -rf /var/lib/etcd
```
