# Mysql

## 主从环境搭建

Mysql5.7


## 常用参数说明

|参数|说明|
|----|---|
|server-id|服务器唯一ID，在同一复制集群内必须唯一，从库ID不能与主库相同|    
|gtid_mode|	开启 GTID 模式|
|enforce_gtid_consistency|强制GTID一致性，确保所有事务都能安全地以GTID模式记录|
|log-bin|开启binlog日志|
|binlog_format|	设置二进制日志的格式为行格式。此格式基于数据行的变化进行记录，能最大程度保证主从数据的一致性，是GTID复制下的推荐设置|
|expire_logs_days| 设置binlog日志的自动过期时间|
|plugin-load |"semisync_master.so;semisync_slave.so" 加载半同步复制插件|
|rpl_semi_sync_master_enabled| 是否在主库（Master）启用半同步复制功能。作用：设置为 ON 时，主库会等待至少有一个从库确认收到 binlog 后，事务才提交成功。否则主库直接提交事务，不等待从库确认（即异步复制）|
|rpl_semi_sync_slave_enabled| 是否在从库（Slave）启用半同步复制功能。作用：设置为 ON 时，从库会向主库发送确认（ACK），告知主库自己已收到 binlog。否则不发送确认，主库无法实现半同步。|
|rpl_semi_sync_master_wait_no_slave |控制在主库（Master）启用半同步复制时，如果没有任何半同步从库连接，主库是否继续等待从库的 ACK（确认）。ON：即使没有半同步从库，主库也会一直等待，不会自动切换为异步复制模式，可能导致主库写操作阻。OFF（默认）：如果没有半同步从库，主库会自动切换为异步复制模式，不会阻塞写操作。|
|read_only| 设置从库只读|
|log-slave-updates|	从库将重放主库的事务也记录到自己的二进制日志中。这在链式复制（A->B->C）或需要以该从库为基础再搭建从库时是必须的|

## 搭建过程

```bash
mkdir -p /data/mysql/master/{conf,data}
cat <<EOF >/data/mysql/master/conf/my.cnf
[mysqld]
server-id=1
gtid_mode=ON
enforce_gtid_consistency=ON
log-bin=mysql-bin
binlog_format=ROW
expire_logs_days = 1
plugin-load = "semisync_master.so;semisync_slave.so"
rpl_semi_sync_master_enabled = ON
rpl_semi_sync_master_timeout = 1000000000000000000
rpl_semi_sync_master_wait_no_slave = OFF
rpl_semi_sync_slave_enabled = OFF
EOF

mkdir -p /data/mysql/mslave/{conf,data}
cat <<EOF >/data/mysql/mslave/conf/my.cnf
[mysqld]
server-id=2
gtid_mode=ON
enforce_gtid_consistency=ON
log-bin=mysql-bin
binlog_format=ROW
expire_logs_days = 1
plugin-load = "semisync_master.so;semisync_slave.so"
rpl_semi_sync_master_enabled = OFF
rpl_semi_sync_master_timeout = 1000000000000000000
rpl_semi_sync_master_wait_no_slave = OFF
rpl_semi_sync_slave_enabled = ON
read_only=ON
log-slave-updates = on
EOF

# master
docker run -d \
    --name mysql-master \
    -e MYSQL_ROOT_PASSWORD=mysql-1234 \
    -p 13306:3306 \
    -v /data/mysql/master/conf:/etc/mysql/conf.d \
    -v /data/mysql/master/data:/var/lib/mysql \
    mysql:5.7

# slave
docker run -d \
  --name mysql-mslave \
  -e MYSQL_ROOT_PASSWORD=mysql-1234 \
  -p 13307:3306 \
  -v /data/mysql/mslave/conf:/etc/mysql/conf.d \
  -v /data/mysql/mslave/data:/var/lib/mysql \
  mysql:5.7

# 登录master
docker exec -it mysql-master mysql -uroot -pmysql-1234

# 创建repl用户，指定密码为repl-1234
CREATE USER 'repl'@'%' IDENTIFIED BY 'repl-1234';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;

# 查看master状态, 记录下File和Position的值
# 如果不开启GTID,则需要使用File和Position进行配置
show master status\G;
# *************************** 1. row ***************************
#              File: mysql-bin.000003
#          Position: 787
#      Binlog_Do_DB:
#  Binlog_Ignore_DB:
# Executed_Gtid_Set: 9196d4ee-b94f-11f0-8018-0242ac110004:1-8

# 登录msalve
docker exec -it mysql-mslave mysql -uroot -pmysql-1234 

# 开启gitid后，不能再使用File和Position方式进行配置，从而报错
# ERROR 1776 (HY000): Parameters MASTER_LOG_FILE, MASTER_LOG_POS, RELAY_LOG_FILE and RELAY_LOG_POS cannot be set when MASTER_AUTO_POSITION is active.
CHANGE MASTER TO
  MASTER_HOST='10.122.166.115',
  MASTER_PORT=13306,
  MASTER_USER='repl',
  MASTER_PASSWORD='repl-1234',
  MASTER_AUTO_POSITION=1;
START SLAVE;

# 查看Slave状态
show slave status\G;
```
## 测试

