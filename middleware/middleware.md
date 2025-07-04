# Middleware

## Mysql

### Docker

#### Server
```bash
docker run -d --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root mysql:5.7
```

#### Client
```bash
docker run --rm --net host -it dbcliorg/mycli:mycli-1.25.0 -h 127.0.0.1 -P 3306  mysql -u root -p "root"
```

## Postgres

### Docker

#### Server
```bash
docker run -d --name postgres -e POSTGRES_USER=root -e POSTGRES_DB=database -e POSTGRES_PASSWORD=root -p 5432:5432 postgres:14
```

## Zookeeper

### Docker

#### Server
```bash
docker run -d --name zk -p 2181:2181 zookeeper:3.8.1
```

#### Client
```bash
docker run -it --rm --network kind -e HTTP_PORT=9000 -p 9000:9000  elkozmon/zoonavigator:latest
```

## Kafka

### Docker

#### Client
```bash
docker run -it --rm --network kind -e KAFKA_CLUSTERS_0_NAME=kafka-single -e KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=172.19.0.2:30008 -p 9090:8080 provectuslabs/kafka-ui:latest
```

## Registry

### Docker

```bash
docker run --restart always --network kind --name registry --tmpfs /var/lib/registry -p 0.0.0.0:5000:5000 -d registry:2
```

## Minio

### Dcoker

```bash
docker run --name minio -d -p 9000:9000 -p 9090:9090 -d -e "MINIO_ACCESS_KEY=minioadmin" -e "MINIO_SECRET_KEY=minioadmin" -v /data/minio/data:/data -v /data/minio/config:/root/.minio minio/minio:latest server /data --console-address ":9090" -address ":9000"
```

## Nacos

### Docker

```bash
# http://localhost:18080/nacos username: nacos password: nacos
docker run --name nacos-server \
-p 18080:8080 -p 8848:8848 -p 9848:9848 \
-e MODE=standalone \
-e NACOS_AUTH_TOKEN="aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789+ab/cdefg==" \
-e NACOS_AUTH_IDENTITY_KEY="serverIdentity" \
-e NACOS_AUTH_IDENTITY_VALUE="a3F5gH9kLm2pO8sD1qW0eR7tY4uI6zXc" \
-d nacos/nacos-server:v3.0.1
```
