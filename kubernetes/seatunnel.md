# SeaTunnel

## Docker 部署（Zeta引擎）
```bash
docker pull apache/seatunnel:2.3.11
```

### TCP 到另一个 TCP 

```bash
# 10.122.159.141启动TCPsource
nc -l -p 8888
# 10.122.159.141监听sink 地址
nc -l -p 8889
# 10.122.166.104提交seatunnel任务
mkdir -p /data/workspace/seatunnel-conf
# 创建配置文件
# A single split source allows only one single reader to be created. Please make sure source parallelism = 1
# parallelism 设置为1
cat << EOF >/data/workspace/seatunnel-conf/tcp-tcp.conf
env {
  job.mode = "STREAMING"        // 流式模式
  parallelism = 1               // 并行度
  checkpoint.interval = 10000   // 10秒一次Checkpoint
  job.retry.times = 10
  job.retry.interval.seconds = 10
}
source {
  Socket {
    host = "10.122.159.141"
    port = 8888
    data_format = "raw"         // 原始字节流
  }
}
sink {
  Socket {
    host = "10.122.159.141"
    port = 8889
  }
}
EOF

# 直接提交job并运行
docker run --rm --network host -it \
    -v /data/workspace/seatunnel-conf/:/config \
    apache/seatunnel:2.3.11 ./bin/seatunnel.sh -m local -c /config/tcp-tcp.conf

# seaTunnel作为服务后台运行只有一个master节点,默认8080为web ui 端口
# 默认5801为manager端口
# 只有master无法完成工作
docker network create seatunnel-network
docker run -d --name seatunnel_master --network seatunnel-network -p 8080:8080 -p 5801:5801 \
    apache/seatunnel:2.3.11 ./bin/seatunnel-cluster.sh -r master

# 获取master contianer ip,然后修改worker ST_DOCKER_MEMBER_LIST
docker run -d --name seatunnel_worker1 --network seatunnel-network \
    -e ST_DOCKER_MEMBER_LIST=172.31.0.2:5801 \
    apache/seatunnel:2.3.11 ./bin/seatunnel-cluster.sh -r worker

docker run -d --name seatunnel_worker2 --network seatunnel-network \
    -e ST_DOCKER_MEMBER_LIST=172.31.0.2:5801 \
    apache/seatunnel:2.3.11 ./bin/seatunnel-cluster.sh -r worker
# ------------api-----------------
# 集群概览
curl http://10.122.166.104:8080/overview

# 获取job列表
curl http://10.122.166.104:8080/running-jobs

# job详情
curl http://10.122.166.104:8080/job-info/{jobid}

# 提交job
curl -X POST http://10.122.166.104:8080/submit-job \
  -H "Content-Type: application/json" \
  -d '{
    "env": {
        "job.mode": "streaming",
        "parallelism": 1,
        "checkpoint.interval": 100000,
        "job.retry.times": 10,
        "job.retry.interval.seconds": 10
    },
    "source":[
        {
            "plugin_name": "socket",
            "host": "10.122.159.141",
            "port": 8888
        }
    ],
    "transform":[],
    "sink":[
        {
            "plugin_name": "socket",
            "host": "10.122.159.141",
            "port": 8889
        }
    ]
}'

# 查看完成得job FINISHED,CANCELED,FAILED,UNKNOWABLE
curl  http://10.122.166.104:8080/finished-jobs

# 停止job
curl -X POST http://10.122.166.104:8080/stop-job \
-d '{
    "jobId": 987623192854003713,
    "isStopWithSavePoint": false
}'
```