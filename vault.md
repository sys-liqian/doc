# Vault/OpenBao

## 安装

1. 下载对应的系统的二进制文件
```
https://developer.hashicorp.com/vault/install
```

2. 开发模式启动
```bash
vault server -dev
```

3. 正常启动

* 创建配置文件config.hcl
```
ui = true
disable_mlock = true
api_addr  = "http://127.0.0.1:8200"

backend "file" {
        path = "/home/earthgod/vault/data"
}

listener "tcp" {
        address = "0.0.0.0:8200"
        tls_disable = "true"
}
```
* 启动
```bash
vault server -config=./config.hcl
```

* CLI配置环境变量
```
export VAULT_ADDR='http://127.0.0.1:8200'
```

* 解封(默认需要使用3个key解封)
```bash
vault operator unseal
```

## 使用

* 登录
```
vault login
```

* KV
```bash
#创建Path为mykv的kv引擎
vault secrets enable -path mykv kv

#写入数据
vault kv put mykv/test001 address=127.0.0.1 port=1234

#读取数据
vault kv get mykv/test001

#删除数据
vault delete mykv/test001
```

# Database

## postgres
```bash
# 创建Path为db的数据库引擎
vault secrets enable -path db database

# 配置postgres数据库
vault write db/config/my-postgresql-database \
    plugin_name=postgresql-database-plugin \
    allowed_roles="my-role" \
    connection_url="postgresql://{{username}}:{{password}}@127.0.0.1:5432/liqian35?sslmode=disable" \
    username="root" \
    password="root"

# 创建角色
vault write db/roles/my-role \
    db_name=my-postgresql-database \
    creation_statements="CREATE ROLE '{{name}}' WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO '{{name}}';" \
    default_ttl="1h" \
    max_ttl="24h"

# 读取临时账户信息
vault read db/creds/my-role

# 删除
vault delete db/config/my-postgresql-database
vault delete db/roles/my-role


# 创建database
vault write db/config/my-postgresql-database-registry \
    plugin_name=postgresql-database-plugin \
    allowed_roles="my-role-registry" \
    connection_url="postgresql://{{username}}:{{password}}@127.0.0.1:5432/postgres?sslmode=disable" \
    username="root" \
    password="root"


# 创建只有访问某个数据库的角色[registry]
vault write db/roles/my-role-registry \
    db_name=my-postgresql-database-registry \
    creation_statements="CREATE ROLE '{{name}}' WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT ALL PRIVILEGES ON DATABASE registry TO '{{name}}';" \
    default_ttl="5m" \
    max_ttl="5m"

vault read db/creds/my-role-registry
```

## mysql
```bash
# 配置mysql数据库
vault write db/config/my-mysql-database \
    plugin_name=mysql-database-plugin \
    connection_url="{{username}}:{{password}}@tcp(127.0.0.1:3306)/" \
    allowed_roles="my-mysql-database-role" \
    username="root" \
    password="root"

#创建role
vault write db/roles/my-mysql-database-role \
    db_name=my-mysql-database \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}'; GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl="1h" \
    max_ttl="24h"

# 读取临时账户信息
vault read db/creds/my-mysql-database-role

# 续约，读取账户时何以获取lease_id
vault lease renew <lease_id>

# 查看当前凭证过期时间
vault lease lookup <lease_id>
```

# API

* 修改DefaultPolicy或者创建新Policy(my-policy.hcl)
```bash 
path "db/*" {
    capabilities = ["create", "read", "update", "delete", "list"]
}

path "mykv/*" {
    capabilities = ["create", "read", "update", "delete", "list"]
}
```

* 上传Policy到Vualt
```bash
vault policy write my-policy my-policy.hcl
```

* Policy操作
```bash
# policy list
vault policy list
# read policy
vault policy read default
```

* 使用userpass认证
```bash
vault auth enable userpass
vault write auth/userpass/users/liqian35 password=liqian35 policies=my-policy
curl -X POST -d '{"password": "liqian35"}' http://127.0.0.1:8200/v1/auth/userpass/login/liqian35
```

* 使用token认证
```bash
vault token create -policy=my-policy
```

* Token操作
```bash
# 创建token时会返回token_accessor
vault list auth/token/accessors

# 查询token meta
vault token lookup -accessor {accessor}

# token续期
vault token renew {token}
```


## k8s 安装vault

vault 1.14.8 MPL协议,chart version 为0.25.0

```bash
# 添加repo
helm repo add hashicorp https://helm.releases.hashicorp.com
# 查看所有chart版本
helm search repo hashicorp -l
# 开发模式启动vault
helm install vault hashicorp/vault --version 0.25.0 --set "server.dev.enabled=true" -n vault
# 正常启动vault
helm install vault hashicorp/vault --version 0.25.0 -n vault
```
