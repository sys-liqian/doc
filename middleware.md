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

