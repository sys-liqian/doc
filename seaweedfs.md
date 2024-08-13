# SeaweedFS

## 单点

* 启动脚本

```bash
#!/bin/bash

# 默认端口
# master 9333
# volume 8080
# filer  8888
# s3     8333


mkdir -p /data/seaweedfs/log/master
mkdir -p /data/seaweedfs/log/volume
mkdir -p /data/seaweedfs/log/filer
mkdir -p /data/seaweedfs/log/s3
mkdir -p /data/seaweedfs/master
mkdir -p /data/seaweedfs/volume
mkdir -p /data/seaweedfs/s3

cat <<EOF >/data/seaweedfs/s3/config.json
{
  "identities": [
    {
      "name": "anonymous",
      "actions": [
        "Read"
      ]
    },
    {
      "name": "root",
      "credentials": [
        {
          "accessKey": "testak",
          "secretKey": "testsk"
        }
      ],
      "actions": [
        "Admin",
        "Read",
        "List",
        "Tagging",
        "Write"
      ]
    }
  ]
}
EOF


create_service(){
cat <<EOF > /usr/lib/systemd/system/weed-${service_name}-server.service
[Unit]
Description=${service_name}
After=network.target

[Service]
Restart=always
ExecStart=${command}
ExecStop=/bin/docker stop seaweedfs-${service_name}
ExecStopPost=/bin/docker rm -f seaweedfs-${service_name}


[Install]
WantedBy=multi-user.target
EOF
}

service_name="master"
command="/bin/docker run --rm --network host --name seaweedfs-master -v /data/seaweedfs/master:/data/master -v /data/seaweedfs/log/master:/data/log/master chrislusf/seaweedfs:latest -logdir=/data/log/master master -mdir=/data/master"
create_service

service_name="volume"
command="/bin/docker run --rm --network host --name seaweedfs-volume -v /data/seaweedfs/volume:/data/volume -v /data/seaweedfs/log/volume:/data/log/volume chrislusf/seaweedfs:latest -logdir=/data/log/volume volume -dir=/data/volume -max=300 -mserver=localhost:9333"
create_service

service_name="filer"
command="/bin/docker run --rm --network host --name seaweedfs-filer -v /data/seaweedfs/log/filer:/data/log/filer chrislusf/seaweedfs:latest -logdir=/data/log/filer filer -master=localhost:9333"
create_service

service_name="s3"
command="/bin/docker run --rm --network host --name seaweedfs-s3  -v /data/seaweedfs/s3:/data/s3 -v /data/seaweedfs/log/s3:/data/log/s3  chrislusf/seaweedfs:latest -logdir=/data/log/s3 s3 -filer=localhost:8888 -config=/data/s3/config.json"
create_service

systemctl daemon-reload
systemctl start weed-master-server.service
systemctl start weed-volume-server.service
systemctl start weed-filer-server.service
systemctl start weed-s3-server.service

systemctl enable weed-master-server.service
systemctl enable weed-volume-server.service
systemctl enable weed-filer-server.service
systemctl enable weed-s3-server.service
```

* 单进程启动所有服务
```bash
docker run --rm --network host --name seaweedfs \
-v /data/seaweedfs/data:/data/data \
-v /data/seaweedfs/config:/data/config \
-v /data/seaweedfs/log:/data/log \
chrislusf/seaweedfs:latest \
-logdir=/data/log \
server \
-master.port=9333 \
-volume.port=8080 \
-s3 \
-s3.port=8333 \
-s3.config=/data/config/config.json
```

* filer配置文件
```bash
weed scaffold -config=filer > filer.toml
```

filer store高可用部署下建议使用redis

