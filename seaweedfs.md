# SeaweedFS

## 单点测试

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
mkdir -p /data/seaweedfs/filerldb2
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
command="/bin/docker run --rm --network host --name seaweedfs-volume -v /data/seaweedfs/volume:/data/volume -v /data/seaweedfs/log/volume:/data/log/volume -v /data/seaweedfs/filerldb2:/data/filerldb2 chrislusf/seaweedfs:latest -logdir=/data/log/volume volume -dir=/data/volume -max=300 -mserver=localhost:9333"
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
chrislusf/seaweedfs:latest \
-logdir=/data/log \
server \
-master.port=9333 \
-volume.port=8080 \
-s3 \
-s3.port=8333 \
```

* seaweedfs配置文件按约定目录优先级寻找,weed -h 可查看有限级

```bash
# 生成filer 配置文件
weed scaffold -config=filer > filer.toml
# 生成安全配置文件
weed scaffold -config=security > security.toml
```

filer store高可用部署下建议使用redis

文件操作复杂度：
* 获取文件：对于LSM树或者B树来说，复杂度为O(logN)（N为已存在的条目），对于Redis复杂度是O(1)
* 列出目录：对于LSM树或者B树来说，是一个遍历的过程，对于Redis复杂度是O(1)
* 添加文件：父目录如果不存在则首先创建父目录信息，然后创建文件条目
* 文件重命名：文件重命名是一个O(1)的操作，删除老的元数据然后插入新的元数据，不需要修改volume中保存的文件内容
* 目录重命名：目录重命名是一个O(N)的操作（N为目录下文件与目录的数量），需要修改所有这些记录的元数据，不需要修改volume中保存的文件内容



## 高可用无安全配置

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


## API

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
yum update
yum install s3cmd
# s3cmd 配置
s3cmd --configure
# 修改/etc/hosts 为目标配置域名
# 配置后修改~/.s3cfg
# host_base = seaweedfs.com:7203
# host_bucket = seaweedfs.com:7203/%(bucket)
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

* weed mount
```bash
# -dir 本地挂载点
# -filer.path 远端目录，不存在会创建
# 10.119.108.54 为vip
weed -v=4  mount -filer=10.119.108.54:10002 -dir /mnt/tst -collection=col1 -collectionQuotaMB=100 -filer.path=/testdir
weed -v=4  mount -filer=10.119.108.51:10002,10.119.108.52:10002,10.119.108.53:10002  -dir /mnt/tst
# mount 
# 使用mount可能和内核以及fuse版本有关系，当前在ubuntu 22.04 kernel 5.10测试通过，在rockylinux 8 kernel 4.18 测试不通过
cp weed /sbin/weed
mount -t fuse.weed fuse /mnt/tst -o "filer=10.119.108.54:10002,collection=col1"
mount -t fuse./usr/local/bin/weed fuse /mnt/tst -o "filer='10.119.108.51:10002,10.119.108.52:10002,10.119.108.53:10002'"
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

## 生产配置

* 主机
```
10.119.108.51
10.119.108.52
10.119.108.53
```

* vip
```bash
# vip 用来保证s3高可用
10.119.108.54
```

* 证书
```bash
mkdir -p /data/cert
cd /data/cert
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -sha256 -days 365 -out ca.crt
openssl req -nodes -newkey rsa:2048 -keyout server.key -out server.csr -subj "/CN=SeaweedFS"
openssl x509 -req -CA ca.crt -CAkey ca.key -CAcreateserial -in server.csr -out server.crt -days 3650
```

* 目录结构
```
root@installerdev01:/data# tree /data/server/sea
/data/server/sea
├── data
│   ├── cert
│   │   ├── ca.crt
│   │   ├── server.crt
│   │   └── server.key
│   ├── conf
│   │   ├── config.json
│   │   ├── filer.toml
│   │   └── security.toml
│   ├── filerldb2
│   ├── master
│   │   └── m7200
│   │       ├── conf
│   │       ├── log
│   │       └── snapshot
│   └── volume
│       └── vol_dir.uuid
└── log
    ├── filer
    │   ├── weed.INFO -> weed.installerdev01.root.log.INFO.20241029-090343.1
    │   ├── weed.installerdev01.root.log.INFO.20241029-090343.1
    │   ├── weed.installerdev01.root.log.WARNING.20241029-090343.1
    │   └── weed.WARNING -> weed.installerdev01.root.log.WARNING.20241029-090343.1
    ├── master
    │   ├── weed.INFO -> weed.installerdev01.root.log.INFO.20241029-090321.1
    │   └── weed.installerdev01.root.log.INFO.20241029-090321.1
    ├── s3
    │   ├── weed.INFO -> weed.installerdev01.root.log.INFO.20241029-090323.1
    │   ├── weed.installerdev01.root.log.INFO.20241029-090323.1
    │   ├── weed.installerdev01.root.log.WARNING.20241029-090344.1
    │   └── weed.WARNING -> weed.installerdev01.root.log.WARNING.20241029-090344.1
    └── volume
        ├── weed.INFO -> weed.installerdev01.root.log.INFO.20241029-090322.1
        └── weed.installerdev01.root.log.INFO.20241029-090322.1

13 directories, 21 files
```

