#!/bin/bash

install_brctl() {
  if ! [ -x "$(command -v brctl)" ]; then
	yum install -y bridge-utils
  else
    echo 'brctl has been installed.'
  fi
}

start_test_env(){
	#1.安装brctl
	install_brctl
	
	#2.创建网桥
	brctl addbr bridge01
	
	#3.启动网桥
	ip link set dev bridge01 up
	
	#4.为网桥分配IP
	ifconfig bridge01 192.168.2.1/24 up
	
	#5.创建两个net namespace
	ip netns add netns01
	ip netns add netns02
	
	#使用 ip netns list 可以查看所有的netns
	
	#6.创建两对veth
	ip link add veth01 type veth peer name bridge-veth01
	ip link add veth02 type veth peer name bridge-veth02
	
	#7.将veth一端挂到默认net namespace的bridge01上
	brctl addif bridge01 bridge-veth01
	brctl addif bridge01 bridge-veth02
	
	#使用brctl show可以查看网桥下面挂的veth
	
	#8.启动这两个veth
	ip link set dev bridge-veth01 up
	ip link set dev bridge-veth02 up
	
	#9.veth 对端分别绑定到netns01和netns02
	ip link set veth01 netns netns01
	ip link set veth02 netns netns02
	
	# ip netns exec [ns] [command]可以再特定的net namespace 执行命令
	# 查看命名空间中的网络设备
	# ip netns exec netns01 ip a
	
	#10.为netns01和netns02中的veth设备设置ip和默认路由，网关地址为bridge01的ip
	ip netns exec netns01 ip link set dev veth01 up
	ip netns exec netns01 ifconfig veth01 192.168.2.11/24 up
	ip netns exec netns01 ip route add default via 192.168.2.1
	
	ip netns exec netns02 ip link set dev veth02 up
	ip netns exec netns02 ifconfig veth02 192.168.2.22/24 up
	ip netns exec netns02 ip route add default via 192.168.2.1
	
	#开始测试
	
	#1. 从netns01 ping netns02的ip,同时在宿主机用tcpdump在bridge01上抓包,在netns02在veth02上抓包
	# ip netns exec netns01 ping 192.168.2.22 -c 1
	
	# 新bash执行 tcpdump -i bridge01 -nn
	
	#16:59:48.823308 ARP, Request who-has 192.168.2.22 tell 192.168.2.11, length 28
	#16:59:48.823324 ARP, Reply 192.168.2.22 is-at da:85:3c:7c:bb:fb, length 28
	#16:59:48.823349 IP 192.168.2.11 > 192.168.2.22: ICMP echo request, id 56111, seq 1, length 64
	#16:59:48.823361 IP 192.168.2.22 > 192.168.2.11: ICMP echo reply, id 56111, seq 1, length 64
	#16:59:54.096095 ARP, Request who-has 192.168.2.11 tell 192.168.2.22, length 28
	#16:59:54.096103 ARP, Reply 192.168.2.11 is-at 62:66:50:1d:d9:6a, length 28
	
	# 新bash执行 ip netns exec netns02 tcpdump -i veth02 -nn
	
	#16:59:48.823314 ARP, Request who-has 192.168.2.22 tell 192.168.2.11, length 28
	#16:59:48.823322 ARP, Reply 192.168.2.22 is-at da:85:3c:7c:bb:fb, length 28
	#16:59:48.823350 IP 192.168.2.11 > 192.168.2.22: ICMP echo request, id 56111, seq 1, length 64
	#16:59:48.823358 IP 192.168.2.22 > 192.168.2.11: ICMP echo reply, id 56111, seq 1, length 64
	#16:59:54.096061 ARP, Request who-has 192.168.2.11 tell 192.168.2.22, length 28
	#16:59:54.096103 ARP, Reply 192.168.2.11 is-at 62:66:50:1d:d9:6a, length 28
	
	#2. 可以在netns01中查看arp列表验证mac地址是否正确
	# ip netns exec netns01 arp
	
	#_gateway (192.168.2.1) at 02:dd:a8:60:ee:ca [ether] on veth01
    #? (192.168.2.22) at da:85:3c:7c:bb:fb [ether] on veth01
	
	#3. 在netns中ping外网ping不通，原因是源地址是私有地址，
	#   发回来的包目的地址是私有地址的话会被丢弃,做一下源 nat
	# ip netns exec netns01 ping 114.114.114.114
	
	iptables -t nat -A POSTROUTING -s 192.168.2.0/24 -j MASQUERADE
}

clear_test_env(){
	ip netns del netns01
	ip netns del netns02
	ifconfig bridge01 down
	brctl delbr bridge01
	iptables -t nat -D POSTROUTING -s 192.168.2.0/24 -j MASQUERADE
}


main(){
	start_test_env
	#clear_test_env
}

main