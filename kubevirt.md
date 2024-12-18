# rockylinux 

```bash
# k8s节点安装
yum install -y qemu-kvm libvirt virt-install

# kubevirt
wget https://github.com/kubevirt/kubevirt/releases/download/v1.4.0/kubevirt-operator.yaml
wget https://github.com/kubevirt/kubevirt/releases/download/v1.4.0/kubevirt-cr.yaml
kubectl apply -f kubevirt-operator.yaml
kubectl apply -f kubevirt-cr.yaml

# virtctl
wget https://github.com/kubevirt/kubevirt/releases/download/v1.4.0/virtctl-v1.4.0-linux-amd64
mv virtctl-v1.4.0-linux-amd64 /usr/bin/virtctl
chmod +x /usr/bin/virtctl 

# cdi
wget https://github.com/kubevirt/containerized-data-importer/releases/download/v1.61.0/cdi-operator.yaml
wget https://github.com/kubevirt/containerized-data-importer/releases/download/v1.61.0/cdi-cr.yaml
kubectl apply -f cdi-operator.yaml
kubectl apply -f cdi-cr.yaml


# csi
# set default
kubectl patch sc nfs-csi -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'


# vm
wget https://kubevirt.io/labs/manifests/vm.yaml
kubectl apply -f vm.yaml

# 支持host
$ kubectl edit kubevirt kubevirt -n kubevirt
    ...
    spec:
      configuration:
        developerConfiguration:
          featureGates:
            - DataVolumes
            - HostDisk
    ...

# image
#uid=107 gid=0(root) groups=0(root),107
export CDI_PROXY=`kubectl -n cdi get svc -l cdi.kubevirt.io=cdi-uploadproxy -o go-template --template='{{ (index .items 0).spec.clusterIP }}'`
virtctl image-upload --image-path='/home/jupiter/workspace/kubevirt/Rocky-8-GenericCloud-Base.latest.x86_64.qcow2' --pvc-name=iso-rocky8  --pvc-size=3G --uploadproxy-url=https://$CDI_PROXY  --insecure  --wait-secs=240
```