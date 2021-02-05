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



## 2. 数据库

### 2.1 如何设计一个关系型数据库

一个关系型数据库主要包括以下几个模块

存储系统（文件系统），存储管理（逻辑地址映射成物理地址），缓存模块，SQL解析模块，日志管理模块，权限划分模块，灾容模块，索引模块，锁模块



### 2.2 索引的作用

在**数据量大**的情况下，可以**加快查询**效率，尽量避免全表扫描



### 2.3 什么样的信息可以成为索引

主键，唯一键，普通键



### 2.4 索引的数据结构

二叉树，B树，B+树，Hash，BitMap

![image-20210204153601663](https://github.com/buddhistSystem/doc/blob/main/image-storage/image-20210204153601663.png)

B+树特点：

- 非叶子节点的子树指针个数与关键字个数相同
- 非叶子节点仅仅进行索引，所有数据必须在叶子节点中才能获取到
- 非叶子节点的子树指针p[i],指向关键字值[k[i] , k[i+1])
- 所有的叶子节点均有一个链指针指向下一个叶子节点

B+树的优点：

因为 B树不管叶子节点还是非叶子节点，都会保存数据，这样导致在非叶子节点中能保存的指针数量变少，指针少的情况下要保存大量数据，只能增加树的高度，导致IO 操作变多，查询性能变低

因为树的层高较低，所以B+树磁盘读写代价更低，查询效率更加稳定O(log n)



### 2.5 密集索引和稀疏索引的区别

![image-20210204154841992](https://github.com/buddhistSystem/doc/blob/main/image-storage/image-20210204154841992.png)

聚簇索引：其叶子节点保存不仅仅是键值，还保存了位于同一行记录里的其他列的信息，找到了索引也就找到了数				   据，B+树是一种聚簇索引

稀疏索引：只为索引码的某些值建立索引项，其叶子节点仅保存了键位信息以及该行数据的地址或者主键，查找时需要查到索引，对应到主键信息，然后根据找到的主键信息在B+Tree中再执行一遍B+Tree的索引操作，最终再到达叶子节点获取整行的数据（回表操作）

InnoDB有且只有一个聚簇索引，而MyISAM中都是非聚簇索引



### 2.6 为什么InnoDB只有一个聚簇索引，而不将所有索引都使用聚簇索引

因为聚簇索引决定了表的物理排列顺序，所以有且仅有一个

并且聚簇索引是将索引和数据都存放在叶子节点中，如果所有索引都是用聚簇索引，则每一个聚簇索引都将保存一份数据，造成数据冗余，消耗不必要的资源



### 2.7 索引越多越好吗

数据量小的表不需要建立索引，建立索引会增加额外的开销

索引只能加快查询效率，如果数据产生增删，则需要重新维护索引，增加维护成本

更多的索引需要更多的空间



### 2.8 MyISAM和InnoDB锁区别

MyISAM 默认表锁，不支持行锁

InnoDB默认行锁，支持表锁



MyISAM 在读取数据时会给整张表加上一个读锁，读取未完成时，其他Session进行增删时会给表加写锁，因为读锁未释放，所以写锁必须等待

显式加锁： lock table xxx read | write

释放锁： unlock tables 



**读锁**也叫**共享锁**（lock in share mode）,**写锁**也叫**排他锁**（for update)

先上读锁，可以在上读锁，不能上写锁

先上写锁，不可以在家任何锁



InnoDB 不走索引时使用的时表锁，走索引使用行锁



### 2.9 MyISAM 和 InnoDB 适用场景

MyISAM ：

- 频繁执行全表count语句（不带where条件），MyISAM 存储引擎中，把表的总行数存储在磁盘上
- 查询频繁，增删频率高
- 无需事务

InnoDB：

- 数据增删改查都频率较高
- 可靠性要求较高，需要支持事务



### 2.10 事务四大特性（ACID）

- 原子性 (Atomic)
- 一致性 (Consistency)
- 隔离性 (Isolation)
- 持久性 (Durability)



### 2.11 事务并发引起的问题

1. 丢失更新

   一个事务更新覆盖另一个事务更新

   eg：两个事务同时访问同一账户，session1查询余额为100，session2查询余额也为100，存入20余额变为120后session2提交事务，此时session1取出10，但是回滚事务，余额变为100，session2丢失更新

2. 脏读

   一个事务读取到另一个事务未提交的数据

   eg：两个事务同时访问同一账户，session1查询余额为100，取出10后，查询余额为90，此时session1并未提交事务，session2进行查询，查询余额为90，此时session1回滚事务，余额回滚为100，但是session2并不知道，还以为余额为90

3. 不可重复读

   事务多次读取同一数据，结果不一样

   eg：session1第一次读取【id=1，name=xx】，session2修改id=1的数据name=ss，并且提交事务，session1再次读取id=1的数据发现和第一次读取不一致

4. 幻读

   事务a读取与搜索条件匹配的行有3行，事务b插入或者修改该事务a的结果集，事务a更新所有与搜索条件匹配的数据，发现却不是3行

|        事务隔离级别        | 丢失更新 | 脏读 | 不可重复读 | 幻读 |
| :------------------------: | :------: | :--: | :--------: | :--: |
| 未提交读 (read uncommited) |    ×     |  √   |     √      |  √   |
|  已提交读 (read commited)  |    ×     |  ×   |     √      |  √   |
|  可重复读 (repeated read)  |    ×     |  ×   |     ×      |  √   |
| 串  行  化 (serializable)  |    ×     |  ×   |     ×      |  ×   |

实际上MySQL的可重复读也可以避免幻读



### 2.12 索引失效条件

- 在索引列上做任何操作（计算，函数，类型转换），导致索引失效
- 在组合索引中，如果中间莫格字段适用了范围条件，右边的索引列失效
- mysql在适用不等于（!= 或者<>），会使索引列失效
- is null 和 is not null 无法适用索引
- like通配符放在索引列左边，索引失效
- or，会使索引失效，可以用union代替



### 2.13 数据库3范式

1. 1NF：列不可再分，一列数据之恶能存储一个数据，不能再次拆分，强调原子性
2. 2NF：不可把多种数据保存在同一张表中，即一张表只能描述一种数据，强调唯一性
3. 3NF：消除字段冗余



## 3. JVM

### 3.1 java 如何实现平台无关性

java源码汇编成字节码，字节码在不同平台上的jvm执行时，会由不同平台的jvm转换成具体平台上的机器指令



### 3.2 为何不jvm不直接将源码解析成机器码执行

检查工作：每次执行时需要进行语法检查，句法检查，需要重新编译

兼容性：jvm可以执行其他语言生成的字节码，如ruby，若直接解析源码，则不能实现



### 3.3 jvm组成部分

![image-20210205162055891](https://github.com/buddhistSystem/doc/blob/main/image-storage/image-20210205162055891.png)

Class Loader : 依据特定命令加载class文件

Execution Engine：对命令进行解析

Native Interface： 本地接口，融合不同开发语言库为java所用

Runtime Data Area： jvm内存空间模型



### 3.4 什么是反射

反射机制是指在运行状态时动态获取类的信息，以及动态调用类方法的功能称为反射

eg：

```java
public class Robot{
    private String name;
    private void hello(String name){
        System.out.println("hello " + name);
    }
}
public class RobotTestCase{
    public static void main(String[] args) throws Exception {
        //Robot限定类名
    	Class rc = Class.forName("com.xxx.Robot");
        //动态获取对象
        Robot robot = (Robot)rc.newInstance();
        //动态获取方法
        Method hello = rc.getDeclaredMethod("hello",String.class);
        //修改私有方法访问权限
        hello.setAccessible(true);
        //动态调用
        hello.invoke(robot,"张三");
    }
}
```



### 3.5 类装载过程

1. 加载

   通过一个类的全限定名来获取定义此类的class文件二进制字节流

   将这个字节流代表的静态存储结构转换成方法区中的运行时数据结构

   在堆中生成一个Class类对象，作为方法区和该类数据的访问入口

2. 链接

   1. 验证

      确保被加载类的信息符合jvm规范，没有安全问题

   2. 准备

      为类的静态变量分配内存，并设置**默认值**（init 默认为0，String 默认为null，是指类型的默认值）

   3. 解析

      将常量池中的符号引用替换为直接引用（内存地址）

      符号引用是指一组符号来描述目标，包括类和接口的全限定名、字段的名称和描述符、方法的名称和描述符

3. 初始化

   执行类构造器<clinit>()方法，该方法编译时生成与class文件中的，该方法作用是静态变量的初始化和静态代码块的执行（为静态变量赋**初始值**）

   当类初始化时，若其父类没有初始化看，则需要先初始化其父类

### 3.6  java程序初始化顺序

1. 父类静态（静态变量，静态代码块）
2. 子类静态（静态变量，静态代码块）
3. 父类非静态（构造代码块，非静态成员变量）
4. 父类构造函数
5. 子类非静态（构造代码块，非静态成员变量）
6. 子类构造函数



### 3.7 谈谈ClassLoader

ClassLoader的主要工作都在类装载的加载阶段，作用是获取class文件的二进制数据流，将二进制数据流装载进内存，然后由jvm进行链接，初始化等工作



### 3.8 ClassLoader种类

BootStrapClassLoader:  c++编写，加载核心库java.*

ExtClassLoader:  java编写，加载扩展库javax.*

AppClassLoader: java编写, 再在程序所在目录，即程序的classpath

自定义ClassLoader: java编写，定制化加载



### 3.9 ClassLoader的双亲委派机制

1. 类加载器收到类加载请求
2. 判断类是否已经被加载，若没有加载，把这个类委托父类加载器执行，一直向上委托直至BootStrapClassLoader
3. BootStrapClassLoader检查自己是否能够加载（findClass()方法）,能加载则直接返回，否则抛出异常通知子加载器进行加载
4. 重复步骤3

优点：

1.核心作用是防止恶意篡改java核心类库，比如你自己的String类，加载时BootStrapClassLoader已经加载， 就会直接结束，保护java核心类库

2.防止字节码重复加载



### 3.10 类的加载loadClass方法和Class.forName区别

隐式加载：new()

显示加载：loadClass(),Class.forName()

loadClass方法加载的类只完成了装载的加载过程，并没有执行链接和初始化

Class.forName加载的类已经完成了初始化



### 3.11 JVM 内存模型-jdk8

- 线程私有部分：

  - 程序计数器：

    当前程序所执行字节码的行号指示器（逻辑），改变计数器的值来获取下一条需要执行的字节码指令

    每条线程需要独立的程序计数器，和线程一对一

  - 虚拟机栈

  - 本地方法栈

- 线程共有部分：

  - 元空间

    java8元空间代替了永久代，元空间存储着类文件在jvm运行时数据结构以及Class相关内容

  - 堆

    对象实例分配区域，GC主要管理区域

    

    Jdk7之后字符串常量池从方法区被移动到了堆中

    

### 3.12元空间metaSpace对比永久代PermGen

- 元空间使用的是本地内存，永久代使用的是jvm内存
- 字符串常量池存在永久代中，容易出现性能问题和内存溢出
- 类和方法信息大小难以确定，给永久代大小指定带来困难
- 永久代会为GC带来不必要的复杂性



### 3.13 jvm调优参数

- -Xss : 规定每个线程虚拟机栈大小，一般256k足够
- -Xms：规定堆初始大小
- -Xmx：规定堆最大值



### 3.14 jvm常见内存溢出问题

- java.lang.OutOfMemoryError: Java heap space ----JVM Heap（堆）溢出

  JVM在启动的时候会自动设置JVM Heap的值，其初始空间(即-Xms)是物理内存的	1/64，最大空间(-Xmx)不可超过物理内存。可以利用JVM提供的-Xmn -Xms -Xmx等选项可进行设置。Heap的大小是Young Generation 和Tenured Generaion 之和。

  在JVM中如果98％的时间是用于GC，且可用的Heap size 不足2％的时候将抛出	此异常信息。

- java.lang.OutOfMemoryError: PermGen space ---- PermGen space溢出

  PermGen space的全称是Permanent Generation space，是指内存的永久保存区域。

  为什么会内存溢出，这是由于这块内存主要是被JVM存放Class和Meta信息的，	Class在被Load的时候被放入PermGen space区域，它和存放Instance的Heap区	域不同,sun的 GC不会在主程序运行期对PermGen space进行清理，所以如果你的	APP会载入很多CLASS的话，就很可能出现PermGen space溢出。

-  java.lang.StackOverflowError ---- 栈溢出

  通常是程序错误，比如递归太多层数