* s3 静态认证配置文件config.json
```json
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
```
* filer 配置filer.toml

1. master服务禁用http,grpc 使用tls来保证安全
2. volume服务http不安全，但是url需要从master获取，mater禁用http，没有地方获取fid,所以安全，grpc使用tls保证安全
3. filer服务不能禁用http,-disableHttp,s3服务使用http与filer通信，所以filer添加jwt认证保证http安全，filer grpc使用tls保证安全
4. s3 s3使用accessKey,secretKey保证安全

```toml
[filer.options]
recursive_delete = false
max_file_name_length = 512

[redis2_sentinel]
enabled = true
addresses = ["10.119.108.51:26379","10.119.108.52:26379","10.119.108.53:26379"]
masterName = "sentinel_master"
username = ""
password = "123456"
database = 0
```

* security配置security.toml
```toml
[cors.allowed_origins]
values = "*"  

[access]
ui = false

[filer.expose_directory_metadata]
enabled = true

[jwt.signing]
key = ""
expires_after_seconds = 120     

[jwt.signing.read]
key = ""
expires_after_seconds = 120


[jwt.filer_signing]
key = "73h2h6gsg6"
expires_after_seconds = 120

[jwt.filer_signing.read]
key = "73h2h6gsg6"
expires_after_seconds = 120

[grpc]
ca = "/data/cert/ca.crt"
allowed_wildcard_domain = ""

[grpc.volume]
cert = "/data/cert/server.crt"
key = "/data/cert/server.key"
allowed_commonNames = ""

[grpc.master]
cert = "/data/cert/server.crt"
key = "/data/cert/server.key"
allowed_commonNames = ""

[grpc.filer]
cert = "/data/cert/server.crt"
key = "/data/cert/server.key"
allowed_commonNames = ""

[grpc.s3]
cert = ""
key = ""
allowed_commonNames = ""   

[grpc.msg_broker]
cert = ""
key = ""
allowed_commonNames = ""

[grpc.client]
cert = "/data/cert/server.crt"
key = "/data/cert/server.key"

[https.client]
enabled = false
cert = ""
key = ""
ca = ""

[https.volume]
cert = ""
key = ""
ca = ""

[https.master]
cert = ""
key = ""
ca = ""

[https.filer]
cert = ""
key = ""
ca = ""
```
```bash
如果需要浏览器上传文件的功能,修改security.toml相关配置如下
------
[access]
ui = true

[jwt.filer_signing]
key = ""
expires_after_seconds = 120

[jwt.filer_signing.read]
key = ""
expires_after_seconds = 120
------
```

