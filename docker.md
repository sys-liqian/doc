## Docker 安装

1. 查看当前是否已安装Docker
```bash
rpm -aq | grep docker
```

2. 安装Docker源
```bash
curl -o /etc/yum.repos.d/docker-ce.repo  https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo?spm=a2c6h.25603864.0.0.29d84ca5jvb9YX
```

3. 查看可用Docker版本
```bash
yum list docker-ce --showduplicates |sort -r
```

4. 安装
```bash
yum install docker-ce-19.03.15-3.el7.x86_64
```

5. 配置文件
```bash
mkdir /etc/docker
cat >/etc/docker/daemon.json <<EOF
{
  "registry-mirrors":["https://registry.docker-cn.com","https://docker.mirrors.ustc.edu.cn"],
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
```

6. 重启并配置开机自启
```bash
systemctl restart docker
systemctl enable docker
```

7. 卸载
```bash
yum remove docker-ce-19.03.15-3.el7.x86_64
```

## Docker 清理

若创建容器时报错如下,则Docker磁盘空间不足
```log
Failed to create pod sandbox: rpc error: code = Unknown desc = failed to create a sandbox for pod "csi-node-5n8tg": Error response from daemon: devmapper: Thin Pool has 53522 free data blocks which is less than minimum required 163840 free data blocks. Create more free space in thin pool or use dm.min_free_space option to change behavior
```

```bash
#查看Docker详情
docker info
```

清理
```bash
#删除关闭的容器
docker ps -a | grep Exit | cut -d ' ' -f 1 | xargs docker rm
#删除没有Tag的镜像
docker rmi $(docker images | grep "^<none>" | awk "{print $3}")
#删除dangling Volume
docker volume rm $(docker volume ls -qf dangling=true)
#或者使用以下命令清理，将删除当前不在运行的所有镜像容器网络volume
docker system prune
```

## 国内代理
```json
{
  "registry-mirrors":["https://registry.docker-cn.com","https://docker.mirrors.ustc.edu.cn","https://ustc-edu-cn.mirror.aliyuncs.com","https://qbd2mtyh.mirror.aliyuncs.com","https://docker.registry.cyou","https://docker-cf.registry.cyou","https://dockercf.jsdelivr.fyi","https://docker.jsdelivr.fyi","https://dockertest.jsdelivr.fyi","https://mirror.aliyuncs.com","https://dockerproxy.com","https://mirror.baidubce.com","https://docker.m.daocloud.io","https://docker.nju.edu.cn","https://docker.mirrors.sjtug.sjtu.edu.cn","https://docker.mirrors.ustc.edu.cn","https://mirror.iscas.ac.cn","https://dockerhub.icu","https://docker.rainbond.cc"],
  "insecure-registries":[],
  "data-root": "/data/docker"
}
```

