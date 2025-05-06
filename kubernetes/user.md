# k8s 创建User Account

k8s 创建用户，并且限制该用户只能访问某些namespace下的限制资源

```bash
# 拷贝k8s证书
mkdir -p /home/jupiter/workspace/account
cp /etc/kubernetes/pki/ca.crt .
cp /etc/kubernetes/pki/ca.key .

# 创建dev用户证书,并用k8s证书签署
openssl genrsa -out dev.key 2048
openssl req -new -key dev.key -out dev.csr -subj "/O=k8s/CN=dev"
openssl x509 -req -in dev.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out dev.crt -days 365

# 创建test用户证书
openssl genrsa -out test.key 2048
openssl req -new -key test.key -out test.csr -subj "/O=k8s/CN=test"
openssl x509 -req -in test.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out test.crt -days 365

# 创建集群配置 自定义集群名称为k8s
kubectl config set-cluster k8s \
    --server=https://10.122.196.159:6443 \
    --certificate-authority=/etc/kubernetes/pki/ca.crt \
    --embed-certs=true \
    --kubeconfig=/home/jupiter/workspace/account/dev.conf

# 创建用户配置
kubectl config set-credentials dev \
    --client-certificate=dev.crt \
    --client-key=dev.key \
    --embed-certs=true \
    --kubeconfig=/home/jupiter/workspace/account/dev.conf

# 创建context配置
kubectl config set-context dev@k8s \
    --cluster=k8s \
    --user=dev \
    --kubeconfig=/home/jupiter/workspace/account/dev.conf


# 重复以上步骤创建test用户
kubectl config set-cluster k8s --server=https://10.122.196.159:6443 \
    --certificate-authority=/etc/kubernetes/pki/ca.crt \
    --embed-certs=true \
    --kubeconfig=/home/jupiter/workspace/account/test.conf

kubectl config set-credentials test \
    --client-certificate=test.crt \
    --client-key=test.key \
    --embed-certs=true \
    --kubeconfig=/home/jupiter/workspace/account/test.conf

kubectl config set-context test@k8s \
    --cluster=k8s \
    --user=test \
    --kubeconfig=/home/jupiter/workspace/account/test.conf

# test用户使用token认证
kubectl config set-cluster k8s --server=https://10.122.196.159:6443 \
    --certificate-authority=/etc/kubernetes/pki/ca.crt \
    --embed-certs=true \
    --kubeconfig=/home/jupiter/workspace/account/test-token.conf

kubectl config set-credentials test \
  --token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6InRlc3QiLCJpYXQiOjE1MTYyMzkwMjJ9.tRF6jrkFnCfv6ksyU-JwVq0xsW3SR3y5cNueSTdHdAg \
  --kubeconfig=/home/jupiter/workspace/account/test-token.conf

kubectl config set-context test@k8s \
    --cluster=k8s \
    --user=test \
    --kubeconfig=/home/jupiter/workspace/account/test-token.conf

# 检查账户权限
kubectl auth can-i get pods --as=test -n volcano-system
```

