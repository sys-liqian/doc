[TOC]



## 1. 计算机网络

### 1.1 TCP的三次握手

![image-20210203171632918](https://github.com/buddhistSystem/doc/blob/main/image-storage/image-20210203171632918.png)

**第一次握手**：建立连接时，客户端发送SYN包到服务器，之后客户端进入**SYN_SEND**状态，等待服务端确认

**第二次握手**：服务端收到客户端发送的SYN包，必须确认客户端的SYN包，同时自己也向客户端发送SYN包，

​					   即服务端发送SYN+ACK包，发送之后服务端进入**SYN_RECV**状态

**第三次握手**：客户端收到服务器的SYN+ACK包之后，向服务端发送确认包，此包发送完毕后，客户端服务端都

​					   进入**ESTAB_LISHED**状态，此时客户端服务端可以进行传输数据，完成三次握手



### 1.2 TCP握手存在的隐患

TCP在首次握手存在的隐患为：**SYN超时**

Server收到Client的SYN包之后，回复SYN-ACK之后确一直收不到Client的ACK确认，即没有完成三次握手

发生上述情况后，Server会不断重试，Linux默认重试5次等待63秒后断开TCP连接

这种情况可能造成**SYN-Flood攻击**，SYN-Flood攻击是一种典型的**Dos**（拒绝服务攻击），恶意程序持续向Server发送SYN包却不响应ACK，直到把SYN队列耗尽

**解决方案**：SYN队列被耗尽之后，通过tcp-syncookies参数发送SYN Cookie，若为正常连接的Client会发送SYN Cookie，建立连接



### 1.3 TCP的四次挥手

![image-20210203180049728](https://github.com/buddhistSystem/doc/blob/main/image-storage/image-20210203180049728.png)

**第一次挥手**：Client向Server发送一个FIN包，关闭Client到Server的数据传输，发送后Client进入**FIN_WAIT_1**状					   态

**第二次挥手**：Server收到Client的FIN包，发送一个ACK确认给Clinet，Server进入**CLOSE_WAIT**状态

**第三次挥手**：Server向Client发送FIN包，关闭Server到Client的数据传输，发送后Server进入**LAST_ACK**状态

**第四次挥手**：Client收到FIN包后，Client进入**TIME_WAIT**状态，接着发送一个ACK给Server，Server收到ACK之后

​						直接进入**CLOSED**状态，Client需要等待**2MSL**之后进入CLOSED状态



### 1.4 为什么TCP需要四次挥手才能断开连接

因为TCP是**全双工**，发送方和接收方都需要发送FIN报文和ACK报文



### 1.5 为什么TCP四次挥手会有TIME_WAIT状态

1. 确保最后一个确认报文能够到达（如果server没收到client发送来的确认报文，那么就会重新发送连接释放请求报文，client等待一段时间就是为了处理这种情况的发生）

2. 避免新旧链接混淆（等待2MSL可以让本连接持续时间内所产生的所有报文都从网络中消失，使得下一个新的连接请求不会出现旧的连接请求报文）

   

### 1.6 TCP和UDP的区别

1. TCP面向连接，UDP面向非连接
2. TCP具有可靠性
3. TCP具有有序性
4. UDP传输速度快
5. TCP重量级，TCP头20字节，UDP8字节



### 1.7 TCP的滑动窗口

![image-20210203181828870](https://github.com/buddhistSystem/doc/blob/main/image-storage/image-20210203181828870.png)

TCP 接收方缓存内有三种状态

- 已接收并且发送了ACK确认状态
- 未接收，但是可以接收状态（称为接收窗口）
- 未接收状态

TCP传输的可靠性来自**确认重传**，TCP滑动窗口的可靠性也来自确认重传

发送发之后收到接收方对于本段发送窗口内字节的ACK确认后才会移动发送窗口的左边界，接收窗口只有在前面所有段都确认的情况下才会移动左边界（当接收窗口中前面还有字节未接收，就收到了后面的字节，接收窗口的左边界是不会移动的，并不会对后面的字节进行确认，确保前面的数据会进行重传）



### 1.8 浏览器输入URL后，按下回车经历流程

1. DNS解析，由近道远依次是 **浏览器**缓存-->系统缓存-->**路由器**缓存-->**IPS服务器**缓存-->域名服务器缓存-->**顶级域名服务器**缓存
2. 进行TCP连接
3. 发送HTTP请求
4. 服务器处理请求返回HTTP报文
5. 浏览器解析结果渲染页面，结束连接



### 1.9 常见HTTP状态码

- 200： 正常
- 302： 重定向
- 400：Bad Request
- 401： 请求未经授权，这个状态码必须和WWW-Authenticate报头一起使用
- 403：服务器正确收到请求，但是拒绝提供服务
- 404：请求资源不存在
- 500：Server error
- 503：服务器暂时无法处理请求，一段时间后可能恢复



### 1.10 GET请求和POST请求的区别

- GET请求回退无害，POST会再次提交请求
- GET请求产生的URL可以被收藏夹收藏，POST不可以
- GET请求浏览器会主动缓存，POST不会，可以手动设置
- GET请求只能进行URL编码，POST支持多种编码方式
- GET请求请求参数会完整保留在浏览器历史中，POST请求不会保留参数
- GET请求URL参数长度有限制，POST没有
- GET于PSOT相比，不安全，GET将参数直接暴露在URL中，所以不能传递敏感信息，POST将参数存放在RequetBody中，相比GET安全一点
- GET请求，浏览器会把http header和data一并发送到Server，而POST，浏览器会先发送header，服务器响应状态码100 continue，浏览器在发送data， 并不是所有浏览器都会在POST中发送两次包，Firefox就只发送一次



### 1.11 Cookie和Session的区别

- Cookie

  由服务器发送给客户端的特殊信息，以文本形式存放在客户端，客户端再次请求服务器时会把Cookie回发，服务器收到Cookie后，解析Cookie生成客户端对应的内容

- Session

  服务器机制，保存在服务器中的信息，解析客户端请求携带的sessionid，按需保存状态信息

  Session的实现方式：Cookie和URL回写（即将sessionid以参数的形式携带到URL中）

- 区别

  Cookie数据保存在客户端中，Session数据保存在服务器中

  Session相比Cookie更加安全

  Session数据保存在服务器中会增加服务器负担



### 1.12 HTTP和HTTPS区别

- https需要到CA认证申请证书，http不需要
- https密文传输，http明文传输
- https默认使用443端口，http默认使用80端口
- https=http+加密+认证+完整性保护，比http更加安全
- https比http握手阶段比较耗时



### 1.13 https建立连接步骤

1. 客户端发送https请求

2. 服务端向客户端发送证书公钥，CA证书就是一对公钥私钥，包含了证书的颁发机构过期时间等等

3. 客户端解析证书公钥，这部分工作由客户端的TLS完成的，首先验证证书公钥是否有效，如果存在问题，会弹出提示，说明证书存在问题

   如果证书公钥没问题，那么就生成一个随机值，然后用公钥对该随机值进行加密，这样除非有私钥否则看不到被锁的内容

4. 传输加密后的随机值

5. 服务端用私钥解密随机值之后，客户端和服务端都以这个随机值进行加密解密了



### 1.14 Socket通信流程

![image-20210203191402341](https://github.com/buddhistSystem/doc/blob/main/image-storage/image-20210203191402341.png)