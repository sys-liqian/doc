# Linux安装信任自签证书

## Debain/Ubuntu
```bash
sudo cp root_ca.crt /usr/local/share/ca-certificates/root_ca.crt
# update-ca-certificates 会添加 /etc/ca-certificates.conf 配置文件中指定的证书
# 另外所有 /usr/local/share/ca-certificates/*.crt 会被列为隐式信任
sudo update-ca-certificates

# - 删除
sudo rm /usr/local/share/ca-certificates/root_ca.crt
sudo update-ca-certificates --fresh
```

## Centos/Fedora/RHEL
```bash
yum install ca-certificates
# 启用动态 CA 配置功能：
update-ca-trust force-enable
cp root_ca.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust
```

## Alpine
```bash
apk update && apk add --no-cache ca-certificates
cp root_ca.crt /usr/local/share/ca-certificates/
update-ca-certificates
```