* mater service file
```bash
[Unit]
Description=Seaweedfs Master Container
Wants=docker.service
After=docker.service

[Service]
Restart=always
ExecStartPre=-/bin/docker stop sea-master
ExecStartPre=-/bin/docker rm -f sea-master
ExecStart=/bin/docker run \
    --rm \
    --net=host \
    -l app=sea \
    -l component=seaweedfs \
    -v /data/server/sea/data/master:/data/seaweedfs/master \
    -v /data/server/sea/data/conf:/etc/seaweedfs \
    -v /data/server/sea/data/cert:/data/cert \
    -v /data/server/sea/log/master:/data/seaweedfs/log \
    --name sea-master \
    registry-public.lenovo.com/earth_system/seaweedfs:3.71 \
    -logdir=/data/seaweedfs/log \
    master \
    -mdir=/data/seaweedfs/master \
    -volumeSizeLimitMB=30000 \
    -ip=10.119.108.51 \
    -port=7200 \
    -port.grpc=17200 \
    -disableHttp \
    -peers=10.119.108.51:7200,10.119.108.52:7200,10.119.108.53:7200 \
    -defaultReplication=001

ExecStop=/bin/docker stop sea-master
ExecStopPost=/bin/docker rm -f sea-master

[Install]
WantedBy=multi-user.target
```
* volume service file
```bash
[Unit]
Description=Seaweedfs Volume Container
Wants=docker.service
After=docker.service

[Service]
Restart=always
ExecStartPre=-/bin/docker stop sea-volume
ExecStartPre=-/bin/docker rm -f sea-volume
ExecStart=/bin/docker run \
    --rm \
    --net=host \
    -l app=sea \
    -l component=seaweedfs \
    -v /data/server/sea/data/conf:/etc/seaweedfs \
    -v /data/server/sea/data/cert:/data/cert \
    -v /data/server/sea/log/volume:/data/seaweedfs/log \
    -v /data/server/sea/data/volume:/data/volume-1 \
    --name sea-volume \
    registry-public.lenovo.com/earth_system/seaweedfs:3.71 \
    -logdir=/data/seaweedfs/log \
    volume \
    -dir=/data/volume-1 \
    -max=8 \
    -ip=10.119.108.51 \
    -port=7201 \
    -port.grpc=17201 \
    -mserver=10.119.108.51:7200,10.119.108.52:7200,10.119.108.53:7200

ExecStop=/bin/docker stop sea-volume
ExecStopPost=/bin/docker rm -f sea-volume

[Install]
WantedBy=multi-user.target
```
* filer service file
```bash
[Unit]
Description=Seaweedfs Filer Container
Wants=docker.service
After=docker.service

[Service]
Restart=always
ExecStartPre=-/bin/docker stop sea-filer
ExecStartPre=-/bin/docker rm -f sea-filer
ExecStart=/bin/docker run \
    --rm \
    --net=host \
    -l app=sea \
    -l component=seaweedfs \
    -v /data/server/sea/data/conf:/etc/seaweedfs \
    -v /data/server/sea/data/cert:/data/cert \
    -v /data/server/sea/data/filerldb2:/data/filerldb2 \
    -v /data/server/sea/log/filer:/data/seaweedfs/log \
    --name sea-filer \
    registry-public.lenovo.com/earth_system/seaweedfs:3.71 \
    -logdir=/data/seaweedfs/log \
    filer \
    -ip.bind=0.0.0.0 \
    -port=7202 \
    -port.grpc=17202 \
    -master=10.119.108.51:7200,10.119.108.52:7200,10.119.108.53:7200

ExecStop=/bin/docker stop sea-filer
ExecStopPost=/bin/docker rm -f sea-filer

[Install]
WantedBy=multi-user.target
```
* s3 service file
1. s3 -ip.bind=0.0.0.0,s3多节点会配置同各国vip访问
```bash
[Unit]
Description=Seaweedfs S3 Container
Wants=docker.service
After=docker.service

[Service]
Restart=always
ExecStartPre=-/bin/docker stop sea-s3
ExecStartPre=-/bin/docker rm -f sea-s3
ExecStart=/bin/docker run \
    --rm \
    --net=host \
    -l app=sea \
    -l component=seaweedfs \
    -v /data/server/sea/data/conf:/etc/seaweedfs \
    -v /data/server/sea/data/cert:/data/cert \
    -v /data/server/sea/log/s3:/data/seaweedfs/log \
    --name sea-s3 \
    registry-public.lenovo.com/earth_system/seaweedfs:3.71 \
    -logdir=/data/seaweedfs/log \
    s3 \
    -port=7203 \
    -port.grpc=17203 \
    -filer=localhost:7202 \
    -ip.bind=0.0.0.0

ExecStop=/bin/docker stop sea-filer
ExecStopPost=/bin/docker rm -f sea-filer

[Install]
WantedBy=multi-user.target
```
* 客户端mount，需要/etc/seaweedfs/security.toml 
```toml
[grpc]
ca = "/data/cert/ca.crt"

[grpc.client]
cert = "/data/cert/server.crt"
key = "/data/cert/server.key
```

* 动态创建s3用户

s3服务启动时如果-config指定了静态认证文件,将无法使用动态配置功能,动态和静态的方式只能使用一种

动态的认证配,s3服务会将配置发送到filer,存储到filer使用的db中

```bash
# weed shell 也需要在主机配置security.toml
weed shell -master localhost:7200 -filer localhost:7202
s3.configure -access_key=any -secret_key=any -buckets=bucket1 -user=me -actions=Read,Write,List,Tagging,Admin -apply
```