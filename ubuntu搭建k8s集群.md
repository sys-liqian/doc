# k8s 安装手册

## 版本说明

ubuntu: 20.04LTS

docker: 19.03.15_3-0

kubeadm: 1.20.4-00

## 安装前准备

关闭master节点和node节点的swap

临时关闭命令: sudo swapoff -a

永久关闭: 文件/etc/fstab 删除/swap内容

docker用户组?



### 安装软件

socat_1.7.3.3-2

ebtables_2.0.11-3build1

ethtool_5.4.1

conntrack_1.4.5-2

containerd.io_1.4.4-1

docker-ce-cli_19.03.15_3-0

docker-ce_19.03.15_3-0

cri-tools_1.13.0-01

kubernetes-cni_0.8.7-00

kubelet_1.20.4-00

kubectl_1.20.4-00

kubeadm_1.20.4-00



安装命令: dpkg -i

卸载命令: dpkg -r

## 获取镜像

```bash
kube-apiserver
kube-controller-manager
kube-scheduler
kube-proxy
pause
etcd
coredns
```

## 初始化集群

运行命令:kubeadm init

如果运行成功会如下

```none
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a Pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  /docs/concepts/cluster-administration/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join <control-plane-host>:<control-plane-port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

需要在Node节点执行生成的命令: kubeadm join .........

## 安装网络附加组件Calico 

安装命令  kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

卸载命令  kubectl delete -f https://docs.projectcalico.org/manifests/calico.yaml

安装失败,卸了重安

查看是否安装成功 命令:kubectl get pods --all-namespaces

成功如下:

```text
NAME                              READY   STATUS              RESTARTS   AGE
coredns-86c58d9df4-mmjls          1/1     Running             0          6h26m
coredns-86c58d9df4-p7brk          1/1     Running             0          6h26m
etcd-promote                      1/1     Running             1          6h26m
kube-apiserver-promote            1/1     Running             1          6h26m
kube-controller-manager-promote   1/1     Running             1          6h25m
kube-proxy-6ml6w                  1/1     Running             1          6h26m
kube-scheduler-promote            1/1     Running             1          6h25m
```



## 安装kuboard可视化

```sh
安装: kubectl applay -f https://kuboard.cn/install-script/kuboard.yaml
删除:kubectl delete -f https://kuboard.cn/install-script/kuboard.yaml
```

##### 获取kuboard 登录token

```
 kubectl get secrets -n kube-system
 kubectl describe  secrets -n kube-system kuboard-user-token-hjtwg
```
