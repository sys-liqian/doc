# Zookeeper

## 单点测试

```bash
mkdir -p /data/server/zk/data
mkdir -p /data/server/zk/datalog
mkdir -p /data/server/zk/conf

# 在 dataDir 写入myid文件按
echo "1" > /data/server/zk/data/myid

# 创建jaas认证
# 格式: user_<用户名>="<密码>"
# 注意号不可省略

# 认证流程
# 1. 客户端使用 Client 段的 username/password 生成MD5哈希值，发送至服务端
# 2. 服务端使用 Server 段中 user_admin="123456" 的密码生成MD5哈希，与客户端提交的哈希比对
cat <<EOF > /data/server/zk/conf/zookeeper.jaas
Server {
   org.apache.zookeeper.server.auth.DigestLoginModule required
   user_admin="123456";
};

Client {
       org.apache.zookeeper.server.auth.DigestLoginModule required
       username="admin"
       password="123456";
};
EOF

# 创建conf文件
cat <<EOF > /data/server/zk/conf/zoo.cfg
clientPort=2181
dataDir=/data
dataLogDir=/datalog
tickTime=2000
initLimit=5
syncLimit=2
autopurge.snapRetainCount=3
autopurge.purgeInterval=0
maxClientCnxns=60
standaloneEnabled=true
admin.enableServer=true

# 认证配置
authProvider.1=org.apache.zookeeper.server.auth.SASLAuthenticationProvider
requireClientAuthScheme=sasl
jaasLoginRenew=3600000

server.1=localhost:2888:3888;2181
EOF


docker run -d --name zk \
-p 2181:2181 \
-p 2888:2888 \
-p 3888:3888 \
-v /data/server/zk/data:/data \
-v /data/server/zk/datalog:/datalog \
-v /data/server/zk/conf:/conf \
-e "JVMFLAGS=-Djava.security.auth.login.config=/conf/zookeeper.jaas" \
zookeeper:3.8.4
```

web client
```bash
docker run -it --rm --network host -e HTTP_PORT=9000 -p 9000:9000 elkozmon/zoonavigator:latest
```

zkCli.sh
```bash
# 开启SASL后，使用zkCli.sh需要指定 jass认证文件
zkCli.sh -Djava.security.auth.login.config=/conf/zookeeper.jaas
```

# 集群测试

```bash
# 3台节点都执行
mkdir -p /data/server/zk/data
mkdir -p /data/server/zk/datalog
mkdir -p /data/server/zk/conf

cat <<EOF > /data/server/zk/conf/zookeeper.jaas
Server {
   org.apache.zookeeper.server.auth.DigestLoginModule required
   user_admin="123456";
};

Client {
       org.apache.zookeeper.server.auth.DigestLoginModule required
       username="admin"
       password="123456";
};
EOF

cat <<EOF > /data/server/zk/conf/zoo.cfg
clientPort=2181
dataDir=/data
dataLogDir=/datalog
tickTime=2000
initLimit=5
syncLimit=2
autopurge.snapRetainCount=3
autopurge.purgeInterval=0
maxClientCnxns=60
standaloneEnabled=true
admin.enableServer=true

# 认证配置
authProvider.1=org.apache.zookeeper.server.auth.SASLAuthenticationProvider
requireClientAuthScheme=sasl
jaasLoginRenew=3600000

server.1=10.122.159.130:2888:3888;2181
server.2=10.122.159.161:2888:3888;2181
server.3=10.122.159.193:2888:3888;2181
EOF

# 10.122.159.130执行
echo "1" > /data/server/zk/data/myid
# 10.122.159.161执行
echo "2" > /data/server/zk/data/myid
# 10.122.159.193执行
echo "3" > /data/server/zk/data/myid

docker run -d --name zk \
--network host \
-p 2181:2181 \
-p 2888:2888 \
-p 3888:3888 \
-v /data/server/zk/data:/data \
-v /data/server/zk/datalog:/datalog \
-v /data/server/zk/conf:/conf \
-e "JVMFLAGS=-Djava.security.auth.login.config=/conf/zookeeper.jaas" \
zookeeper:3.8.4


zkCli.sh -server 10.122.159.130:2181,10.122.159.161:2181,10.122.159.193:2181 -Djava.security.auth.login.config=/conf/zookeeper.jaas
```