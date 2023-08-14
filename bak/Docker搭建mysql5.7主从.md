#### 本次搭建环境

##### Docker 18.06,1-ce

##### Centos7 



##### 1.拉取mysql5.7镜像

```
docker pull mysql:5.7
```



##### 2.开启主从需要开启二进制日志,默认没有开启,所以需要创建mysql配置文件my.conf挂载到容器

##### my.conf内容如下,从节点配置只需要更改server-id

```
 [mysqld]
 server-id = 1                              # 确保在整个Mysql集群中唯一
 log-bin = /var/log/mysql/mysql-bin.log     # 日志存放位置 
 log-bin-index = binlog.index
 
#[Err]1055 - Expression #1 of ORDER BY clause is not in GROUP BY clause and contains     #nonaggregated column ‘information_schema.PROFILING.SEQ’ which is not functionally  #dependent on columns in GROUP BY clause; this is incompatible with  #sql_mode=only_full_group_by

# 出现上述错误,需要修改sql_mode
 sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES 
```



##### 3.运行主节点

```
docker run -d -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root -v /home/mysql/mastar-data:/var/lib/mysql -v /home/mysql/master-conf/my.cnf:/etc/mysql/my.cnf --name mysql-master 2c9028880e58
```

-d 后台运行

-p 端口映射   主机端口:容器端口

-e 设置环境变量,myql5.7初始化必须指定登录密码

-v 主机路径:容器路径,mysql5.7默认存储位置/var/lib/mysql

--name 指定容器名称



##### 4.进入master容器内,并且登录容器中的mysql

```
docker exec -it {容器id} /bin/bash

mysql -u root -p
```



##### 5.查看主节点信息

```
show master status;
```

##### 显示如下:

![image-20210604235738279](https://github.com/sys-liqian/doc/blob/main/image-storage/image-20210604235738279.png)

##### 记录 File 字段的值,稍后从节点连接主节点需要指定该日志



##### 6.运行从节点

```
docker run -d -p 3307:3306 -e MYSQL_ROOT_PASSWORD=root -v /home/mysql/slave-data:/var/lib/mysql -v /home/mysql/slave-conf/my.cnf:/etc/mysql/my.cnf --name mysql-slave 2c9028880e58
```

##### 和mater节点类似,进入slave容器内部,并且登录mysql

##### 执行如下命令连接master,并且开启slave模式

```
CHANGE MASTER TO MASTER_HOST='172.21.0.2',MASTER_USER='root',MASTER_PASSWORD='root',MASTER_LOG_FILE='mysql-bin.000001',MASTER_LOG_POS=0;

start slave; 
```

MASTER_HOST 			主节点IP

MASTER_USER			  主节点用户名

MASTER_PASSWORD   主节点密码

MASTER_LOG_FILE		主节点bin-log名

MASTER_LOG_POS 	    开始游标,mysql会自动匹配



##### 7.查看slave状态

```
 show slave status\G;
```

##### 如下图则创建关联成功

![image-20210605000943511](https://github.com/sys-liqian/doc/blob/main/image-storage/image-20210605000943511.png)



