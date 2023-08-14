# restic 使用手册

## 下载
[Github Release](https://github.com/restic/restic/releases)

```bash
wget https://github.com/restic/restic/releases/download/v0.16.0/restic_0.16.0_linux_amd64.bz2
bzip2 -d restic_0.16.0_linux_amd64.bz2 
mv restic_0.16.0_linux_amd64 restic
chmod +x restic
mv restic /usr/local/bin/
```

## 初始化本地仓库
```bash
# 输入仓库密码
restic -r /home/earthgod/restic/repo/ init
```

## 初始化远程仓库(S3)
```bash
export AWS_ACCESS_KEY_ID=xxx
export AWS_SECRET_ACCESS_KEY=xxx
export RESTIC_PASSWORD=123456
export RESTIC_REPOSITORY=s3:https://s3.com/velero/restic/tst
restic init
```


# 备份
```bash
# 备份testdata目录中的数据到repo
restic -r /home/earthgod/restic/repo/ backup testdata
```