### 测试从库只读

```bash
# 登录主库
docker exec -it mysql-master mysql -uroot -pmysql-1234 
# 创建Database
CREATE DATABASE testdb;
# 创建普通用户,Readonly对包含super权限的用户无效
CREATE USER 'testuser'@'%' IDENTIFIED BY 'testuser-1234';
GRANT ALL PRIVILEGES ON testdb.* TO 'testuser'@'%';
FLUSH PRIVILEGES;


# 使用testuser用户在主库插入数据
docker exec -it mysql-master mysql -utestuser -ptestuser-1234
USE testdb; CREATE TABLE t1(id INT PRIMARY KEY); INSERT INTO t1 VALUES(3);


# 在从库尝试插入数据（应报错，提示只读）
docker exec -it mysql-mslave mysql -utestuser -ptestuser-1234
USE testdb; CREATE TABLE t1(id INT PRIMARY KEY); INSERT INTO t1 VALUES(4);

# 预期输出
# ERROR 1290 (HY000): The MySQL server is running with the --read-only option so it cannot execute this statement
```

### 主备切换

```bash
# 配置从库为新主库并允许写入
docker exec -it mysql-mslave mysql -uroot -pmysql-1234

STOP SLAVE; RESET SLAVE ALL;

# 取消只读
SET GLOBAL read_only=OFF;
# 设置半同步参数
SET GLOBAL rpl_semi_sync_master_enabled=ON;
SET GLOBAL rpl_semi_sync_slave_enabled=OFF;


# 原主库降级为从库
docker exec -it mysql-master mysql -uroot -pmysql-1234

SET GLOBAL read_only=ON;
CHANGE MASTER TO
  MASTER_HOST='10.122.166.115', 
  MASTER_PORT=13307,        
  MASTER_USER='repl',
  MASTER_PASSWORD='repl-1234',
  MASTER_AUTO_POSITION=1;
START SLAVE;

# 在原主库测试写入，报错
docker exec -it mysql-master mysql -utestuser -ptestuser-1234
USE testdb; INSERT INTO t1 VALUES(2000);
```

### 测试备份

* 创建测试数据
```bash
# 在主库插入数据
echo "INSERT INTO t1 (id) VALUES" > insert.sql
for i in $(seq 500 1000); do
  if [ $i -eq 1000 ]; then
    echo "($i);" >> insert.sql
  else
    echo "($i)," >> insert.sql
  fi
done

docker exec -i mysql-master mysql -utestuser -ptestuser-1234 testdb < insert.sql

# 查看从库数据是否保存
docker exec -it mysql-mslave mysql -utestuser -ptestuser-1234
USE testdb; SELECT COUNT(*) FROM t1;
```
* 执行备份

```Dockerfile
FROM percona/percona-xtrabackup:2.4
USER root
RUN echo "mysql:x:999:" >> /etc/group && \
    echo "mysql:x:999:999::/home/mysql:/bin/sh" >> /etc/passwd
RUN mkdir /xtrabackup_backupfiles && chown mysql:mysql  /xtrabackup_backupfiles && chmod 755 /xtrabackup_backupfiles
USER mysql
CMD ["xtrabackup"]
```

```bash
groupadd -r mysql
useradd -r -g mysql mysql
chown -R mysql:mysql /data/mysql
chmod -R 755 /data/mysql

# 使用 percona/percona-xtrabackup:2.4 备份 MySQL 到 S3
docker run --rm  -it --name backup \
    --network host \
    -v /data/mysql/master/data:/var/lib/mysql \
    -e AWS_ACCESS_KEY_ID=minioadmin \
    -e AWS_SECRET_ACCESS_KEY=xcloud@lenovo \
    xtrabackup:2.4 bash


xtrabackup --backup \
    --host=10.122.166.115 \
    --port=13306 \
    --user=root \
    --password=mysql-1234 \
    --stream=xbstream \
    > /xtrabackup_backupfiles/backup-001.xbstream
```

