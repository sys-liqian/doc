# Velero使用和原理

## 环境
kubernetes: 1.21.x

velero storage: minio

kubernetes storage: ceph

velero client version: v1.10.3

velero plugin for aws: v1.6.2

velero plugin for csi: v0.3.0

## Velero安装

### 创建S3 Secret File
```
cat > /root/credentials-velero << EOF
[default]
aws_access_key_id=admin
aws_secret_access_key=123456
EOF
```

### 使用CSI Snapshot备份
先决条件

kubernetes中安装ceph-csi(provider、attacher、snapshot-controller、snap-shotter、node-driver-registrar、plugin)

kubernetes集群中安装snapshot crd(volumesnapshotclass、volumesnapshot、volumesnapshotcontents)

1. 安装
```
velero install \
--features=EnableCSI \
--provider aws \
--bucket velero \
--image velero/velero:v1.10.3 \
--plugins velero/velero-plugin-for-aws:v1.6.2,velero/velero-plugin-for-csi:v0.3.0 \
--namespace velero \
--secret-file /root/credentials-velero \
--use-volume-snapshots=true \
--kubeconfig=/root/.kube/config \
--backup-location-config region=us-west-1,s3ForcePathStyle="true",s3Url=https://s3.com
```

2. 在VolumeSnapshotClass上打labels提供给velero使用
```
velero.io/csi-volumesnapshot-class: "true"
```

3. 备份
```
velero backup create backup-1 --include-namespaces default
```

4. 恢复
```
velero restore create --from-backup backup-1
```

### 使用文件系统备份
1. 安装
```
velero install \
--provider aws \
--bucket velero \
--image velero/velero:v1.10.3 \
--plugins velero/velero-plugin-for-aws:v1.6.2 \
--namespace velero \
--secret-file /root/credentials-velero \
--use-volume-snapshots=false \
--kubeconfig=/root/.kube/config \
--backup-location-config region=us-west-1,s3ForcePathStyle="true",s3Url=https://s3.com \
--use-node-agent
```
2. 给需要备份volume的pod打注解
```
kubectl -n default annotate pod/nginx-c5d8c77ff-l69p5 backup.velero.io/backup-volumes=pvc1,pvc2
```
3. 备份
```
velero backup create backup-1 --include-namespaces default --default-volumes-to-fs-backup=true
```
4. 恢复
```
velero restore create --from-backup backup-1
```


