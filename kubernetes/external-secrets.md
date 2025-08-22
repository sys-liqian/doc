# External-Secrets

## YAML安装


```bash
# 查询k8s和external-secrets版本对应关系
https://external-secrets.io/main/introduction/stability-support/

# 安装CRD
kubectl apply -k "https://raw.githubusercontent.com/external-secrets/external-secrets/v0.13.0/deploy/crds/bundle.yaml"

# 安装Operator
kubectl apply -k "https://github.com/external-secrets/external-secrets/releases/download/v0.13.0/external-secrets.yaml"
```


## Vault Storage

```yaml
# v0.13.0 使用的是v1beta1
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "http://10.122.166.104:8200" # vault 地址
      path: "mykv" # secret 引擎名称
      version: "v1" # secret 引擎版本，默认是v2
      auth:
        tokenSecretRef:
          name: "vault-token" # 保存vault token的k8s secret 名称
          key: "token" # 保存vault token的k8s secret 的 key
---
# valult token secret
apiVersion: v1
kind: Secret
metadata:
  name: vault-token # 对应 vault-backend.spec.provider.vault.auth.tokenSecretRef.name
data:
  # 对应 vault-backend.spec.provider.vault.auth.tokenSecretRef.key
  # vault Initial Root Token
  token: aHZzLmtsTEV0WmNpOW1rS0dIWHUzTlV2bE95RA==
```

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: vault-example
  namespace: default
spec:
  refreshInterval: "1m"    # 每1分钟同步一次
  secretStoreRef:
    name: vault-backend
    kind: SecretStore 
  target:
    name: example-sync # 生成的K8s Secret名称
  data:
    - secretKey: foo-bar  # Kubernetes Secret中的key
      remoteRef:
        key: test # vault 中secret 名称，mykv 引擎下创建 test secret
        property: aaa  # test secret 中包含多个键值对，这里引用aaa
```

生成的k8s secret如下

```yaml
apiVersion: v1
kind: Secret
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"external-secrets.io/v1beta1","kind":"ExternalSecret","metadata":{"annotations":{},"name":"vault-example","namespace":"default"},"spec":{"data":[{"remoteRef":{"key":"test","property":"aaa"},"secretKey":"foo-bar"}],"refreshInterval":"1m","secretStoreRef":{"kind":"SecretStore","name":"vault-backend"},"target":{"name":"example-sync"}}}
    reconcile.external-secrets.io/data-hash: 37ca321978cafe75f0ed8b4276051a33
  creationTimestamp: "2025-08-22T08:07:41Z"
  labels:
    reconcile.external-secrets.io/created-by: d76f8195ffce9a03f68b99755267544e
    reconcile.external-secrets.io/managed: "true"
  name: example-sync
  namespace: default
  ownerReferences:
  - apiVersion: external-secrets.io/v1beta1
    blockOwnerDeletion: true
    controller: true
    kind: ExternalSecret
    name: vault-example
    uid: a11332e3-0203-452f-a7ca-37bfd076c7ed
  resourceVersion: "104452155"
  uid: 6b23e5a1-bd3c-44f8-85f1-f39347988162
type: Opaque
data:
  foo-bar: MTIzNDU2Nzg=
```