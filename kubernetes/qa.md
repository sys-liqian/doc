# 常见问题

## coredns 无法启动

```bash
[root@k8s ~]# kubectl logs -n kube-system  coredns-6ddff5bd6d-b2jr9
Listen: listen tcp :53: bind: permission denied
```

原因openeuler自带docker version 过低
```bash
[root@k8s ~]# cat /etc/os-release 
NAME="openEuler"
VERSION="22.03 (LTS-SP4)"
ID="openEuler"
VERSION_ID="22.03"
PRETTY_NAME="openEuler 22.03 (LTS-SP4)"
ANSI_COLOR="0;31"

[root@k8s ~]# docker version
Client:
 Version:           18.09.0
 EulerVersion:      18.09.0.345
 API version:       1.39
 Go version:        go1.17.3
 Git commit:        d51e3ad
 Built:             Wed Dec 11 15:36:49 2024
 OS/Arch:           linux/amd64
 Experimental:      false

Server:
 Engine:
  Version:          18.09.0
  EulerVersion:     18.09.0.345
  API version:      1.39 (minimum version 1.12)
  Go version:       go1.17.3
  Git commit:       d51e3ad
  Built:            Wed Dec 11 15:36:13 2024
  OS/Arch:          linux/amd64
  Experimental:     false
```

解决办法
```bash
dnf config-manager --add-repo=https://repo.huaweicloud.com/docker-ce/linux/centos/docker-ce.repo
sed -i 's+download.docker.com+repo.huaweicloud.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo 
sed -i 's+\$releasever+8+' /etc/yum.repos.d/docker-ce.repo 
yum install docker-ce docker-ce-cli
docker version
systemctl restart docker
```

## volcano-agent 报错
```bash
E0506 16:34:09.563868       1 resource_usage_getter.go:113] "Failed to collector cpu metric" err="open /host/sys/fs/cgroup/memory/kubepods/memory.stat: no such file or directory" resType="memory"
E0506 16:34:09.760496       1 resource_usage_getter.go:113] "Failed to collector cpu metric" err="open /host/sys/fs/cgroup/cpu/kubepods/cpuacct.usage: no such file or directory" resType="cpu"
```

解决办法
```bash
# volcano 1.11.2 agent当前仅支持 openeuler cgroup v1
# /var/lib/kubelet/config.yaml 中修改cgroupDriver为cgroupfs

# docker info
# dodcker 使用 cgroupfs

# 重新部署volcano

# volcano agent 配置
kubectl get cm -n volcano-system volcano-agent-configuration -o yaml
```