### binlog删除

```bash
# 执行过主备切换后 mysql-master已经是从库了，在从库执行备份

# 在主库执行删除binlog
docker exec -it mysql-master mysql -uroot -pmysql-1234

# 查看binlog日志列表
SHOW BINARY LOGS;
# mysql> SHOW BINARY LOGS;
# +------------------+-----------+
# | Log_name         | File_size |
# +------------------+-----------+
# | mysql-bin.000001 |       177 |
# | mysql-bin.000002 |   3084237 |
# | mysql-bin.000003 |      5176 |
# | mysql-bin.000004 |       194 |
# +------------------+-----------+

# 在主从上都删除mysql-bin.000004之前的日志
PURGE BINARY LOGS TO 'mysql-bin.000004';
```

### binlog清除后创建新的slave

```bash
mkdir -p /data/mysql/slave/{conf,data}
cat <<EOF >/data/mysql/slave/conf/my.cnf
[mysqld]
server-id=3
gtid_mode=ON
enforce_gtid_consistency=ON
log-bin=mysql-bin
binlog_format=ROW
expire_logs_days = 1
plugin-load = "semisync_master.so;semisync_slave.so"
rpl_semi_sync_master_enabled = OFF
rpl_semi_sync_master_timeout = 1000000000000000000
rpl_semi_sync_master_wait_no_slave = OFF
rpl_semi_sync_slave_enabled = ON
read_only=ON
log-slave-updates = on
EOF

docker run -d \
  --name mysql-slave \
  -e MYSQL_ROOT_PASSWORD=mysql-1234 \
  -p 13308:3306 \
  -v /data/mysql/slave/conf:/etc/mysql/conf.d \
  -v /data/mysql/slave/data:/var/lib/mysql \
  mysql:5.7

docker exec -it mysql-slave mysql -uroot -pmysql-1234 

CHANGE MASTER TO
  MASTER_HOST='10.122.166.115',
  MASTER_PORT=13307,
  MASTER_USER='repl',
  MASTER_PASSWORD='repl-1234',
  MASTER_AUTO_POSITION=1;
START SLAVE;

# 因为主库的binlog已经被清除，slave无法拉取到数据，show slave status\G报错:
# Got fatal error 1236 from master when reading data from binary log: 'The slave is connecting using CHANGE MASTER TO MASTER_AUTO_POSITION = 1, but the master has purged binary logs containing GTIDs that the slave requires. Replicate the missing transactions from elsewhere, or provision a new slave from backup. Consider increasing the master's binary log expiration period. The GTID set sent by the slave is '9e81ec41-b9f5-11f0-87ed-0242ac110006:1-5', and the missing transactions are '5c144016-b957-11f0-a2fa-0242ac110004:1-17, 5f502c0e-b957-11f0-b2b4-0242ac110005:1-6'.'

# 恢复过程

# 停止Slave的binlog
SET sql_log_bin=0;

# 注意挂载的文件夹权限
# 注意mysql用户uid gid 都为999，检查/etc/group和/etc/passwd
chown -R mysql:mysql /data/mysql/backup
chmod 750 /data/mysql/backup/backup-001.xbstream
docker run --rm  -it --name backup \
    --network host \
    -v /data/mysql/backup:/xtrabackup_backupfiles \
    -e AWS_ACCESS_KEY_ID=minioadmin \
    -e AWS_SECRET_ACCESS_KEY=xcloud@lenovo \
    xtrabackup:2.4 bash

# 解压
mkdir /tmp/backup
xbstream -x < /xtrabackup_backupfiles/backup-001.xbstream -C /xtrabackup_backupfiles/

docker stop mysql-slave
# 清理slave
rm -rf /data/mysql/slave/data/*
# 恢复数据
cp -r /xtrabackup_backupfiles/* /data/mysql/slave/data/
# 修改权限
chown -R mysql:mysql /data/mysql/slave/data

docker exec -it mysql-slave mysql -uroot -pmysql-1234
SET sql_log_bin=1;
CHANGE MASTER TO
  MASTER_HOST='10.122.166.115',
  MASTER_PORT=13307,
  MASTER_USER='repl',
  MASTER_PASSWORD='repl-1234',
  MASTER_AUTO_POSITION=1;
START SLAVE;

# 查看Slave状态
show slave status\G;
```

## 环境清理
```bash
# 环境清理
docker stop mysql-master
docker stop mysql-mslave
docker stop minio

docker rm -f mysql-master
docker rm -f mysql-mslave
rm -rf /data/mysql
```