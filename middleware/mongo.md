# MongoDB

## Docker搭建ReplicaSet

* 创建docker network
```bash
docker network create mongo-net
```
* 启动三个ReplicaSet
```bash
docker run --network mongo-net  --name mongo-1  -d  -p 27021:27017 mongo:6.0.5 --replSet mongo-set
docker run --network mongo-net  --name mongo-2  -d  -p 27022:27017 mongo:6.0.5 --replSet mongo-set
docker run --network mongo-net  --name mongo-3  -d  -p 27023:27017 mongo:6.0.5 --replSet mongo-set
```
* 初始化(只能初始化一次)
```bash
docker exec -i mongo-1 bash -c "echo 'rs.initiate({_id:\"mongo-set\",members:[{_id:0,host:\"mongo-1:27017\"},{_id:1,host:\"mongo-2:27017\"},{_id:2,host:\"mongo-3:27017\"}]})' | mongosh"
```
* 查看ReplicaSet Status
```bash
docker exec -it mongo-1 bash -c "echo 'rs.status()' | mongosh"
```
* Status 结果如下
```json
{
  set: 'mongo-set',
  date: ISODate("2023-07-05T06:13:33.177Z"),
  myState: 1,
  term: Long("1"),
  syncSourceHost: '',
  syncSourceId: -1,
  heartbeatIntervalMillis: Long("2000"),
  majorityVoteCount: 2,
  writeMajorityCount: 2,
  votingMembersCount: 3,
  writableVotingMembersCount: 3,
  optimes: {
    lastCommittedOpTime: { ts: Timestamp({ t: 1688537612, i: 1 }), t: Long("1") },
    lastCommittedWallTime: ISODate("2023-07-05T06:13:32.749Z"),
    readConcernMajorityOpTime: { ts: Timestamp({ t: 1688537612, i: 1 }), t: Long("1") },
    appliedOpTime: { ts: Timestamp({ t: 1688537612, i: 1 }), t: Long("1") },
    durableOpTime: { ts: Timestamp({ t: 1688537612, i: 1 }), t: Long("1") },
    lastAppliedWallTime: ISODate("2023-07-05T06:13:32.749Z"),
    lastDurableWallTime: ISODate("2023-07-05T06:13:32.749Z")
  },
  lastStableRecoveryTimestamp: Timestamp({ t: 1688537592, i: 1 }),
  electionCandidateMetrics: {
    lastElectionReason: 'electionTimeout',
    lastElectionDate: ISODate("2023-07-05T06:09:32.713Z"),
    electionTerm: Long("1"),
    lastCommittedOpTimeAtElection: { ts: Timestamp({ t: 1688537362, i: 1 }), t: Long("-1") },
    lastSeenOpTimeAtElection: { ts: Timestamp({ t: 1688537362, i: 1 }), t: Long("-1") },
    numVotesNeeded: 2,
    priorityAtElection: 1,
    electionTimeoutMillis: Long("10000"),
    numCatchUpOps: Long("0"),
    newTermStartDate: ISODate("2023-07-05T06:09:32.733Z"),
    wMajorityWriteAvailabilityDate: ISODate("2023-07-05T06:09:34.191Z")
  },
  members: [
    {
      _id: 0,
      name: 'mongo-1:27017',
      health: 1,
      state: 1,
      stateStr: 'PRIMARY',
      uptime: 1176,
      optime: { ts: Timestamp({ t: 1688537612, i: 1 }), t: Long("1") },
      optimeDate: ISODate("2023-07-05T06:13:32.000Z"),
      lastAppliedWallTime: ISODate("2023-07-05T06:13:32.749Z"),
      lastDurableWallTime: ISODate("2023-07-05T06:13:32.749Z"),
      syncSourceHost: '',
      syncSourceId: -1,
      infoMessage: '',
      electionTime: Timestamp({ t: 1688537372, i: 1 }),
      electionDate: ISODate("2023-07-05T06:09:32.000Z"),
      configVersion: 1,
      configTerm: 1,
      self: true,
      lastHeartbeatMessage: ''
    },
    {
      _id: 1,
      name: 'mongo-2:27017',
      health: 1,
      state: 2,
      stateStr: 'SECONDARY',
      uptime: 250,
      optime: { ts: Timestamp({ t: 1688537602, i: 1 }), t: Long("1") },
      optimeDurable: { ts: Timestamp({ t: 1688537602, i: 1 }), t: Long("1") },
      optimeDate: ISODate("2023-07-05T06:13:22.000Z"),
      optimeDurableDate: ISODate("2023-07-05T06:13:22.000Z"),
      lastAppliedWallTime: ISODate("2023-07-05T06:13:32.749Z"),
      lastDurableWallTime: ISODate("2023-07-05T06:13:32.749Z"),
      lastHeartbeat: ISODate("2023-07-05T06:13:32.726Z"),
      lastHeartbeatRecv: ISODate("2023-07-05T06:13:32.231Z"),
      pingMs: Long("0"),
      lastHeartbeatMessage: '',
      syncSourceHost: 'mongo-1:27017',
      syncSourceId: 0,
      infoMessage: '',
      configVersion: 1,
      configTerm: 1
    },
    {
      _id: 2,
      name: 'mongo-3:27017',
      health: 1,
      state: 2,
      stateStr: 'SECONDARY',
      uptime: 250,
      optime: { ts: Timestamp({ t: 1688537602, i: 1 }), t: Long("1") },
      optimeDurable: { ts: Timestamp({ t: 1688537602, i: 1 }), t: Long("1") },
      optimeDate: ISODate("2023-07-05T06:13:22.000Z"),
      optimeDurableDate: ISODate("2023-07-05T06:13:22.000Z"),
      lastAppliedWallTime: ISODate("2023-07-05T06:13:32.749Z"),
      lastDurableWallTime: ISODate("2023-07-05T06:13:32.749Z"),
      lastHeartbeat: ISODate("2023-07-05T06:13:32.726Z"),
      lastHeartbeatRecv: ISODate("2023-07-05T06:13:32.230Z"),
      pingMs: Long("0"),
      lastHeartbeatMessage: '',
      syncSourceHost: 'mongo-1:27017',
      syncSourceId: 0,
      infoMessage: '',
      configVersion: 1,
      configTerm: 1
    }
  ],
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1688537612, i: 1 }),
    signature: {
      hash: Binary(Buffer.from("0000000000000000000000000000000000000000", "hex"), 0),
      keyId: Long("0")
    }
  },
  operationTime: Timestamp({ t: 1688537612, i: 1 })
}
```
* join 节点
```bash
docker run --network mongo-net  --name mongo-4 -d  -p 27024:27017 mongo:6.0.5 --replSet mongo-set
docker exec -i mongo-1 bash -c "echo 'rs.add(\"mongo-4:27017\")' | mongosh"
```
* 删除节点
```bash
docker exec -i mongo-1 bash -c "echo 'rs.remove(\"mongo-4:27017\")' | mongosh"
```
* 主从切换
mongo replicaSet 具有自动切换主从的功能，由状态可知 mongo-1 当前为主，当mongo-1 停止服务时，将自动触发主备切换
```bash
docker stop mongo-1
docker exec -it mongo-2 bash -c "echo 'rs.status()' | mongosh"
```
当前状态如下,mongo-2 当前为新的主节点
```json
{
  set: 'mongo-set',
  date: ISODate("2023-07-05T06:38:58.210Z"),
  myState: 1,
  term: Long("2"),
  syncSourceHost: '',
  syncSourceId: -1,
  heartbeatIntervalMillis: Long("2000"),
  majorityVoteCount: 2,
  writeMajorityCount: 2,
  votingMembersCount: 3,
  writableVotingMembersCount: 3,
  optimes: {
    lastCommittedOpTime: { ts: Timestamp({ t: 1688539129, i: 1 }), t: Long("2") },
    lastCommittedWallTime: ISODate("2023-07-05T06:38:49.614Z"),
    readConcernMajorityOpTime: { ts: Timestamp({ t: 1688539129, i: 1 }), t: Long("2") },
    appliedOpTime: { ts: Timestamp({ t: 1688539129, i: 1 }), t: Long("2") },
    durableOpTime: { ts: Timestamp({ t: 1688539129, i: 1 }), t: Long("2") },
    lastAppliedWallTime: ISODate("2023-07-05T06:38:49.614Z"),
    lastDurableWallTime: ISODate("2023-07-05T06:38:49.614Z")
  },
  lastStableRecoveryTimestamp: Timestamp({ t: 1688539112, i: 1 }),
  electionCandidateMetrics: {
    lastElectionReason: 'stepUpRequestSkipDryRun',
    lastElectionDate: ISODate("2023-07-05T06:38:39.601Z"),
    electionTerm: Long("2"),
    lastCommittedOpTimeAtElection: { ts: Timestamp({ t: 1688539112, i: 1 }), t: Long("1") },
    lastSeenOpTimeAtElection: { ts: Timestamp({ t: 1688539112, i: 1 }), t: Long("1") },
    numVotesNeeded: 2,
    priorityAtElection: 1,
    electionTimeoutMillis: Long("10000"),
    priorPrimaryMemberId: 0,
    numCatchUpOps: Long("0"),
    newTermStartDate: ISODate("2023-07-05T06:38:39.613Z"),
    wMajorityWriteAvailabilityDate: ISODate("2023-07-05T06:38:40.608Z")
  },
  electionParticipantMetrics: {
    votedForCandidate: true,
    electionTerm: Long("1"),
    lastVoteDate: ISODate("2023-07-05T06:09:32.714Z"),
    electionCandidateMemberId: 0,
    voteReason: '',
    lastAppliedOpTimeAtElection: { ts: Timestamp({ t: 1688537362, i: 1 }), t: Long("-1") },
    maxAppliedOpTimeInSet: { ts: Timestamp({ t: 1688537362, i: 1 }), t: Long("-1") },
    priorityAtElection: 1
  },
  members: [
    {
      _id: 0,
      name: 'mongo-1:27017',
      health: 0,
      state: 8,
      stateStr: '(not reachable/healthy)',
      uptime: 0,
      optime: { ts: Timestamp({ t: 0, i: 0 }), t: Long("-1") },
      optimeDurable: { ts: Timestamp({ t: 0, i: 0 }), t: Long("-1") },
      optimeDate: ISODate("1970-01-01T00:00:00.000Z"),
      optimeDurableDate: ISODate("1970-01-01T00:00:00.000Z"),
      lastAppliedWallTime: ISODate("2023-07-05T06:38:39.613Z"),
      lastDurableWallTime: ISODate("2023-07-05T06:38:39.613Z"),
      lastHeartbeat: ISODate("2023-07-05T06:38:56.244Z"),
      lastHeartbeatRecv: ISODate("2023-07-05T06:38:48.615Z"),
      pingMs: Long("0"),
      lastHeartbeatMessage: 'Error connecting to mongo-1:27017 :: caused by :: Could not find address for mongo-1:27017: SocketException: Host not found (authoritative)',
      syncSourceHost: '',
      syncSourceId: -1,
      infoMessage: '',
      configVersion: 4,
      configTerm: 2
    },
    {
      _id: 1,
      name: 'mongo-2:27017',
      health: 1,
      state: 1,
      stateStr: 'PRIMARY',
      uptime: 2692,
      optime: { ts: Timestamp({ t: 1688539129, i: 1 }), t: Long("2") },
      optimeDate: ISODate("2023-07-05T06:38:49.000Z"),
      lastAppliedWallTime: ISODate("2023-07-05T06:38:49.614Z"),
      lastDurableWallTime: ISODate("2023-07-05T06:38:49.614Z"),
      syncSourceHost: '',
      syncSourceId: -1,
      infoMessage: '',
      electionTime: Timestamp({ t: 1688539119, i: 1 }),
      electionDate: ISODate("2023-07-05T06:38:39.000Z"),
      configVersion: 4,
      configTerm: 2,
      self: true,
      lastHeartbeatMessage: ''
    },
    {
      _id: 2,
      name: 'mongo-3:27017',
      health: 1,
      state: 2,
      stateStr: 'SECONDARY',
      uptime: 1775,
      optime: { ts: Timestamp({ t: 1688539129, i: 1 }), t: Long("2") },
      optimeDurable: { ts: Timestamp({ t: 1688539129, i: 1 }), t: Long("2") },
      optimeDate: ISODate("2023-07-05T06:38:49.000Z"),
      optimeDurableDate: ISODate("2023-07-05T06:38:49.000Z"),
      lastAppliedWallTime: ISODate("2023-07-05T06:38:49.614Z"),
      lastDurableWallTime: ISODate("2023-07-05T06:38:49.614Z"),
      lastHeartbeat: ISODate("2023-07-05T06:38:57.614Z"),
      lastHeartbeatRecv: ISODate("2023-07-05T06:38:57.616Z"),
      pingMs: Long("0"),
      lastHeartbeatMessage: '',
      syncSourceHost: 'mongo-2:27017',
      syncSourceId: 1,
      infoMessage: '',
      configVersion: 4,
      configTerm: 2
    }
  ],
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1688539129, i: 1 }),
    signature: {
      hash: Binary(Buffer.from("0000000000000000000000000000000000000000", "hex"), 0),
      keyId: Long("0")
    }
  },
  operationTime: Timestamp({ t: 1688539129, i: 1 })
}
```
* 重新启动mongo-1 集群状态恢复
```bash
docker restart mongo-1
docker exec -it mongo-2 bash -c "echo 'rs.status()' | mongosh"
```
状态如下，mongo-2 任为主节点，mongo-1 变为从节点
```json
{
  set: 'mongo-set',
  date: ISODate("2023-07-05T06:43:43.563Z"),
  myState: 1,
  term: Long("2"),
  syncSourceHost: '',
  syncSourceId: -1,
  heartbeatIntervalMillis: Long("2000"),
  majorityVoteCount: 2,
  writeMajorityCount: 2,
  votingMembersCount: 3,
  writableVotingMembersCount: 3,
  optimes: {
    lastCommittedOpTime: { ts: Timestamp({ t: 1688539419, i: 1 }), t: Long("2") },
    lastCommittedWallTime: ISODate("2023-07-05T06:43:39.622Z"),
    readConcernMajorityOpTime: { ts: Timestamp({ t: 1688539419, i: 1 }), t: Long("2") },
    appliedOpTime: { ts: Timestamp({ t: 1688539419, i: 1 }), t: Long("2") },
    durableOpTime: { ts: Timestamp({ t: 1688539419, i: 1 }), t: Long("2") },
    lastAppliedWallTime: ISODate("2023-07-05T06:43:39.622Z"),
    lastDurableWallTime: ISODate("2023-07-05T06:43:39.622Z")
  },
  lastStableRecoveryTimestamp: Timestamp({ t: 1688539409, i: 1 }),
  electionCandidateMetrics: {
    lastElectionReason: 'stepUpRequestSkipDryRun',
    lastElectionDate: ISODate("2023-07-05T06:38:39.601Z"),
    electionTerm: Long("2"),
    lastCommittedOpTimeAtElection: { ts: Timestamp({ t: 1688539112, i: 1 }), t: Long("1") },
    lastSeenOpTimeAtElection: { ts: Timestamp({ t: 1688539112, i: 1 }), t: Long("1") },
    numVotesNeeded: 2,
    priorityAtElection: 1,
    electionTimeoutMillis: Long("10000"),
    priorPrimaryMemberId: 0,
    numCatchUpOps: Long("0"),
    newTermStartDate: ISODate("2023-07-05T06:38:39.613Z"),
    wMajorityWriteAvailabilityDate: ISODate("2023-07-05T06:38:40.608Z")
  },
  electionParticipantMetrics: {
    votedForCandidate: true,
    electionTerm: Long("1"),
    lastVoteDate: ISODate("2023-07-05T06:09:32.714Z"),
    electionCandidateMemberId: 0,
    voteReason: '',
    lastAppliedOpTimeAtElection: { ts: Timestamp({ t: 1688537362, i: 1 }), t: Long("-1") },
    maxAppliedOpTimeInSet: { ts: Timestamp({ t: 1688537362, i: 1 }), t: Long("-1") },
    priorityAtElection: 1
  },
  members: [
    {
      _id: 0,
      name: 'mongo-1:27017',
      health: 1,
      state: 2,
      stateStr: 'SECONDARY',
      uptime: 41,
      optime: { ts: Timestamp({ t: 1688539419, i: 1 }), t: Long("2") },
      optimeDurable: { ts: Timestamp({ t: 1688539419, i: 1 }), t: Long("2") },
      optimeDate: ISODate("2023-07-05T06:43:39.000Z"),
      optimeDurableDate: ISODate("2023-07-05T06:43:39.000Z"),
      lastAppliedWallTime: ISODate("2023-07-05T06:43:39.622Z"),
      lastDurableWallTime: ISODate("2023-07-05T06:43:39.622Z"),
      lastHeartbeat: ISODate("2023-07-05T06:43:41.605Z"),
      lastHeartbeatRecv: ISODate("2023-07-05T06:43:43.070Z"),
      pingMs: Long("0"),
      lastHeartbeatMessage: '',
      syncSourceHost: 'mongo-3:27017',
      syncSourceId: 2,
      infoMessage: '',
      configVersion: 4,
      configTerm: 2
    },
    {
      _id: 1,
      name: 'mongo-2:27017',
      health: 1,
      state: 1,
      stateStr: 'PRIMARY',
      uptime: 2977,
      optime: { ts: Timestamp({ t: 1688539419, i: 1 }), t: Long("2") },
      optimeDate: ISODate("2023-07-05T06:43:39.000Z"),
      lastAppliedWallTime: ISODate("2023-07-05T06:43:39.622Z"),
      lastDurableWallTime: ISODate("2023-07-05T06:43:39.622Z"),
      syncSourceHost: '',
      syncSourceId: -1,
      infoMessage: '',
      electionTime: Timestamp({ t: 1688539119, i: 1 }),
      electionDate: ISODate("2023-07-05T06:38:39.000Z"),
      configVersion: 4,
      configTerm: 2,
      self: true,
      lastHeartbeatMessage: ''
    },
    {
      _id: 2,
      name: 'mongo-3:27017',
      health: 1,
      state: 2,
      stateStr: 'SECONDARY',
      uptime: 2060,
      optime: { ts: Timestamp({ t: 1688539419, i: 1 }), t: Long("2") },
      optimeDurable: { ts: Timestamp({ t: 1688539419, i: 1 }), t: Long("2") },
      optimeDate: ISODate("2023-07-05T06:43:39.000Z"),
      optimeDurableDate: ISODate("2023-07-05T06:43:39.000Z"),
      lastAppliedWallTime: ISODate("2023-07-05T06:43:39.622Z"),
      lastDurableWallTime: ISODate("2023-07-05T06:43:39.622Z"),
      lastHeartbeat: ISODate("2023-07-05T06:43:41.619Z"),
      lastHeartbeatRecv: ISODate("2023-07-05T06:43:41.618Z"),
      pingMs: Long("0"),
      lastHeartbeatMessage: '',
      syncSourceHost: 'mongo-2:27017',
      syncSourceId: 1,
      infoMessage: '',
      configVersion: 4,
      configTerm: 2
    }
  ],
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1688539419, i: 1 }),
    signature: {
      hash: Binary(Buffer.from("0000000000000000000000000000000000000000", "hex"), 0),
      keyId: Long("0")
    }
  },
  operationTime: Timestamp({ t: 1688539419, i: 1 })
}
```
* 环境清理
```bash
docker exec -i mongo-1 bash -c "echo 'rs.remove(\"mongo-4:27017\")' | mongosh"
```
## 为ReplicaSet添加认证

