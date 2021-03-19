## harbor搭建

##### 安装最新的docker-compose

```
weget https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
```

项目git地址:

```
https://github.com/docker/compose/
```

##### 给docker-compose添加执行权限

```
chmod +x /usr/local/bin/docker-compose
```

##### 获取harbor

```
weget https://github.com/goharbor/harbor/releases/download/v2.1.4/harbor-offline-installer-v2.1.4.tgz
```

项目git地址

```
https://github.com/goharbor/harbor
```

##### 解压

```
tar -xf harbor-offline-installer-v1.7.1.tgz -C /{your_install_path}
```

##### 修改配置文件

配置文件路径地址: {your_install_path}/harbor/harbor.yml

项目结构如图

```
drwxr-xr-x 3 root root      4096 3月  18 17:28 ./
drwxr-xr-x 7 root root      4096 3月  18 14:03 ../
drwxr-xr-x 3 root root      4096 3月  18 17:28 common/
-rw-r--r-- 1 root root      3361 3月  15 17:27 common.sh
-rw-r--r-- 1 root root      8568 3月  18 17:28 docker-compose.yml
-rw-r--r-- 1 root root 564438538 3月  15 17:27 harbor.v2.1.4.tar.gz
-rw-r--r-- 1 root root      8138 3月  18 17:26 harbor.yml
-rw-r--r-- 1 root root      8136 3月  15 17:27 harbor.yml.tmpl
-rwxr-xr-x 1 root root      2523 3月  15 17:27 install.sh*
-rw-r--r-- 1 root root     11347 3月  15 17:27 LICENSE
-rwxr-xr-x 1 root root      1881 3月  15 17:27 prepare*

```

- 修改配置文件中的hostname 为主机ip

- 更改http绑定端口

- 注释掉https相关

- 修改admin用户密码 harbor_admin_password

##### 初始化配置文件

在{your_install_path}/harbor目录下执行

```
sudo ./prepare
```

##### 安装harbor

在{your_install_path}/harbor目录下执行

```
sudo ./install.sh
```

安装时需要下载镜像,失败了重安

##### harbor的开启停止与重启

在{your_install_path}/harbor目录下执行

```
docker-compose start
docker-compose stop
docker-compose restart
```

##### 修改harbor配置,并重启

```
 sudo docker-compose down -v 
 //修改harbor.yml
 sudo ./prepare
 sudo docker-compose up -d
```



