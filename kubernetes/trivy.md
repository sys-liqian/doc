# trivy

```bash
# 下载trivy
wget https://github.com/aquasecurity/trivy/releases/download/v0.67.2/trivy_0.67.2_Linux-64bit.tar.gz
tar -zxvf trivy_0.67.2_Linux-64bit.tar.gz
mv trivy /usr/bin

# 下载oras
wget https://github.com/oras-project/oras/releases/download/v1.3.0/oras_1.3.0_linux_amd64.tar.gz
tar -zxvf oras_1.3.0_linux_amd64.tar.gz
mv oras /usr/bin



# 使用trivy在线下载漏洞库
# 漏洞库下载后默认放在 /$USER/.cache/trivy/db 目录下
# 目录地址可以由 --cache-dir指定
trivy image --download-db-only --db-repository ghcr.nju.edu.cn/aquasecurity/trivy-db:2

# 使用trivy在线下载java漏洞库
# 漏洞库下载后默认放在 /$USER/.cache/trivy/java-db 目录下
trivy image --download-java-db-only --java-db-repository ghcr.nju.edu.cn/aquasecurity/trivy-java-db:1

# 使用trivy下载规则扫描库
# trivy没有提供单独下载规则扫描库的命令，这里通过扫描一个文件来下载规则扫描库
# 规则库下载后默认放在 /$USER/.cache/trivy/policy 目录下
trivy fs --scanners=misconfig  --checks-bundle-repository ghcr.nju.edu.cn/aquasecurity/trivy-checks:1 /etc/hosts



# oras 离线下载漏洞库
mkdir /home/earthgod/trivy/db
cd /home/earthgod/trivy/db
oras pull ghcr.nju.edu.cn/aquasecurity/trivy-db:2
tar -zxvf db.tar.gz

# oras 离线下载java漏洞库
mkdir /home/earthgod/trivy/java-db
cd /home/earthgod/trivy/java-db
oras pull  ghcr.nju.edu.cn/aquasecurity/trivy-java-db:1
tar -zxvf java-db.tar.gz

# oras 离线下载规则库
mkdir /home/earthgod/trivy/policy/content
cd /home/earthgod/trivy/policy/content
oras pull  ghcr.nju.edu.cn/aquasecurity/trivy-checks:1
tar -zxvf bundle.tar.gz
```

## 推送漏洞库到nexus

```bash
#  查看制品type
#  oras manifest fetch ghcr.nju.edu.cn/aquasecurity/trivy-checks:1
oras push  registry-dev.xcloud.lenovo.com:18083/aquasecurity/trivy-db:2 \
--artifact-type application/vnd.aquasec.trivy.db.layer.v1.tar+gzip \
./db.tar.gz:application/vnd.aquasec.trivy.db.layer.v1.tar+gzip

oras push  registry-dev.xcloud.lenovo.com:18083/aquasecurity/trivy-java-db:1 \
--artifact-type application/vnd.aquasec.trivy.javadb.layer.v1.tar+gzip \
./javadb.tar.gz:application/vnd.aquasec.trivy.javadb.layer.v1.tar+gzip

oras push  registry-dev.xcloud.lenovo.com:18083/aquasecurity/trivy-checks:1 \
--artifact-type application/vnd.cncf.openpolicyagent.layer.v1.tar+gzip \
./bundle.tar.gz:application/vnd.cncf.openpolicyagent.layer.v1.tar+gzip

oras push  registry-dev.xcloud.lenovo.com:18083/aquasecurity/installer-db:1 \
--artifact-type xcloud.poc.com/db \
./installer.db:xcloud.poc.com/db
```


## 镜像扫描

```bash
# scanners 介绍
# vuln     漏洞扫描
# secret   密码扫描
# misconfig 配置扫描
# license  许可证扫描

# severity 漏洞的严重级别
# CRITICAL
# HIGH
# MEDIUM
# LOW
trivy image \
--scanners vuln,secret,misconfig,license  \
--severity CRITICAL,HIGH  \
registry-public.lenovo.com/lq/syncer:v0.0.1

# 若漏洞数据文件过期
# 可以跳过下载最新漏洞数据文件
trivy \
--insecure \
image \
--scanners vuln,secret,misconfig,license  \
--severity CRITICAL,HIGH  \
--skip-db-update \
--skip-java-db-update \
--skip-check-update \
--username admin \
--password 123456 \
registry-public.lenovo.com/lq/syncer:v0.0.1

## 指定漏洞库地址
trivy \
--insecure \
image \
--scanners vuln,secret,misconfig,license  \
--severity CRITICAL,HIGH  \
--db-repository registry-dev.xcloud.lenovo.com:18083/aquasecurity/trivy-db:2 \
--java-db-repository registry-dev.xcloud.lenovo.com:18083/aquasecurity/trivy-java-db:1 \
--checks-bundle-repository registry-dev.xcloud.lenovo.com:18083/aquasecurity/trivy-checks:1 \
--username admin \
--password admin123 \
registry-dev.xcloud.lenovo.com:18083/earth_system/multikube:v0.0.2
```

## k8s扫描


```bash
# 扫描k8s trivy和集群不在同一台机器上
# 如果有镜像无法获取
# 会导致扫描失败
# 可以添加--skip-images参数,会跳过镜像和secret的扫描
# 如果扫描集群中的images
# 需要trivy所在节点可以访问到镜像仓库，docker login
trivy k8s \
--skip-db-update \
--skip-java-db-update \
--skip-check-update \
--node-collector-imageref registry-dev.xcloud.lenovo.com:18083/aquasecurity/node-collector:0.3.1 \
--include-namespaces kube-system --report summary

# cis 扫描使用node-collector
trivy k8s --compliance=k8s-cis-1.23 --report all  \
--node-collector-imageref registry-dev.xcloud.lenovo.com:18083/aquasecurity/node-collector:0.3.1 \
--debug --skip-db-update --skip-java-db-update --skip-check-update

# csi 扫描自定义规则
# https://github.com/aquasecurity/trivy-checks/blob/31e779916f3863dd74a28cee869ea24fdc4ca8c2/specs/compliance/k8s-cis-1.23.yaml

# --report all 不知为什么没输出
trivy k8s --compliance=@/root/k8s-cis-1.23.yaml --report summary  \
--node-collector-imageref registry-dev.xcloud.lenovo.com:18083/aquasecurity/node-collector:0.3.1 \
--debug --skip-db-update --skip-java-db-update --skip-check-update
```

## trivy server

```bash
# trivy 扫描中只有config，k8s没有server mode
#   config      扫描配置文件
#   filesystem  扫描本地文件系统
#   image       扫描镜像
#   kubernetes  扫描k8s集群
#   repository  扫描git仓库
#   rootfs      扫描rootfs
#   sbom        扫描 SBOM 中漏洞和licenses
#   vm          扫描虚拟机镜像

# 启动server
trivy server \
--skip-db-update \
--listen 0.0.0.0:10000

# client

# filesystem
trivy filesystem --server http://10.122.166.104:10000 /etc

# image
# trivy 以客户端/服务器模式运行
# 但错误配置( misconfiguration )和许可证(license)扫描将在客户端完成

# scanner 添加misconfig需要本地有check db(bundle.tar.gz)
trivy image --server http://10.122.166.104:10000 registry-dev.xcloud.lenovo.com:18083/earth_system/seaweedfs:3.80 \
--username admin --password admin123 \
--scanners vuln,secret,misconfig,license
```

## 源码编译trivy

```bash
cd cmd/trivy
# trivy 使用了jsonv2特性，需要添加编译标签
go build -tags=goexperiment.jsonv2 -o trivy


```