文件操作复杂度：
* 获取文件：对于LSM树或者B树来说，复杂度为O(logN)（N为已存在的条目），对于Redis复杂度是O(1)
* 列出目录：对于LSM树或者B树来说，是一个遍历的过程，对于Redis复杂度是O(1)
* 添加文件：父目录如果不存在则首先创建父目录信息，然后创建文件条目
* 文件重命名：文件重命名是一个O(1)的操作，删除老的元数据然后插入新的元数据，不需要修改volume中保存的文件内容
* 目录重命名：目录重命名是一个O(N)的操作（N为目录下文件与目录的数量），需要修改所有这些记录的元数据，不需要修改volume中保存的文件内容

文件如下：
```bash
# filer 配置文件
# 在 weed filer 或者 weed server -filer 使用
# filer 配置文件地址优先级如下
#    ./filer.toml
#    $HOME/.seaweedfs/filer.toml
#    /usr/local/etc/seaweedfs/filer.toml
#    /etc/seaweedfs/filer.toml


# filer server 配置
[filer.options]
# 允许递归删除
recursive_delete = false
# 最大文件名长度
max_file_name_length = 255

# filer store 配置
[leveldb2]
enabled = true
dir = "./filerldb2"

[leveldb3]
enabled = false
dir = "./filerldb3"

[rocksdb]
enabled = false
dir = "./filerrdb"

[sqlite]
enabled = false
dbFile = "./filer.db"

[mysql]  #  memsql, tidb 配置同mysql
# CREATE TABLE IF NOT EXISTS `filemeta` (
#   `dirhash`   BIGINT NOT NULL       COMMENT 'first 64 bits of MD5 hash value of directory field',
#   `name`      VARCHAR(766) NOT NULL COMMENT 'directory or file name',
#   `directory` TEXT NOT NULL         COMMENT 'full path to parent directory',
#   `meta`      LONGBLOB,
#   PRIMARY KEY (`dirhash`, `name`)
# ) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

enabled = false
# dsn will take priority over "hostname, port, username, password, database".
# [username[:password]@][protocol[(address)]]/dbname[?param1=value1&...&paramN=valueN]
dsn = "root@tcp(localhost:3306)/seaweedfs?collation=utf8mb4_bin"
hostname = "localhost"
port = 3306
username = "root"
password = ""
database = ""      # create or use an existing database
connection_max_idle = 2
connection_max_open = 100
connection_max_lifetime_seconds = 0
interpolateParams = false
enableUpsert = true
upsertQuery = """INSERT INTO `%s` (`dirhash`,`name`,`directory`,`meta`) VALUES (?,?,?,?) AS `new` ON DUPLICATE KEY UPDATE `meta` = `new`.`meta`"""

[mysql2]  # memsql, tidb 配置同mysql
enabled = false
createTable = """
  CREATE TABLE IF NOT EXISTS `%s` (
    `dirhash`   BIGINT NOT NULL,
    `name`      VARCHAR(766) NOT NULL,
    `directory` TEXT NOT NULL,
    `meta`      LONGBLOB,
    PRIMARY KEY (`dirhash`, `name`)
  ) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
"""
hostname = "localhost"
port = 3306
username = "root"
password = ""
database = ""              # create or use an existing database     
connection_max_idle = 2
connection_max_open = 100
connection_max_lifetime_seconds = 0
interpolateParams = false
enableUpsert = true
upsertQuery = """INSERT INTO `%s` (`dirhash`,`name`,`directory`,`meta`) VALUES (?,?,?,?) AS `new` ON DUPLICATE KEY UPDATE `meta` = `new`.`meta`"""

[postgres] # cockroachdb, YugabyteDB 配置同postgresql
# CREATE TABLE IF NOT EXISTS filemeta (
#   dirhash     BIGINT,
#   name        VARCHAR(65535),
#   directory   VARCHAR(65535),
#   meta        bytea,
#   PRIMARY KEY (dirhash, name)
# );
enabled = false
hostname = "localhost"
port = 5432
username = "postgres"
password = ""
database = "postgres"          # create or use an existing database
schema = ""
sslmode = "disable"
connection_max_idle = 100
connection_max_open = 100
connection_max_lifetime_seconds = 0
enableUpsert = true
upsertQuery = """UPSERT INTO "%[1]s" (dirhash,name,directory,meta) VALUES($1,$2,$3,$4)"""

[postgres2]
enabled = false
createTable = """
  CREATE TABLE IF NOT EXISTS "%s" (
    dirhash   BIGINT,
    name      VARCHAR(65535),
    directory VARCHAR(65535),
    meta      bytea,
    PRIMARY KEY (dirhash, name)
  );
"""
hostname = "localhost"
port = 5432
username = "postgres"
password = ""
database = "postgres"          # create or use an existing database
schema = ""
sslmode = "disable"
connection_max_idle = 100
connection_max_open = 100
connection_max_lifetime_seconds = 0
enableUpsert = true
upsertQuery = """UPSERT INTO "%[1]s" (dirhash,name,directory,meta) VALUES($1,$2,$3,$4)"""

[cassandra]
# CREATE TABLE filemeta (
#    directory varchar,
#    name varchar,
#    meta blob,
#    PRIMARY KEY (directory, name)
# ) WITH CLUSTERING ORDER BY (name ASC);
enabled = false
keyspace = "seaweedfs"
hosts = [
    "localhost:9042",
]
username = ""
password = ""
# This changes the data layout. Only add new directories. Removing/Updating will cause data loss.
superLargeDirectories = []
# Name of the datacenter local to this filer, used as host selection fallback.
localDC = ""
# Gocql connection timeout, default: 600ms
connection_timeout_millisecond = 600

[hbase]
enabled = false
zkquorum = ""
table = "seaweedfs"

[redis2]
enabled = false
address = "localhost:6379"
password = ""
database = 0
# This changes the data layout. Only add new directories. Removing/Updating will cause data loss.
superLargeDirectories = []

[redis2_sentinel]
enabled = false
addresses = ["172.22.12.7:26379","172.22.12.8:26379","172.22.12.9:26379"]
masterName = "master"
username = ""
password = ""
database = 0

[redis_cluster2]
enabled = false
addresses = [
    "localhost:30001",
    "localhost:30002",
    "localhost:30003",
    "localhost:30004",
    "localhost:30005",
    "localhost:30006",
]
password = ""
# allows reads from slave servers or the master, but all writes still go to the master
readOnly = false
# automatically use the closest Redis server for reads
routeByLatency = false
# This changes the data layout. Only add new directories. Removing/Updating will cause data loss.
superLargeDirectories = []

[redis_lua]
enabled = false
address = "localhost:6379"
password = ""
database = 0
# This changes the data layout. Only add new directories. Removing/Updating will cause data loss.
superLargeDirectories = []

[redis_lua_sentinel]
enabled = false
addresses = ["172.22.12.7:26379","172.22.12.8:26379","172.22.12.9:26379"]
masterName = "master"
username = ""
password = ""
database = 0

[redis_lua_cluster]
enabled = false
addresses = [
    "localhost:30001",
    "localhost:30002",
    "localhost:30003",
    "localhost:30004",
    "localhost:30005",
    "localhost:30006",
]
password = ""
# allows reads from slave servers or the master, but all writes still go to the master
readOnly = false
# automatically use the closest Redis server for reads
routeByLatency = false
# This changes the data layout. Only add new directories. Removing/Updating will cause data loss.
superLargeDirectories = []

[redis3] # 处于Beta阶段，不建议使用
enabled = false
address = "localhost:6379"
password = ""
database = 0

[redis3_sentinel]
enabled = false
addresses = ["172.22.12.7:26379","172.22.12.8:26379","172.22.12.9:26379"]
masterName = "master"
username = ""
password = ""
database = 0

[redis_cluster3] # 处于Beta阶段，不建议使用
enabled = false
addresses = [
    "localhost:30001",
    "localhost:30002",
    "localhost:30003",
    "localhost:30004",
    "localhost:30005",
    "localhost:30006",
]
password = ""
# allows reads from slave servers or the master, but all writes still go to the master
readOnly = false
# automatically use the closest Redis server for reads
routeByLatency = false

[etcd]
enabled = false
servers = "localhost:2379"
username = ""
password = ""
key_prefix = "seaweedfs."
timeout = "3s"
tls_ca_file=""
tls_client_crt_file=""
tls_client_key_file=""

[mongodb]
enabled = false
uri = "mongodb://localhost:27017"
username = ""
password = ""
ssl = false
ssl_ca_file = ""
ssl_cert_file = ""
ssl_key_file = ""
insecure_skip_verify = false
option_pool_size = 0
database = "seaweedfs"

[elastic7]
enabled = false
servers = [
    "http://localhost1:9200",
    "http://localhost2:9200",
    "http://localhost3:9200",
]
username = ""
password = ""
sniff_enabled = false
healthcheck_enabled = false
# 建议增加该值，确保 Elastic 中的值大于或等于此处
index.max_result_window = 10000


[arangodb] # 开发中，禁止使用
enabled = false
db_name = "seaweedfs"
servers=["http://localhost:8529"] # 集群填写多个
password=""
insecure_skip_verify = true

[ydb]
enabled = false
dsn = "grpc://localhost:2136?database=/local"
prefix = "seaweedfs"
useBucketPrefix = true # Fast Bucket Deletion
poolSizeLimit = 50
dialTimeOut = 10

# 
##########################
# To add path-specific filer store:
#
# 1. Add a name following the store type separated by a dot ".". E.g., cassandra.tmp
# 2. Add a location configuration. E.g., location = "/tmp/"
# 3. Copy and customize all other configurations.
#     Make sure they are not the same if using the same store type!
# 4. Set enabled to true
#
# The following is just using redis as an example
##########################
[redis2.tmp]
enabled = false
location = "/tmp/"
address = "localhost:6379"
password = ""
database = 1

[tikv]
enabled = false
pdaddrs = "localhost:2379" #集群地址用逗号分隔 localhost:2379,localhost:2380,localhost:2381
deleterange_concurrency = 1
enable_1pc = false
ca_path=""
cert_path=""
key_path=""
verify_cn=""
```

