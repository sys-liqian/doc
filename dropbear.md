# Dropbear


[下载地址](https://matt.ucc.asn.au/dropbear/releases/)
```bash
yum install zlib* gcc make
tar -xjf dropbear-2024.85.tar.bz2
cd dropbear-2024.85/
./configure
make
make install
mkdir /etc/dropbear
./dropbearkey -t rsa -s 4096 -f /etc/dropbear/dropbear_rsa_host_key
./dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key
./dropbearkey -t ed25519 -f /etc/dropbear/dropbear_ed25519_host_key
mkdir /etc/config
cat <<EOF >/etc/config/dropbear
config dropbear
	option PasswordAuth     'off'
	option RootPasswordAuth 'off'
	option Port             '20023'
EOF
```