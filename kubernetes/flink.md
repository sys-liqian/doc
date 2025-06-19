# Flink

## k8s部署

```bash
docker pull quay.io/jetstack/cert-manager-controller:v1.8.2
docker pull quay.io/jetstack/cert-manager-webhook:v1.8.2
docker pull quay.io/jetstack/cert-manager-cainjector:v1.8.2
kubectl create -f https://github.com/jetstack/cert-manager/releases/download/v1.8.2/cert-manager.yaml

wget https://get.helm.sh/helm-v3.18.3-linux-amd64.tar.gz
tar -zxvf helm-v3.18.3-linux-amd64.tar.gz
mv linux-amd64/helm /usr/bin/helm
wget https://downloads.apache.org/flink/flink-kubernetes-operator-1.12.0/flink-kubernetes-operator-1.12.0-helm.tgz
tar -zxvf flink-kubernetes-operator-1.12.0-helm.tgz
cd flink-kubernetes-operator
kubectl create ns flink
# 修改values.yaml中 apache/flink-kubernetes-operator镜像仓库为registry-public.lenovo.com/lq/flink-kubernetes-operator
helm install flink -n flink .
# 卸载
helm uninstall flink -n flink

# 下载flink:1.20镜像

# 创建serviceaccount.yaml
cat << EOF > serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: flink
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-admin-sa-binding
subjects:
- kind: ServiceAccount
  name: flink
  namespace: default
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF

# 执行测试
kubectl apply -f https://github.com/apache/flink-kubernetes-operator/blob/release-1.12.0/examples/basic.yaml
kubectl port-forward svc/basic-example-rest 80:8081
```
