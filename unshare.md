# unshare

```bash
unshare --ipc --uts --net  --mount --root /home/unshare_test/ubuntu --pid --mount-proc --fork bash
```

如果unshare 版本过低没有 --root参数,需要安装最新版本的util-linux
[Github](https://github.com/util-linux/util-linux)

当前本机为centos系统,可以使用docker run 一个ubuntu容器

使用 docker export -o ubuntu.tar {容器id}

解压 ubuntu.tar, unshare --root 指向解压目录