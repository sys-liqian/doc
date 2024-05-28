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
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"

# 读取临时账户信息
vault read db/creds/my-role
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
vault token {token}
```

