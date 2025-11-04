# Dropbear


[下载地址](https://matt.ucc.asn.au/dropbear/releases/)
```bash
# Version Dropbear v2017.75
yum install zlib* gcc make bzip2
tar -xjf dropbear-2024.85.tar.bz2
cd dropbear-2017.75/
./configure
make
make install
mkdir /etc/dropbear
./dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
./dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key
./dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key
cp /usr/local/sbin/dropbear /usr/sbin/

cat <<EOF >/usr/lib/systemd/system/dropbear.service
# /usr/lib/systemd/system/dropbear.service
[Unit]
Description=Dropbear SSH Server Daemon
Documentation=man:dropbear(8)
After=network.target

[Service]
EnvironmentFile=-/etc/sysconfig/dropbear
ExecStart=/usr/sbin/dropbear -E -F -p 2222

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start dropbear
```
