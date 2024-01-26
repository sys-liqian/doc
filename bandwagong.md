## acme

```bash
docker run --restart always --name acme --network host -v /opt/certs:/acme.sh -m 32MB -d neilpang/acme.sh daemon
# 注册账户(首次运行)
docker exec -it acme acme.sh --register-account -m {email}
# 申请证书（domain更换为域名）
docker exec -it acme acme.sh --issue --standalone -d {domain} -k 2048
```

## filebrowser

```bash
mkdir -p /root/volume/filebrowser
touch /root/volume/filebrowser/filebrowser.db
docker run -d --restart always --name filebrowser -v /root/volume/filebrowser/filebrowser.db:/database.db  -v /media:/srv -p 8088:80 filebrowser/filebrowser:latest
```

## trojan

* 服务端配置 `/root/volume/trojan/config/config.json`
* 配置需要更换密码，和ssl.key中的domian为域名
```json
{
	"run_type":"server",
	"local_addr":"0.0.0.0",
	"local_port":"443",
	"remote_addr":"127.0.0.1",
	"remote_port":"8088",
	"password":["{password}"],
	"log_level":1,
	"ssl":{
		"cert":"/certs/fullchain.cer",
		"key":"/certs/{domain}.key",
		"perfer_server_cipher":true,
		"alpn":["http/1.1"],
		"reuse_session":true
	},
	"mysql":{"enabled":false}

}

```

```bash
# domain 更换为域名
docker run -d --restart always --name trojan --network host -v /root/volume/trojan/config:/config -v /opt/certs/{domain}:/certs -m 128m trojangfw/trojan:latest
```