创建RBAC文件
```yaml

# 实现需求，用户dev和test限制只能操作固定几个namespace下的资源
# 并且dev和test分别拥有不同的权限

# 定义：
# 项目: 一组namespace
# 角色：一个角色拥有自己独立的ClusterRole
# 用户：用户属于某个项目，并且拥有角色

# 一个空项目对应
#   ClusterRole 只管理namespace （project-ClusterRole）
#   ClusterRoleBinding 管理成员  (project-ClusterRoleBinding）

# 一个角色对应
#   ClusterRole 管理具体的资源权限 (role-ClusterRole)

# 空项目中添加管理的namespace
#   需要在对应的（project-ClusterRole）resourceNames中添加 namespace

# 项目中添加成员，添加成员时指定角色
#  1. 要在对应的 (project-ClusterRoleBinding）subjects中添加用户信息
#     在project管理的所有namespace中创建 RoleBinding, RoleRef 指向(role-ClusterRole),每当拥有一种角色，就需要一个新RoleBinding
#     在每个namespace中，如果存在两个角色(role-ClusterRole)，就需要两个RoleBinding
#  2. 在每个namespace中，查找角色对应的RoleBonding, subjects中添加用户信息

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: volcano-admin
rules:
- apiGroups:
  - ""
  resourceNames: 
  - volcano-system
  - volcano-monitoring 
  resources:
  - namespaces
  verbs:
  - '*'

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: volcano-admin-crb
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: volcano-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: dev
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: test


---
# 创建自定义角色role-edit
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: role-edit
rules:
  - apiGroups: [""]
    resources: ["pods","services","endpoints","configmaps","persistentvolumes"]
    verbs: ["*"]
  - apiGroups: [ "apps"]
    resources: ["deployments"]
    verbs: ["*"]
# 创建自定义角色role-readonly
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: role-readonly
rules:
  - apiGroups: [""]
    resources: ["pods","services","endpoints","configmaps","persistentvolumes"]
    verbs: ["get","list","watch"]
  - apiGroups: [ "apps"]
    resources: ["deployments"]
    verbs: ["get","list","watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: rb-edit
  namespace: volcano-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: role-edit
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: dev
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: rb-readonly
  namespace: volcano-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: role-readonly
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: test
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: rb-edit
  namespace: volcano-monitoring 
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: role-edit
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: dev
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: rb-readonly
  namespace: volcano-monitoring 
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: role-readonly
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: test

```

测试
```bash
# test只有查看权限
export KUBECONFIG=/home/jupiter/workspace/account/test.conf
kubectl config use-context test@k8s
kubectl get configmap -n volcano-monitoring
kubectl create configmap test-cm -n volcano-monitoring --from-literal=foo=foo 
```
```bash
# 创建时报错如下
[root@sldw93dwm29 account]kubectl create configmap test-cm -n volcano-monitoring --from-literal=foo=foo
error: failed to create configmap: configmaps is forbidden: User "test" cannot create resource "configmaps" in API group "" in the namespace "volcano-monitoring
```
```bash
# 使用dev用户,通过测试
export KUBECONFIG=/home/jupiter/workspace/account/dev.conf
kubectl config use-context dev@k8s
kubectl get configmap -n volcano-monitoring
kubectl create configmap test-cm -n volcano-monitoring --from-literal=foo=foo 
kubectl delete configmap test-cm -n volcano-monitoring
```

rancher测试
```bash
# dev 项目 local/p-dpzls

# 项目crd
kubectl get projects.management.cattle.io  p-dpzls -n local -o yaml

# 该项目控制namespace的clusterrole
kubectl get clusterrole p-dpzls-namespaces-edit -o yaml
kubectl get clusterrole p-dpzls-namespaces-readonly -o yaml

# 项目创建的namespace
kubectl get ns p-dpzls

# -------------------------------------------------------
# 全局角色dev  	gr-s4vqn

# 全局角色crd
kubectl get globalroles.management.cattle.io gr-s4vqn -o yaml

# 全局角色的 clusterrole
kubectl get clusterrole cattle-globalrole-gr-s4vqn -o yaml

# 用户dev 和该角色的绑定关系
kubectl get globalrolebindings.management.cattle.io grb-dthvk -o yaml

kubectl get clusterrolebinding  cattle-globalrolebinding-grb-dthvk -o yaml

# -------------------------------------------------------
# 项目角色dev   rt-l4c9h

# 项目角色crd
kubectl get roletemplates.management.cattle.io rt-l4c9h -o yaml

# 项目角色clusterrole
kubectl get clusterrole rt-l4c9h -o yaml

# 用户dev 和项目角色的绑定关系, 该项目下所有namespace都需要绑定
# 项目中的用户和项目角色的绑定关系

kubectl get projectroletemplatebindings.management.cattle.io

kubectl get rolebinding -n dev-1 rb-wnexgb4myu -o yaml
kubectl get rolebinding -n dev-2 rb-d75tjspd5o -o yaml

# -------------------------------------------------------
# 用户 u-vzzv6
kubectl get users.management.cattle.io u-vzzv6 -o yaml

# token
kubectl get tokens.management.cattle.io
kubectl get tokens.management.cattle.io token-fpr5q -o yaml
```