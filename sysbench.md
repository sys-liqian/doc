# sysbench 使用

[项目地址](https://github.com/akopytov/sysbench)

测试所需的lua脚本在release tests文件夹中,不在master中

如果压测数据库报错
```
FATAL: Connection to database failed: SCRAM authentication requires libpq version 10 or above
```
解决办法
```bash
# 下载该项目https://gitee.com/xiaohai008/postgresql10-devel
yum install -y libicu libicu-devel
unzip postgresql10-devel-master.zip 
rpm -ivh postgresql10-devel-master/*
```

## 压测mysql

* 准备数据
```bash
sysbench ./tests/include/oltp_legacy/oltp.lua --mysql-host=10.119.104.16 --mysql-port=3306 --mysql-user=root --mysql-password=123456 --oltp-test-mode=complex --oltp-tables-count=10 --oltp-table-size=100000 --threads=10 --time=120 --report-interval=10 prepare
```

* 压测
```bash
sysbench ./tests/include/oltp_legacy/oltp.lua --mysql-host=10.119.104.16 --mysql-port=3306 --mysql-user=root --mysql-password=123456 --oltp-test-mode=complex --oltp-tables-count=10 --oltp-table-size=100000 --threads=10 --time=120 --report-interval=10 run
```

* 清理
```bash
sysbench ./tests/include/oltp_legacy/oltp.lua --mysql-host=10.119.104.16 --mysql-port=3306 --mysql-user=root --mysql-password=123456 --oltp-tables-count=10 cleanup
``` 

## 压测postgres

* 准备数据
```bash
sysbench ./tests/include/oltp_legacy/oltp.lua --db-driver=pgsql --pgsql-host=10.122.195.109 --pgsql-port=5432 --pgsql-user=postgres --pgsql-password=123456 --pgsql-db=postgres --oltp-test-mode=complex --oltp-tables-count=10 --oltp-table-size=100000 --threads=10 --time=120 --report-interval=10 prepare
```

* 压测
```bash
sysbench ./tests/include/oltp_legacy/oltp.lua --db-driver=pgsql --pgsql-host=10.122.195.109 --pgsql-port=5432 --pgsql-user=postgres --pgsql-password=123456 --pgsql-db=postgres --oltp-test-mode=complex --oltp-tables-count=10 --oltp-table-size=100000 --threads=10 --time=120 --report-interval=10 run
```

* 清理
```bash
sysbench ./tests/include/oltp_legacy/oltp.lua --db-driver=pgsql --pgsql-host=10.122.195.109 --pgsql-port=5432 --pgsql-user=postgres --pgsql-password=123456 --pgsql-db=postgres --oltp-tables-count=10 cleanup
```

## 压测IO

参数介绍
```
–file-num 生成测试文件的数量，默认是128
–file-block-size 测试期间文件块的大小,默认16384,16k
–file-total-size 所有文件总的大小，默认是2GB
–file-test-mode 文件测试模式，包含seqwr（顺序写）、seqrewr（顺序读写）、seqrd（顺序读）、rndr d（随即读）、rndwr（随机写）、rndrw（随机读写）
–file-io-mode 文件操作模式，同步还是异步，默认是同步
--file-extra-flags  sync,dsync,direct  direct绕过文件系统缓存，直接io
```

* 准备数据
```bash
sysbench fileio --file-total-size=2G --file-test-mode=rndrw --time=180 --events=100000000 --threads=16  --file-num=16 --file-extra-flags=direct --file-fsync-freq=0 --file-block-size=16384 prepare
```

* 测试
```bash
sysbench fileio --file-total-size=2G --file-test-mode=rndrw --time=180 --events=100000000 --threads=16  --file-num=16 --file-extra-flags=direct --file-fsync-freq=0 --file-block-size=16384 run
```