* 删除脚本

```bash
#/bin/bash
systemctl disable weed-master-server.service
systemctl disable weed-volume-server.service
systemctl disable weed-filer-server.service
systemctl disable weed-s3-server.service
systemctl stop weed-master-server.service
systemctl stop weed-volume-server.service
systemctl stop weed-filer-server.service
systemctl stop weed-s3-server.service
rm -f /usr/lib/systemd/system/weed-master-server.service
rm -f /usr/lib/systemd/system/weed-volume-server.service
rm -f /usr/lib/systemd/system/weed-filer-server.service
rm -f /usr/lib/systemd/system/weed-s3-server.service
rm -rf /data/seaweedfs
```

## 高可用

环境准备

主机：
* 10.119.108.51
* 10.119.108.52
* 10.119.108.53

Redis:
```bash
#生产环境Redis建议部署高可用，这里使用单点的Redis测试
docker run -d --name seaweedfs-redis --network host registry-public.lenovo.com/earth_system/redis:6.2.8
```

在3个节点上执行该脚本
```bash
#!/bin/bash
mkdir -p /data/seaweedfs/log/master
mkdir -p /data/seaweedfs/log/volume
mkdir -p /data/seaweedfs/log/filer
mkdir -p /data/seaweedfs/master
mkdir -p /data/seaweedfs/volume
mkdir -p /data/seaweedfs/filer
mkdir -p /data/seaweedfs/s3

cat <<EOF >/data/seaweedfs/s3/config.json
{
  "identities": [
    {
      "name": "anonymous",
      "actions": [
        "Read"
      ]
    },
    {
      "name": "root",
      "credentials": [
        {
          "accessKey": "testak",
          "secretKey": "testsk"
        }
      ],
      "actions": [
        "Admin",
        "Read",
        "List",
        "Tagging",
        "Write"
      ]
    }
  ]
}
EOF

cat <<EOF >/data/seaweedfs/filer/filer.toml
[filer.options]
recursive_delete = false
max_file_name_length = 512

[redis2]
enabled = true
address = "10.119.108.53:6379"
password = ""
database = 0
superLargeDirectories = []
EOF


create_service(){
cat <<EOF > /usr/lib/systemd/system/weed-${service_name}-server.service
[Unit]
Description=${service_name}
After=network.target

[Service]
Restart=always
ExecStart=${command}
ExecStop=/bin/docker stop seaweedfs-${service_name}
ExecStopPost=/bin/docker rm -f seaweedfs-${service_name}


[Install]
WantedBy=multi-user.target
EOF
}

service_name="master"
command="/bin/docker run --rm --network host --name seaweedfs-master -v /data/seaweedfs/master:/data/master -v /data/seaweedfs/log/master:/data/log/master chrislusf/seaweedfs:latest -logdir=/data/log/master master -mdir=/data/master -peers=10.119.108.51:9333,10.119.108.52:9333,10.119.108.53:9333 -defaultReplication=001"
create_service

service_name="volume"
command="/bin/docker run --rm --network host --name seaweedfs-volume -v /data/seaweedfs/volume:/data/volume -v /data/seaweedfs/log/volume:/data/log/volume chrislusf/seaweedfs:latest -logdir=/data/log/volume volume -dir=/data/volume -max=300 -mserver=10.119.108.51:9333,10.119.108.52:9333,10.119.108.53:9333"
create_service

# filer s3 作为一个进程启动
service_name="filer"
command="/bin/docker run --rm --network host --name seaweedfs-filer -v /data/seaweedfs/log/filer:/data/log/filer -v /data/seaweedfs/s3:/data/s3 -v /data/seaweedfs/filer:/etc/seaweedfs chrislusf/seaweedfs:latest -logdir=/data/log/filer filer -master=10.119.108.51:9333,10.119.108.52:9333,10.119.108.53:9333 -s3 -s3.config=/data/s3/config.json -s3.port=8333"
create_service


systemctl daemon-reload
systemctl start weed-master-server.service
systemctl start weed-volume-server.service
systemctl start weed-filer-server.service

systemctl enable weed-master-server.service
systemctl enable weed-volume-server.service
systemctl enable weed-filer-server.service
```

