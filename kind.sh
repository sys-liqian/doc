#! /bin/sh

#自定义修改项
localIp="172.25.16.7"
gopath="/home/go"
go_package_filename="./go1.17.6.linux-amd64.tar.gz"


docker_repo_file="/etc/yum.repos.d/docker-ce.repo"

init_go() {
  if ! [ -x "$(command -v go)" ]; then
    echo 'go not installed,installing......'
    tar -C /usr/local/ -xzvf ${go_package_filename}
    echo 'create gopath'
    mkdir -p ${gopath}/src
    mkdir -p ${gopath}/bin
    mkdir -p ${gopath}/pkg
    echo 'create gopath success'
    echo 'export PATH=$PATH:/usr/local/go/bin' >>/etc/profile
    echo 'export PATH=$PATH:/home/go/bin' >>/etc/profile
    echo "export GOPATH=${gopath}" >>/etc/profile
    echo "export GOPROXY=https://goproxy.cn,direct" >>/etc/profile
    source /etc/profile
    reboot
  else
    echo 'go has been installed.'
  fi
}

init_kubectl(){
    if ! [ -x "$(command -v kubectl)" ]; then
        curl -LO https://dl.k8s.io/release/v1.24.1/bin/linux/amd64/kubectl
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    else
      echo 'kubectl has been installed.'
    fi
}

install_docker() {
  if test -f "$docker_repo_file"; then
    echo "$docker_repo_file exist."
  else
    echo 'install docker 19.03.15......'
    curl -o $docker_repo_file https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo?spm=a2c6h.25603864.0.0.29d84ca5jvb9YX
    yum install -y docker-ce-19.03.15-3.el7.x86_64
    systemctl start docker
    sleep 15
    cat >/etc/docker/daemon.json <<EOF
{
  "registry-mirrors":["https://registry.docker-cn.com","https://docker.mirrors.ustc.edu.cn"],
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
    systemctl restart docker
    systemctl enable docker
  fi
}

init_docker() {
  if ! [ -x "$(command -v docker)" ]; then
    echo 'docker not installed,installing......'
    install_docker
    echo 'docker install success.'
  else
    echo 'docker has been installed.'
  fi
}

init_kind() {
  if ! [ -x "$(command -v kind)" ]; then
    echo 'kind not installed,installing.......'
    go install sigs.k8s.io/kind@v0.16.0
  else
    echo 'kind has been installed.'
  fi
}

init_registry() {
  if test -z "$(docker ps -a | grep registry:2)"; then
    echo "registry not start,create container......"
    docker run -d -p 0.0.0.0:5000:5000 -v regsitry:/var/lib/registry --name registry -h registry --network kind registry:2
  else
    echo "registry is already running."
  fi
}

init_kind_cluster() {
  kind delete cluster
  kind create cluster --image kindest/node:v1.21.12 --config=- <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerPort: 6443
  apiServerAddress: ${localIp}
  podSubnet: 172.16.0.0/16
  serviceSubnet: 172.19.0.0/16
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 30080
    hostPort: 30080
    protocol: TCP
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
    endpoint = ["https://hub-mirror.c.163.com"]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:5000"]
    endpoint = ["http://registry:5000"]
EOF
}

copy_kubeConfig() {
  docker cp $(docker ps -a | grep kindest/node:v1.21.12 | awk '{print $1}'):/etc/kubernetes/admin.conf .
  sed -i "s/kind-control-plane/$localIp/g" admin.conf
}

main() {
  init_go
  init_kubectl
  init_docker
  init_registry
  init_kind
  init_kind_cluster
  copy_kubeConfig
}

main
