# kubelet

kubelet 修改nodeip 以及默认data目录
```bash
vim /etc/sysconfig/kubelet
KUBELET_EXTRA_ARGS='--node-ip 172.25.16.3 --root-dir=/data/kubelet'
```

