
## ElasticSearch Kibana
```yaml
version: '2'
services:
  elasticsearch:
    image: elasticsearch:7.13.3
    container_name: elasticsearch
    privileged: true
    environment:
      - "cluster.name=elasticsearch" #设置集群名称为elasticsearch
      - "discovery.type=single-node" #以单一节点模式启动
      - "ES_JAVA_OPTS=-Xms512m -Xmx1096m" #设置使用jvm内存大小
      - bootstrap.memory_lock=true
    volumes:
      - ./es/plugins:/usr/share/elasticsearch/plugins #插件文件挂载
      - ./es/data:/usr/share/elasticsearch/data:rw #数据文件挂载
      - ./es/logs:/user/share/elasticsearch/logs:rw
    ports:
      - 9200:9200
      - 9300:9300
    deploy:
      resources:
        limits:
          cpus: "2"
          memory: 1000M
        reservations:
          memory: 200M
  kibana:
    image: kibana:7.13.3
    container_name: kibana
    depends_on:
      - elasticsearch #kibana在elasticsearch启动之后再启动
    environment:
      ELASTICSEARCH_HOSTS: http://elasticsearch:9200 #设置访问elasticsearch的地址
      I18N_LOCALE: zh-CN
    ports:
      - 5601:5601
```

## Kafka Kafka-Manger
```yaml
version: '2'
services:
  zookeeper:
    image: wurstmeister/zookeeper
    volumes:
      - /opt/zookeeper/data:/data
    container_name: zookeeper
    mem_limit: 512M
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    ports:
      - 2181:2181
    restart: always
  kafka_node1:
    image: wurstmeister/kafka
    container_name: kafka_node1
    mem_limit: 512M
    depends_on:
      - zookeeper
    ports:
      - 9092:9092
    volumes:
      - /opt/kafka/data:/kafka
    environment:
      KAFKA_CREATE_TOPICS: "test"
      KAFKA_BROKER_NO: 0
      KAFKA_LISTENERS: PLAINTEXT://kafka_node1:9092
      #KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://${kafka_service_public_ip}:${kafka_service_public_port}
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_HEAP_OPTS: "-Xmx512M -Xms16M"
    restart: always
  kafka_manager:
    image: hlebalbau/kafka-manager
    ports:
      - 9000:9000
    environment:
      ZK_HOSTS: "zookeeper:2181"
    depends_on:
      - zookeeper
      - kafka_node1
    restart: always
```

## Prometheus Alter-Manger Node-Exporter Push-Gateway Grafana

* /home/workspace/prometheus/altermanager.yaml
```yaml
#alertmanager 配置文件
global:
  smtp_smarthost: 'smtp.163.com:25' #163邮箱smtp地址
  smtp_from: 'xxxx@163.com' #发送者邮箱账号
  smtp_auth_username: 'xxxx@163.com' #发送者邮箱账号
  smtp_auth_password: 'XXXX' #smtp密码
  smtp_require_tls: false   #tls要设置后才能发送成功，默认是true

route:
  group_interval: 1m   #一组已发送初始通知的告警接收到新告警后，再次发送通知前等待的时间（一般设置为5分钟或更多）
  repeat_interval: 1m  #一条成功发送的告警，在再次发送通知之前等待的时间。 （通常设置为3小时或更长时间）
  receiver: 'mail-receiver' #对应receivers中的接收者

receivers:
  - name: 'mail-receiver'
    email_configs:
      - to: 'xxxx@163.com' #告警邮件接收着
```

* /home/workspace/prometheus/prometheus.yaml
```yaml
# prometheus配置文件
#全局配置
global:
  scrape_interval: 15s # 抓取时间间隔，默认1分钟
  evaluation_interval: 15s # 规则评估时间间隔，默认一分钟
  # scrape_timeout is set to the global default (10s).
# alert manager配置
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - 172.25.16.5:9093 #alertmanager ip:端口
rule_files:
  - "rules/*" # prometheus规则文件路径，这里取相对目录rules下的所有文件

# 抓取配置
scrape_configs:
  - job_name: "prometheus"
    # 配置node-exporter地址，我这里配置的是node-problem-detector地址
    static_configs:
      - targets: ["172.25.16.2:20257"]
      - targets: ["172.25.16.3:20257"]
  - job_name: "pushgateway"
    scrape_interval: 5s
    static_configs:
      - targets: ["172.25.16.5:9091"]
    #honor_labels: true
```
* home/workspace/prometheus/rules/rules.yaml
```yaml
groups:
  - name: cpu_load_5m
    rules:
      - alert: cpu_load_5m #指标名
        expr: cpu_load_5m{instance="172.25.16.2:20257", job="prometheus"} > 1 #告警表达式
        for: 0s #只要表达式成立触发一次就告警
        labels:
          severity: warning #告警级别
        annotations:
          description: '{{$labels.instance}}: cpu_load_5m (current value is:{{ $value }})'
          summary: '{{$labels.instance}}: cpu_load_5m '
```


```yaml
version: '2'
services:
  prometheus:
    image: "prom/prometheus"
    hostname: prometheus
    container_name: prometheus
    networks:
      - mynetwork
    ports:
      - '9090:9090'
    volumes:
      - /home/workspace/prometheus:/etc/prometheus #prometheus 配置文件所在路径映射到容器内
    restart: always
  node-exporter:
    image: "prom/node-exporter"
    hostname: node-exporter
    container_name: node-exporter
    ports:
      - '9100:9100'
    volumes:
      - /usr/share/zoneinfo/Asia/Shanghai:/etc/localtime:ro
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    restart: always
    network_mode: host
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'
  grafana:
    image: "grafana/grafana"
    hostname: grafana
    container_name: grafana
    networks:
      - mynetwork
    ports:
      - '3000:3000'
    restart: always
  alertmanager:
    image: "prom/alertmanager"
    hostname: alertmanager
    container_name: alertmanager
    networks:
      - mynetwork
    ports:
      - '9093:9093'
    volumes:
      - /home/workspace/prometheus:/etc/alertmanager #alertmanager 配置文件所在路径映射到容器内
    restart: always
  pushgateway:
    image: "prom/pushgateway"
    hostname: pushgateway
    container_name: pushgateway
    networks:
      - mynetwork
    ports:
      - '9091:9091'
    restart: always
networks:
  mynetwork:
```

##