# rockylinux 

```bash
# 是否满足虚拟化
yum install libvirt-client
virt-host-validate qemu 

# 硬件条件不满足,开启软件虚拟化
kubectl -n kubevirt patch kubevirt kubevirt --type=merge --patch '{"spec":{"configuration":{"developerConfiguration":{"useEmulation":true,"featureGates":["LiveMigration","Snapshot"]}}}}'

# k8s节点安装
yum install -y qemu-kvm libvirt virt-install
systemctl start libvirtd
systemctl enable libvirtd

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


# seaweedfs
mkdir /data/sea_volume

docker run -d --network host --name seaweedfs \
-v /data/sea_volume:/data \
chrislusf/seaweedfs:3.80 \
server \
-dir=/data \
-master.port=9333 \
-volume.port=8080 \
-filer \
-filer.port=8888

# helm
wget https://get.helm.sh/helm-v3.16.4-linux-amd64.tar.gz
tar -zxvf helm-v3.16.4-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm

# csi
helm -n csi template seaweedfs ./seaweedfs-csi-driver > seaweedfs-csi.yaml
kubectl -n csi apply -f seaweedfs-csi.yaml
# set default
kubectl patch sc seaweedfs-storage -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'


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
export CDI_PROXY=`kubectl -n cdi get svc -l cdi.kubevirt.io=cdi-uploadproxy -o go-template --template='{{ (index .items 0).spec.clusterIP }}'`
virtctl image-upload --image-path='/home/jupiter/workspace/kubevirt/Rocky-8-GenericCloud-Base.latest.x86_64.qcow2' --pvc-name=iso-rocky8  --pvc-size=15G --uploadproxy-url=https://$CDI_PROXY  --insecure  --wait-secs=240
```

vm.yaml
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: testvm
spec:
  runStrategy: Halted
  template:
    metadata:
      labels:
        kubevirt.io/size: small
        kubevirt.io/domain: testvm
    spec:
      domain:
        cpu:
          cores: 1
        devices:
          disks:
            - name: containerdisk
              disk:
                bus: virtio
            - name: cloudinitdisk
              disk:
                bus: virtio
          interfaces:
          - name: default
            masquerade: {}
        resources:
          requests:
            memory: 64M
          limits:
            memory: 1G
      networks:
      - name: default
        pod: {}
      volumes:
        - name: containerdisk
          containerDisk:
            image: quay.io/kubevirt/cirros-container-disk-demo
        - name: cloudinitdisk
          cloudInitNoCloud:
            userDataBase64: SGkuXG4=
```