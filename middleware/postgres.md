

```sql
--- dev 机器启动客户端
docker run --rm -it --network host 86d47da89a09 bash

psql -h 10.122.196.159 -p 35432 -U postgres -d postgres

--- 创建用户
CREATE USER test WITH PASSWORD 'SecurePass123!';

-- 创建数据库并指定所有者
CREATE DATABASE test OWNER test;

-- 连接到新创建的数据库以授予模式权限
\c test

-- 授予 public 模式的相关权限
GRANT ALL ON SCHEMA public TO test;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO test;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO test;

psql -h 10.122.196.159 -p 35432 -U test -d test

--- 创建表
CREATE TABLE test(id serial primary key,name varchar(50));

--- 如果使用postgres 创建了table，test用户无法访问，需要修改表的所有者
ALTER TABLE test OWNER TO test;

--- 查看database列表
\l

--- 查看table列表
\dt 

--- 查看最大连接数
SHOW max_connections;

--- 当前连接总数
SELECT COUNT(*) FROM pg_stat_activity;

--- 按用户查看连接数
SELECT usename, COUNT(*) FROM pg_stat_activity GROUP BY usename;

--- 查看为超级用户保留的连接数
SHOW superuser_reserved_connections;

--- 查看每个用户的最大连接数限制 -1，表示不限制
SELECT rolname, rolconnlimit FROM pg_authid;

--- 设置用户最大连接数
ALTER ROLE {username} CONNECTION LIMIT 10;

--- 剩余可用连接
SELECT (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') - COUNT(*) AS available_connections
FROM pg_stat_activity;

--- 刷新hba
SELECT pg_reload_conf();

--- 查看hba
SELECT * FROM pg_hba_file_rules();
```


sysbench 压测

```bash
sysbench ./tests/include/oltp_legacy/oltp.lua \
--db-driver=pgsql --pgsql-host=10.122.196.159 \
--pgsql-port=35432 --pgsql-user=test --pgsql-password=SecurePass123! \
--pgsql-db=test --oltp-test-mode=complex --oltp-tables-count=10 --oltp-table-size=100000 --threads=10 --time=120 --report-interval=10 prepare


sysbench ./tests/include/oltp_legacy/oltp.lua \
--db-driver=pgsql --pgsql-host=10.122.196.159 \
--pgsql-port=35432 --pgsql-user=test --pgsql-password=SecurePass123! \
--pgsql-db=test --oltp-test-mode=complex --oltp-tables-count=10 --oltp-table-size=100000 --threads=10 --time=120 --report-interval=10 run
```


```
docker run --rm -it registry-dev.xcloud.lenovo.com:18083/earth_system/redis:6.2.20 bash
redis-cli -h 10.122.195.109 -p 51241
kubectl get emm -n project-middleware-3089  redis-390 
```