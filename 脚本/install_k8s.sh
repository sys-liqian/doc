#! /bin/sh

#自定义修改项
default_network_card_name="eth0"
docker_repo_file="/etc/yum.repos.d/docker-ce.repo"
k8s_repo_file="/etc/yum.repos.d/kubernetes.repo"

#1.设置网络
#2.修改主机名
#3.关闭防火墙并且禁用开机自启
#4.关闭selinux
#5.关闭swap,reboot
#6.安装docker
#7.安装k8s源安装kubectl,kubelet,kubeadm
#8.kubeadm生成默认配置文件
#9.kubectl init
#10. 安装calico

stop_firewall() {
  systemctl stop firewalld
  systemctl disable firewalld
}

stop_selinux() {
  sed -i 's/enforcing/disabled/' /etc/selinux/config
  setenforce 0
}

stop_swap() {

}

init_kubectl() {
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

main() {
  #  init_kubectl
  #  init_docker
  stop_firewall
}

main