## 使用

* master api [Github](https://github.com/seaweedfs/seaweedfs/wiki/Master-Server-API)
```bash
echo 111 > tst.txt

# 获取文件id,以及对应的volume url
# 文件id分为3个部分，2,0192747184
# 逗号左边的数字2表示volume id。
# 逗号右边的01表示file key
# 剩下的92747184表示file cookie。
curl http://10.119.108.53:9333/dir/assign
{"fid":"2,0192747184","url":"10.119.108.53:8080","publicUrl":"10.119.108.53:8080","count":1}

# 上传文件
curl -F file=@/home/jupiter/liqian35/seaweedfs/tst.txt http://10.119.108.53:8080/2,0192747184
{"name":"tst.txt","size":4,"eTag":"a7caf2e5","mime":"text/plain"}

# 文件访问，先通过volumeid获取访问的url
curl http://10.119.108.53:9333/dir/lookup?volumeId=2
{"volumeOrFileId":"2","locations":[{"url":"10.119.108.53:8080","publicUrl":"10.119.108.53:8080","dataCenter":"DefaultDataCenter"}]}

# 获取文件内容
curl http://10.119.108.53:8080/2,0192747184

# 删除文件
curl -X DELETE http://10.119.108.53:8080/2,0192747184
```

* filer api
```bash
# 上传文件
curl -F file=@/home/jupiter/liqian35/seaweedfs/tst.txt http://10.119.108.53:8888/tst
{"name":"tst.txt","size":4}

# 列表展示目录中的文件
curl -H "accept: application/json" http://10.119.108.53:8888/tst

# 删除
curl -X DELETE http://10.119.108.53:8888/tst/tst.txt
```

* s3 api
```bash
# s3cmd 配置
s3cmd --configure
# S3 Endpoint不能使用ip,可以在本地hosts配置一个域名
  Access Key: testak
  Secret Key: testsk
  Default Region: US
  S3 Endpoint: seaweedfs.com:8333
  DNS-style bucket+hostname:port template for accessing a bucket: seaweedfs.com:8333
  Encryption password: 
  Path to GPG program: /usr/bin/gpg
  Use HTTPS protocol: False
  HTTP Proxy server name: 
  HTTP Proxy server port: 0
```
```bash
# 创建bucket
s3cmd mb s3://mybucket

# 查看所有bucket
s3cmd ls s3://

# 上传文件到桶
echo 'hello seaweedfs' > /root/hell_seaweedfs.txt
s3cmd put /root/hell_seaweedfs.txt s3://mybucket

# 查看桶中文件
s3cmd ls s3://mybucket
# 递归查看
s3cmd ls --recursive s3://mybucket

# 删除文件
s3cmd del s3://mybucket/hell_seaweedfs.txt

# 删除桶
s3cmd rb s3://mybucket
```

## 高可用验证

数据准备
```bash
#!/bin/bash
for i in $(seq 1 100)
do

echo $i >> $i.txt
echo `cat /proc/sys/kernel/random/uuid` >> $i.txt

done

for i in $(seq 1 100)
do

echo "uploading $i.txt"
curl -F file=@$i.txt "http:/10.119.108.51:8888/test/"
echo "uploaed $i.txt"

done
```

### master leader done

```bash
# 当前leader为10.119.108.51:9333
Volume Size Limit	30000MB
Free	888
Max	900
Leader	10.119.108.51:9333
Other Masters	
10.119.108.52:9333
10.119.108.53:9333
```
停掉Leader
```bash
# 在10.119.108.51节点
systemctl stop weed-master-server
```
Leader重新选举
```bash
# 当前leader为10.119.108.53:9333
Volume Size Limit	30000MB
Free	296
Max	300
Leader	10.119.108.53:9333
Other Masters	
10.119.108.51:9333
10.119.108.52:9333
```
### volume done
停掉volume server
```bash
# 在10.119.108.51节点
systemctl stop weed-volume-server
```
```bash
# volume done 前Topology
Data Center	Rack	RemoteAddr	                    Volumes  Volume Ids  ErasureCodingShards	Max
DefaultDataCenter	DefaultRack	10.119.108.51:8080	5	       1 3-6	      0	                  300
DefaultDataCenter	DefaultRack	10.119.108.52:8080	4	       2-5	        0	                  300
DefaultDataCenter	DefaultRack	10.119.108.53:8080	3	       1-2 6	      0	                  300

# volume done 后Topology
Data Center	Rack	RemoteAddr	                    Volumes  Volume Ids  ErasureCodingShards	Max
DefaultDataCenter	DefaultRack	10.119.108.52:8080	4	       2-5	       0	                  300
DefaultDataCenter	DefaultRack	10.119.108.53:8080	3	       1-2 6	     0  	                300
```
### filer done
停掉filer server,测试时没有在filer服务前加lb,所以51节点done后，使用53或者52节点验证
```bash
# 在10.119.108.51节点
systemctl stop weed-filer-server
```

* 验证读
```bash
#!/bin/bash
for i in $(seq 1 100)
do
  curl  "http:/10.119.108.51:8888/test/$i.txt"
done
```
* 验证写
```bash
echo "new file data" >> /home/jupiter/liqian35/seaweedfs/new.txt
curl -F file=@/home/jupiter/liqian35/seaweedfs/new.txt http://10.119.108.51:8888/test
```

