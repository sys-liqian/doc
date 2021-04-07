##### 开启远程桌面

```
#设置远程桌面端口
reg add "HKLM\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /t REG_DWORD /v portnumber /d 3389 /f

#开启远程桌面
wmic RDTOGGLE WHERE ServerName='%COMPUTERNAME%' call SetAllowTSConnections 1

#检查端口状态
netstat -ano|findstr 3389
```



##### 设置静态IP

```
netsh interface ip set address name="" source=static address=192.168.2.116 mask=255.255.255.0 gateway=192.168.2.1
```



##### 关闭防火墙

```
netsh firewall set opmode disable
```



##### 远程复制文件

```
net use \\192.168.2.177

xcopy \\192.168.2.177\c$\k8swin\* C:\cq  /E /Y /D
```



##### 命令行打开管理员powershell

```
runas /noprofile /user:Administrator cmd
```