默认mongdb replicaSet 启动后可以连接任何数据库,现在我们为replicaSet添加用户密码认证

* 在mongod 配置文件中开启认证并指定keyfile 的位置
```txt
net:
  bindIp: 0.0.0.0
  port: 27017
replication:
  replSetName: mongo-set  #副本集名称
security:
  authorization: enabled  #开启认证
  keyFile: /conf/keyfile  #keyfile文件地址
storage:
  dbPath: /data           #数据库文件存储路径  
  engine: wiredTiger      #数据库默认引擎MongoDB 3.2及更高版本中,默认引擎是 WiredTiger
  wiredTiger:
    engineConfig:
      journalCompressor: zlib  #设置了journal日志的压缩算法,默认为zlib
```

keyfile [详细介绍](https://www.mongodb.com/docs/v5.0/tutorial/deploy-replica-set-with-keyfile-access-control/)

```txt
a//XadVYX3i/UgaZPI/1QPjoXBcL+uhpP4KN0Xr05XY+PjHWkfiLfxqMsQGMC1qMi+ChsZpCnQ71aRXDBwD7Y/a9P/bpMUdPl2iAJUSXjGwJMGqX4Q2kHxOO2okfBp10VsvYeuPKokIXg6YorhD0087W1Nf+TEOSdC2QeuszQSVtIHZeY8AVThmGy6IVpBP7eFzIvWX/MJlQW2M6sELXrLhzFQCBjtwDrVqYI3QMN63jKjNP4wXSI9bxMAVu5zkcBdLJ5r4XglVnts8IDt6DKd0zM1neNwCTVwamLa6DkBLtvntSg7VXhsbzhy+4n1waaLKuPaRxII6wALg6OGP+kDKO7fkASBaXiMPV9C8nT/XTkwzENN0K7s0kPoev+knH8I409IGos7R1gIOW0Ma2UUMEZT5JLBrDLv4DI+2GFTy5KpFy2K6Ak0cWn28EIqrgq5DkNGOA9dCwSN9jPdtunM+g4lScFxUyGn1WmKzIJlzkFZTfD4SwPz2f7GbX8wXR+0nkUYbu9r1QkR5q7dL33+ihZzfdMz3sfbJvjr/ons5Bj0xNdvpFfH9zTEg9zW+Mn2MWMKtrp34PqQPvHl7lslEleVmnKiCeFG9LxY6nETMNc8wyzUJOrYJ7Pwk1edDd4oqm7Dj/ULpwJh5yb22goRW/oFc=
```

* 使用mongo.conf 启动mongodb
```bash
# 注意：keyfile 文件权限必须为400
docker run --network mongo-net  --name mongo-1 -v ${your_volume_path}:/conf -d  -p 27021:27017 mongo:6.0.5 bash -c "chmod 400 /conf/keyfile && exec mongod -f /conf/mongod.conf"
```

* 初始化ReplicaSet

* 初始化后添加首个拥有admin权限用户，添加该用户后，所有客户端将必须认证后才能访问数据库信息
```bash
docker exec -it mongo-1 bash
mongsh
use admin
db.createUser({user:"root",pwd:"root",roles:[{role:"userAdminAnyDatabase",db:"admin"},{role:"readWriteAnyDatabase",db:"admin"},{role:"clusterAdmin",db:"admin"}]})
```

* 未认证访问数据库信息如下，则认证添加成功
```bash
mongo [direct: secondary] test> rs.status();
MongoServerError: command replSetGetStatus requires authentication
```

## kubernetes 部署ReplicaSet

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: mongo-keyfile
data:
  keyfile: YS8vWGFkVllYM2kvVWdhWlBJLzFRUGpvWEJjTCt1aHBQNEtOMFhyMDVYWStQakhXa2ZpTGZ4cU1zUUdNQzFxTWkrQ2hzWnBDblE3MWFSWERCd0Q3WS9hOVAvYnBNVWRQbDJpQUpVU1hqR3dKTUdxWDRRMmtIeE9PMm9rZkJwMTBWc3ZZZXVQS29rSVhnNllvcmhEMDA4N1cxTmYrVEVPU2RDMlFldXN6UVNWdElIWmVZOEFWVGhtR3k2SVZwQlA3ZUZ6SXZXWC9NSmxRVzJNNnNFTFhyTGh6RlFDQmp0d0RyVnFZSTNRTU42M2pLak5QNHdYU0k5YnhNQVZ1NXprY0JkTEo1cjRYZ2xWbnRzOElEdDZES2Qwek0xbmVOd0NUVndhbUxhNkRrQkx0dm50U2c3Vlhoc2J6aHkrNG4xd2FhTEt1UGFSeElJNndBTGc2T0dQK2tES083ZmtBU0JhWGlNUFY5QzhuVC9YVGt3ekVOTjBLN3Mwa1BvZXYra25IOEk0MDlJR29zN1IxZ0lPVzBNYTJVVU1FWlQ1SkxCckRMdjRESSsyR0ZUeTVLcEZ5Mks2QWswY1duMjhFSXFyZ3E1RGtOR09BOWRDd1NOOWpQZHR1bk0rZzRsU2NGeFV5R24xV21LeklKbHprRlpUZkQ0U3dQejJmN0diWDh3WFIrMG5rVVlidTlyMVFrUjVxN2RMMzMraWhaemZkTXozc2ZiSnZqci9vbnM1QmoweE5kdnBGZkg5elRFZzl6VytNbjJNV01LdHJwMzRQcVFQdkhsN2xzbEVsZVZtbktpQ2VGRzlMeFk2bkVUTU5jOHd5elVKT3JZSjdQd2sxZWREZDRvcW03RGovVUxwd0poNXliMjJnb1JXL29GYz0=
---
apiVersion: v1
kind: Secret
metadata:
  name: root-user
data:
  username: cm9vdAo=
  password: cm9vdAo=
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: mongo-cm
data:
  mongod.conf: |
    net:
      bindIp: 0.0.0.0
      port: 27017
    replication:
      replSetName: mongo
    security:
      authorization: enabled
      keyFile: /auth/keyfile
    storage:
      dbPath: /data
      engine: wiredTiger
      wiredTiger:
        engineConfig:
          journalCompressor: zlib
---
apiVersion: v1
kind: Service
metadata:
  name: mongo-svc
spec:
  clusterIP: None
  ports:
  - name: mongodb
    port: 27017
    protocol: TCP
    targetPort: 27017
  publishNotReadyAddresses: true
  selector:
    app: earth-middleware
    middleware: mongo
  type: ClusterIP
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongo
spec:
  podManagementPolicy: OrderedReady
  replicas: 3
  selector:
    matchLabels:
      app: earth-middleware
      middleware: mongo
  serviceName: mongo-svc
  template:
    metadata:
      labels:
        app: earth-middleware
        middleware: mongo
      name: mongo
      annotations:
        restart: "true"
    spec:
      containers:
      - name: mongod
        image: localhost:5000/earth-middleware/mongo:6.0.5
        imagePullPolicy: IfNotPresent
        command:
          - /bin/bash
          - -c
          - |
            exec mongod -f /conf/mongod.conf
        env:
        - name: INIT_USERNAME
          valueFrom:
            secretKeyRef:
              name: root-user
              key: username
        - name: INIT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: root-user
              key: password
        ports:
        - containerPort: 27017
          name: client
          protocol: TCP
        resources:
          limits:
            cpu: "200m"
            memory: 250Mi
          requests:
            cpu: "200m"
            memory: 250Mi
        volumeMounts:
        - mountPath: /data
          name: mongo
        - mountPath: /conf
          name: conf
        - mountPath: /auth
          name: keyfile
      volumes:
      - name: conf
        projected:
          defaultMode: 0400
          sources:
          - configMap:
              name: mongo-cm
      - name: keyfile
        secret:
          secretName: mongo-keyfile

          defaultMode: 0400
  updateStrategy:
    type: RollingUpdate
  volumeClaimTemplates:
  - apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: mongo
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
```

* 初始化
```bash
kubectl exec -it mongo-0 -- bash
mongosh
rs.initiate({_id:"mongo",members:[{_id:0,host:"mongo-0.mongo-svc.default.svc:27017"},{_id:1,host:"mongo-1.mongo-svc.default.svc:27017"},{_id:2,host:"mongo-2.mongo-svc.default.svc:27017"}]})
use admin
db.createUser({user:"root",pwd:"root",roles:[{role:"userAdminAnyDatabase",db:"admin"},{role:"readWriteAnyDatabase",db:"admin"},{role:"clusterAdmin",db:"admin"}]})
exit
```

## 部署MongoDB Operator

* 下载源码
```bash
git clone https://github.com/mongodb/mongodb-kubernetes-operator.git
```

* 修改ClusterRoleBinding为部署的namespace,文件路径为 deploy/clusterwide/cluster_role_binding.yaml

* 部署Operator
```bash
kubectl apply -f deploy/clusterwide
kubectl apply -k config/rbac --namespace default
kubectl apply -f config/crd/bases/mongodbcommunity.mongodb.com_mongodbcommunity.yaml
kubectl create -f config/manager/manager.yaml --namespace default
```

* 部署3节点ReplicaSet
```yaml
apiVersion: mongodbcommunity.mongodb.com/v1
kind: MongoDBCommunity
metadata:
  name: example-mongodb
spec:
  members: 3
  type: ReplicaSet
  version: "6.0.5"
  security:
    authentication:
      modes: ["SCRAM"]
  users:
    - name: user1
      db: admin
      passwordSecretRef:
        name: my-user-password
      roles:
        - name: clusterAdmin
          db: admin
        - name: userAdminAnyDatabase
          db: admin
      scramCredentialsSecretName: my-scram
  additionalMongodConfig:
    storage.wiredTiger.engineConfig.journalCompressor: zlib
  statefulSet:
    spec:
      template:
        spec:
          containers:
            - name: mongod
              resources:
                limits:
                  cpu: "0.2"
                  memory: 250M
                requests:
                  cpu: "0.2"
                  memory: 200M
            - name: mongodb-agent
              resources:
                limits:
                  cpu: "0.2"
                  memory: 250M
                requests:
                  cpu: "0.2"
                  memory: 200M
---
apiVersion: v1
kind: Secret
metadata:
  name: my-user-password
type: Opaque
stringData:
  password: MTIzNDU2
```
