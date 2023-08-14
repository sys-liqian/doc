# Centos7 安装python3

* 安装必要库
```bash
yum install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc make
```
* 下载python3源码
```bash
wget http://npm.taobao.org/mirrors/python/3.6.4/Python-3.6.4.tar.xz
```
* 解压
```bash
xz -d Python-3.6.4.tar.xz
tar -xf Python-3.6.4.tar
```
* 编译源码
```bash
cd Python-3.6.4
./configure  prefix=/usr/local/python3
make && make install
```
* 备份源python软链
```bash
mv /usr/local/bin/python /usr/local/bin/python.bak
```
* 创建新的软链指向python3
```bash
ln -s /usr/local/python3/bin/python3.6 /usr/bin/python
```
* 验证python版本
```bash
python -V
```
* yum需要python2执行，修改yum相关配置
```bash
vim /usr/bin/yum
把#! /usr/bin/python修改为#! /usr/bin/python2 
vim /usr/libexec/urlgrabber-ext-down
把#! /usr/bin/python 修改为#! /usr/bin/python2
```
* 安装pip3，python3自带pip3,添加软链
```bash
ln -s /usr/local/python3/bin/pip3 /usr/bin/pip3
```
* pip3升级
```bash
pip3 install --upgrade pip
```