# SeaweedFS

## 单点

* 启动脚本

```bash
#!/bin/bash
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
