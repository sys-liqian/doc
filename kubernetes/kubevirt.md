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

container-vm.yaml
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

rocky8-pvc-vm.yaml
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: rocky8vm
  namespace: default
spec:
  runStrategy: Halted
  template:
    metadata:
      labels:
        kubevirt.io/domain: rocky8vm
    spec:
      domain:
        cpu:
          cores: 1
        devices:
          disks:
          - disk:
              bus: virtio
            name: cdromiso
          - disk:
              bus: virtio
            name: cloudinitdisk
          interfaces:
          - masquerade: {}
            model: e1000
            name: default
        machine:
          type: q35
        resources:
          requests:
            memory: 2Gi
      networks:
      - name: default
        pod: {}
      volumes:
      - name: cdromiso
        persistentVolumeClaim:
          claimName: iso-rocky8
      - cloudInitNoCloud:
          networkData: |-
            network:
              version: 1
              config:
                - type: physical
                  name: eth0
                  subnets:
                    - type: dhcp
          userData: |-
            #cloud-config
            disable_root: false
            ssh_pwauth: true
            users:
              - default
              - name: root
                lock_passwd: false
                hashed_passwd: $1$4t.w.u.X$BkdPjEOi30r85GpIaTZ8C1  # 密码:12345678
        name: cloudinitdisk

---
apiVersion: v1
kind: Service
metadata:
  name: rocky8vm
  namespace: default
spec:
  selector:
    kubevirt.io/domain: rocky8vm
  ports:
    - protocol: TCP
      port: 22      
      targetPort: 22   
      nodePort: 30001
  type: NodePort
```

## Multus CNI

```bash
git clone https://github.com/k8snetworkplumbingwg/multus-cni.git && cd multus-cni/deployments
kubectl apply -f multus-daemonset-thick-plugin.yml
# /etc/cni/net.d 生成 00-multus.conf
# /opt/cni/bin 生成 multus-shim

cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: macvlan-conf
spec:
  config: '{
      "cniVersion": "0.3.0",
      "type": "macvlan",
      "master": "eth0",
      "mode": "bridge",
      "ipam": {
        "type": "host-local",
        "subnet": "192.168.1.0/24",
        "rangeStart": "192.168.1.200",
        "rangeEnd": "192.168.1.216",
        "routes": [
          { "dst": "0.0.0.0/0" }
        ],
        "gateway": "192.168.1.1"
      }
    }'
EOF
kubectl get network-attachment-definitions

```