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



## 4. GC

### 4.1 判断对象是否为垃圾的算法

- **引用计数法**：如果一个对象没有任何引用与之相关联，那么这个对象就可能成为被回收对象，但此种方法无法解决循环引用
- **可达性分析算法**：java采用这种方法，通过GC Roots对象作为起点进行搜索，如果GC Roots和一个对象没有可达路径，则这个对象在经过至少两次标记后就可能被回收



### 4.2 垃圾回收算法

- **标记-清除算法**（适合老年代）

  这种方式容易产生内存碎片，碎片太多导致在为大对象分配内存空间时内存不够而提前触发GC

- **复制算法**（适合年轻代）

  将内存按容量分为等量的两块，每次只使用其中一块，当一块内存用完之后，就可以将存活的对象全部复制到另一块内存上，然后清空已用内存

  优点：不容易产生内存碎片，简单高效，适合对象存货率低的场景

  缺点：浪费内存空间，如果对象存活较多，复制算法的效率会大大降低

- **标记-整理算法**（适合老年代）

  为了解决复制算法浪费内存的缺陷，标记整理算法采用的时在标记完成之后，将存活对象移动到内存的一端，然后清掉边界以外的内存呢

- **分代收集算法**

  根据对象存活的周期，将堆区划分为新生代和老年代

  

  **新生代**（1/3堆空间）：Minor GC是发生在新生代的垃圾收集动作，采用**复制算法**

  ​	新生代分为3块（Eden(8/10) , From Survivor(1/10) , To Survivor(1/10) ）

  

  **老年代**（2/3堆空间）:  Full GC是发生在老年代的垃圾收集动作，采用**标记-整理算法**

  

  对象出生在Eden或者是其中一个Survivor区（假设是From）经过一次Minor GC之后，若对象还存活并且能被另一块Survivor（To）所容纳，那么使用复制算法将Eden 喝 From Survivor中存活的对象复制到另一块Survivor中（To），并将他们的年龄设置位1，以后对象在Survivor中每熬过一次Minor GC他的年龄就会加1，当年龄到达15（默认），这些对象就会成为老年代



### 4.3 触发Full GC的条件

- 老年代空间不足
- jkd7以前，永久代空间不足
- Minor GC晋升到老年代的对象总大小，大于老年代剩余空间
- 调用System.gc()，建议jvm进行Full GC,并不一定生效
- 使用RMI来进行RPC或管理的jdk应用，每小时执行一次Full GC



### 4.4 垃圾收集器

jvm有两种运行模式server以及client



垃圾收集器之前的关系：

![image-20210206165203010](https://github.com/buddhistSystem/doc/blob/main/image-storage/image-20210206165203010.png)

- 新生代垃圾收集器：

  - Serial 收集器 (-XX:+UseSerialGC)

    复制算法，单线程运行，client模式默认新生代收集器，收集器工作时，暂停其他所有工作线程

  - ParNew 收集器 ( -XX:+UserParNewGC)

    复制算法，多线程运行，其他行为与Serial一样

    单核cpu下，并不会比Serial效果好，默认开启的线程数与cpu数相同

  - Parallel Scavenge收集器 (-XX:+UseParallelGC)

    复制算法，多线程运行，server模式默认新生代收集器，比起关注线程停顿，更关注吞吐量

    吞吐量=运行用户代码时间/(运行用户代码时间+垃圾收集时间)

- 老年代垃圾收集器

  - Serial Old 收集器 (-XX:+UseSerialOldGC)

    标记-整理算法，单线程运行，client默认默认老年代垃圾收集器

  - CMS 收集器 (-XX:+UseConcMarkSweepGC)

    标记-清除算法

  - Parallel Old 收集器 (-XX:+UseParallelOldGC)

    标记-整理算法，多线程运行，吞吐量优先

- Grabage First收集器

  即能用于新生代也能老年代的收集器，复制+标记整理算法

  将整个java堆内存划分为多个大小相等的Region，新生代和老年代不在物理隔离，只是逻辑上进行区分



## 5.多线程与并发

### 5.1 进程、线程、协程的区别

​	进程是资源分配的最小单位，线程是cpu调度的最小单位

​	线程不能看做独立应用，而进程可看做独立应用

​	进程有独立地址空间，线程没有独立的地址空间

​	进程的切换比线程的切换开销大

​	**协程是一种用户态的轻量级线程，**协程的调度完全由用户控制。协程和线程一样共享堆，不共享栈，协程由程		序员在协程的代码里显示调度。协程拥有自己的寄存器上下文和栈。协程调度切换时，将寄存器上下文和栈		保存到其他地方，在切回来的时候，恢复先前保存的寄存器上下文和栈，直接操作栈则基本没有内核切换的		开销，可以不加锁的访问全局变量，所以上下文的切换非常快



### 5.2 Thread类中start方法和run方法的区别

​	调用start()方法会创建一个新的线程并启动

​	Run()方法知识Thread的一个普通方法调用



### 5.3 Thread和Runable的关系

​	Thread是实现了Runnable接口的类，使run方法支持多线程

​	因为单一继承原则，推荐使用Runnable接口



### 5.4 如何给run()方法传参

​	构造函数传参

​	成员变量传参

​	回调函数传参



### 5.5 如何获得线程返回值

- 主线程等待

  ```java
  public class CycleWait implements Runnable {
      private String value;
      @Override
      public void run() {
          try {
              Thread.currentThread().sleep(3000);
          } catch (InterruptedException e) {
              e.printStackTrace();
          }
          value = "hello world";
      }
      
      public static void main(String[] args) throws InterruptedException {
          CycleWait cycleWait = new CycleWait();
          Thread t = new Thread(cycleWait);
          t.start();
          //主线程等待法
          while (cycleWait.value == null) {
              Thread.currentThread().sleep(100);
          }
          //使用join实现，在主线程中调用t线程join方法，意思是主线程等待t线程执行完毕
          t.join();
          System.out.println(cycleWait.value);
      }
  }
  ```

  

- 使用Callable接口，同故宫FutureTask或者线程池获取

  ```java
  public class CallableTest implements Callable<String> {
      @Override
      public String call() throws Exception {
          String str = "hello world";
          Thread.currentThread().sleep(3000);
          return str;
      }
      
      public static void main(String[] args) 
          throws ExecutionException, 	InterruptedException {
          futureTaskTest();
          threadPoolTest();
      }
      //使用FutureTask对象获取返回值
      public static void futureTaskTest()
          throws ExecutionException, InterruptedException {
          FutureTask task = new FutureTask(new CallableTest());
          Thread thread = new Thread(task);
          thread.start();
          if (!task.isDone()) {
              System.out.println("未执行完成");
          }
          System.out.println(task.get());
      }
      //使用线程池接收返回值
      public static void threadPoolTest()
          throws ExecutionException, InterruptedException {
          ExecutorService es = Executors.newCachedThreadPool();
          Future<String> future = es.submit(new CallableTest());
          if (!future.isDone()) {
              System.out.println("未执行完成");
          }
          System.out.println(future.get());
      }
  }    
  ```



### 5.6 线程的状态

1. 新建 (New)：创建后未启动的线程

2. 运行 (Running)：包含Running和Ready，可能正在执行，也可能等待cpu分配时间

3. 无限期等待 (Waiting)：cpu不会给这种线程分配时间，需要显式唤醒

   没有设置Timeout参数的Object.wait()方法

   没有设置Timeout参数的Thread.join()方法

   LockSuppot.pack()方法

4. 有限期等待 (Time Waiting)：在一定时间后系统会自己唤醒

   Thread.sleep()方法

   设置Timeout参数的Object.wait()方法

   设置Timeout参数的Thread.join()方法

   LockSuppot.packNanos()方法，LockSuppot.packUntil()方法

5. 阻塞 (Block)：等待获取排他锁

6. 结束 (Terminated)：线程已结束



### 5.7 wait()和sleep()的区别

- sleep是Thread中的方法，wait是Object中定义的方法
- sleep可以在任何地方使用，wait只能在synchronized方法或synchronized块中使用
- sleep只会让出cpu，不会释放锁，wait不仅让出cpu，还会释放锁



### 5.8 锁池和等待池

- 锁池

  假设线程A已经拥有了某个对象（不是类）的锁，而其他现线程B、C想调用这个对象的某个synchrronized方法（或者块），由于B、C线程进入对象的synchronized方法（或者块）之前必须获得该对象锁的拥有权，而恰巧该对象的锁目前正在被线程A占用，此时B、C线程就会被阻塞，进去一个地方去等待锁的释放，这个地方便是该对象的锁池

- 等待池

  假设线程A调用了某个对象的wait（）方法，线程A就会释放该对象的锁，同时线程A就会进去该对象的等待池中，进去等待池中的对象不会去竞争该对象的锁



### 5.9 notify和notifyAll的区别

​	notifyAll会让所有处于等待池的线程全部进入锁池去竞争获取锁的机会

​	notify只会随机选取一个处于等待池中的线程进入锁池去竞争获取锁的机会



### 5.10 yield()方法

​	Thread.yield()函数被调用时，会给线程调度器一个当前线程愿意让出cpu使用的暗示，但是线程调度器可能会	忽略这个暗示



### 5.11 如何中断线程

调用interrupt()函数，通知线程该中断了

如果线程处于阻塞状态，那么线程将立即退出被阻塞状态，并抛出一个InterruptedException

如果线程处于正常活动状态，那么会将该线程的中断标记设置未true，被设置中断标志的线程将继续正常运行

```java
public static void main(String[] args) throws InterruptedException {
    Thread t = new Thread(new Runnable() {
        @Override
        public void run() {
            try {
                while (!Thread.currentThread().isInterrupted()) {
                    System.out.println("===");
                    Thread.sleep(1000);
                }
            } catch (InterruptedException e) {
                System.out.println(Thread.currentThread().getState());
            }
        }
    });
    t.start();
    Thread.currentThread().sleep(3000);
    t.interrupt();
}
```





## 6. 并发-原理

### 6.1 synchronized介绍

互斥锁的特性：

- 互斥性(原子性)

  即在同一时间只允许一个线程持有某个对象，通过这种特性来实现多线程的协调机制

- 可见性

  保证一个线程释放锁之前，对共享变量所作的修改，随后获取该锁的另一个线程是可见的，即在获取共享变量时必须是在内存获取，否则另一线程可能实在本地缓存副本上操作（cpu缓存），引起数据不一致

synchronized锁的是对象，不是代码

总结：

1. 有线程访问对象的同步代码块时，其他线程可以访问该对象的非同步代码块
2. 若锁住的是同一个对象，一个线程访问对象的同步代码块时，其他访问该同步代码块的线程被阻塞
3. 若锁住的是同一个对象，一个线程访问对象的同步方法时，其他访问该同步方法的线程被阻塞
4. 若锁住的是同一个对象，一个线程访问对象的同步代码块时，其他线程访问该对象的同步方法会被阻塞，反之亦然
5. 同一个类不同对象的对象锁互不干扰
6. 类锁是特殊的对象锁，表现和1.2.3.4一致，由于一个类只有一把类锁，所以同一个类的不同对象使用类锁是同步的
7. 类锁，对象锁互不干扰



### 6.2 什么是可重入

当一个线程试图操作一个由其他线程持有对象锁的临界资源时，将会处于阻塞状态，但是一个线程再次请求自己持有对象锁的临界资源，不会被阻塞，这种情况属于可重入



### 6.3 自旋锁与自适应自旋锁

- 自旋锁

  多数情况下，共享数据的锁定持续时间很短，线程切换不值得(默认自旋10次)

  通过让线程执行忙，循环等待锁释放，不会像Thread.sleep()一样放弃cpu执行时间

  若锁被其他线程占用时间长，自旋会带来许多性能开销

- 自适应自旋锁(jdk6)

  与自旋锁相比，自旋次数不固定

  

  Java对象由对象头、对象体以及对齐字节所组成。而Java对象头中的Mark Word默认存放的是对象的hasCode、分代年龄以及锁标记位等(锁位标记存放着当前该对象锁是哪个线程拥有)。

  

  由前一次在同一个锁上自旋时间以及锁拥有着的状态决定，如果在同一对象锁上，某个线程自旋等待成功获取了锁，那么并且持有该锁的线程正在运行，jvm会认为该锁自旋获取成功的可能性较大，会增加等待时间



### 6.4 锁消除和锁粗化

- 锁消除

  JIT编译时，对运行上下文进行扫描，去除不可能存在竞争的锁

  ```java
  public static void test(String s1,String s2){
      StringBuffer stringBuffer = new StringBuffer();
      stringBuffer.append(s1).append(s2);
  }
  ```

  如上，不同线程调用StringBuffer.append()方法，由于stirngBuffer变量属于本地变量，只会在test()方法中使用，即每个线程都会拥有自己的stringBuffer对象，所以jvm会自动消除append方法中的锁，提升效率

- 锁粗化

  通过扩大加锁范围，避免重复加锁，如在循环中执行同步代码块，粗化为该方法加锁



### 6.5 synchronized的四种状态

​	无锁，偏向锁，轻量级锁，重量级锁

1. 无锁

2. 偏向锁

   在大多实际环境下，锁不仅不存在多线程竞争，而且总是由同一个线程多次获取

   

   当一个线程访问同步快并获取锁时，会在对象头和栈帧中的锁记录里存储锁偏向的线程ID，以后该线程在进入和退出同步块时不需要进行`CAS`操作来加锁和解锁。只需要简单地测试一下对象头的`Mark Word`里是否存储着指向当前线程的偏向锁。如果成功，表示线程已经获取到了锁

3. 轻量级锁

   偏向锁使用了一种等待竞争出现才会释放锁的机制，所以当其他线程尝试获取偏向锁时，持有偏向锁的线程才会释放锁。但是偏向锁的撤销需要等到全局安全点（就是当前线程没有正在执行的字节码）。它会首先暂停拥有偏向锁的线程，让你后检查持有偏向锁的线程是否活着。如果线程不处于活动状态，直接将对象头设置为无锁状态。如果线程活着，JVM会遍历栈帧中的锁记录，栈帧中的锁记录和对象头要么偏向于其他线程，要么恢复到无锁状态或者标记对象不适合作为偏向锁

   

   线程在执行同步块之前，JVM会先在**当前线程的栈桢**中创建用于存储锁记录的空间，并**将对象头中的Mark Word复制到 当前线程的锁记录**中，官方称为Displaced Mark Word。然后线程尝试使用CAS将对象头中的Mark Word替换为**指向当前线程锁记录的指针**。如果成功，当前线程获得锁，如果失败，表示其他线程竞争锁，当前线程便尝试使用**自旋**来获取锁

4. 重量级锁

   当锁处于这个状态下，其他线程试图获取锁时都会**被阻塞住**，当持有锁的线程释放锁之后会唤醒这些线程，被唤醒的线程就会重新争夺锁

   

![image-20210208221925918](https://github.com/buddhistSystem/doc/blob/main/image-storage/image-20210208221925918.png)



### 6.6 synchronized和ReentrantLock区别

ReentrantLock介绍：

位于java.util.concurrent.locks包

和CountDownLatch、FutureTask、Semaphore一样基于AQS实现

能够实现比synchronized更细粒度的控制，如控制公平性

调用lock()后，必须调用unlock()释放锁

性能未必比synchronized高，并且也是可重入的

ReentrantLock公平性设置

```java
ReentrantLock lock = new ReentrantLock(true);//慎用
```

参数未true时，倾向将锁赋予等待时间最久的线程

synchronized 是非公平锁



最核心的区别就在于Synchronized适合于并发竞争低的情况，因为Synchronized的锁升级如果最终升级为重量级锁在使用的过程中是没有办法消除的，意味着每次都要和cpu去请求锁资源，而ReentrantLock主要是提供了阻塞的能力，通过在高并发下线程的挂起，来减少竞争，提高并发能力

- synchronized是一个关键字，是由**jvm层面**去实现的，而ReentrantLock是由**java api**去实现的
- synchronized是隐式锁，可以**自动释放锁**，ReentrantLock是显式锁，需要**手动释放锁**
- ReentrantLock可以让等待锁的线程响应中断，synchronized不行，使用synchronized时，等待的线程会一直等待下去，不能够响应中断
- ReentrantLock可以获取锁状态，而synchronized不能



### 6.7 volatile和synchronized区别

1. volatile本质是告诉jvm当前变量在寄存器（工作内存）中的值是不确定的，需要从主存中读取；synchronized则是锁定当前变量，只有当前线程可以访问该变量，其他线程被阻塞知道该线程完成变量操作为止

2. volatile仅能适用在变量级别；synchronized可以在变量、方法、和类级别使用

3. volatile仅能保证变量修改的可见性，不能保证原子性；synchronized则可以保证变量修改的原子性和可见性

4. volatile不会造成线程阻塞；synchronized可能造成线程阻塞

5. volatile标记的变量不会被编译器优化；synchronized编辑的变量可以被编译器优化



### 6.8 CAS(Compare and Swap)



### 6.9 线程池

利用Executors创建不同的线程池满足不同场景的需求

1. newFixedThreadPool(int nThreads)

   指定工作数量的线程池

2. newCachedThreadPool()

   短时间处理大量任务的线程池

   - 试图缓存线程并重用
   - 如果线程闲置时间超过阈值，就会被终止并移除
   - 系统长时间闲置时，几乎不消耗资源

3. newSingleThreadExecutor()

   创建唯一的工作线程来执行任务，线程如果异常结束，会有另一个线程取代它

   这个比较适合需要保证队列中任务顺序执行的场景

4. newSingleThreadScheduledExecutor()和newScheduledThreadPool(int corePoolSize)

   定时或者周期工作调度，浪者区别是单一工作线程还是多个线程

5. newWorkStealingPool()--jdk8

   内部构件ForkJoinPool，利用working-stealing算法，并行执行任务，不保证处理顺序

**使用线程池的好处：**

降低资源消耗

提高线程可管理性

**创建线程池:**

1. ```java
   ExecutorService executorService =Executors.newFixedThreadPool(3);
   // 使用该种方式创建线程池容易造成OOM（out of memory）
   //使用该种方式 LinkedBlockingDeque的默认容量为无限制
   ```

2. ```java
   ExecutorService executorService = new ThreadPoolExecutor(
   	3,//corePoolSize
   	3,//maximumPoolSize
   	60,//keepAliveTime
   	TimeUnit.SECONDS,//unit
   	new LinkedBlockingDeque<>(7),//workQueue
   	new DefaultThreadFactory("myPool"),//threadFactory
   	new ThreadPoolExecutor.AbortPolicy()//handler
   );
   ```

   参数：

   - corePoolSize：核心线程数量
   - maximumPoolSize：最大线程数量
   - keepAliveTime：非核心线程存活时间
   - unit：keepAliveTime时间单位
   - workQueue：任务等待队列
   - threadFactory：线程创建工厂，使用DefaultThreadFactory工厂创建的线程具有相同优先级
   - handler： 线程池饱和策略
     - AbortPolicy：直接抛异常，默认的拒绝策略
     - CallerRunsPolicy：直接在调用线程执行该任务
     - DiscardPolicy：丢弃任务
     - DiscardOldestPolicy：丢弃最老未被执行任务，执行当前任务



### 6.10 线程池的状态

![image-20210208232555450](https://github.com/buddhistSystem/doc/blob/main/image-storage/image-20210208232555450.png)

1. Running：能够接收新任务，并且也能处理阻塞队列中的任务
2. Shutdown：不在接收新任务，但是能处理存量任务
3. Stop: 不在接收新任务，也不处理存量任务
4. Tidying：所有任务都终止
5. Terminated：terminated()方法执行完后进入该状态



### 6.11 线程池submit和execute方法的区别



## 7. java常用类库

### 7.1 java异常架构

![image-20210211130205915](https://github.com/buddhistSystem/doc/blob/main/image-storage/image-20210211130205915.png)

- Error和Exception的区别：

  **Error**：为程序无法处理的系统错误，编译器不做检查

  **Exception**：程序可以处理的异常，捕获后可能恢复

- CheckedException和UnCheckedException的区别

  **CheckedException**：图中粉色的是检查异常，必须被try{}catch语句块所捕获，或者通过在方法签名中通过throws子句声明，受检查的异常必须在编译时被捕捉处理

  **UnCheckedException**：也就是运行时异常RuntimeException

- 常见的RuntimeException
  - NullPointerException: 空指针引用异常
  - ClassCastException:  类型强制转换异常
  - IllegalArgumentException: 传递非法参数异常
  - ArithmeticException: 算术运算异常
  - ArrayStoreException: 向数组中存放与声明类型不兼容对象异常
  - IndexOutOfBoundsException: 下标越界异常
  - NumberFormatException: 数字格式异常
  - NegativeArraySizeException: 创建一个大小为负数的数组错误异常

- Finally执行顺序优先于return语句
- try{}catch语句效率并不如if()语句



### 7.2 java集合架构

#### 7.2.1 集合框架图

![image-20210211131453134](https://github.com/buddhistSystem/doc/blob/main/image-storage/image-20210211131453134.png)

![image-20210211131503928](https://github.com/buddhistSystem/doc/blob/main/image-storage/image-20210211131503928.png)



#### 7.2.2 List

- **ArrayList** 是一个动态数组结构，支持随机存取，尾部插入删除方便，内部插入删除效率低下，因为需要移动数组内部元素，如果内部数组容量不足时则自动扩容，当数组很大时，效率会变低

  **ArrayList**扩容方式：

  ArrayList默认容量为10

  jdk1.6扩容算法  新容量=旧容量*1.5+1

  jdk1.8扩容算法  新容量=旧容量*1.5 ，但是扩容或检查当前容量是否大于需求量，如扩容后容量还小于需求量，就直接使用需求量当作新的数组容量，让后调用Arrays.copyOf()复制

  

  Arrays.copyOf()不仅仅只是拷贝数组中的元素，在拷贝元素时，会创建一个新的数组对象而System.arrayCopy只拷贝已经存在数组元素。

  Arrays.copyOf()该方法的底层还是调用了System.arrayCopyOf()方法。

  System.arrayCopy如果改变目标数组的值原数组的值也会随之改变

  

- **LinkedList** 是一个双向链表结构，在任意位置插入删除都很方便，但是不支持随机取值，每次都只能从一端开始遍历，直到查询到指定对象，不过他不像ArrayList需要内存拷贝，因此效率较高，但是因为存在额外的前驱和后继节点，因此占用内存比ArrayList较高

  

- **Vector** 也是一个动态数组结构，自jdk1.1引入，ArrayList为jdk1.2引入，ArrayList大部分方法和Vector类似，区别是Vector是允许同步访问，Vector中的操作是线程安全的，因而效率很低，ArrayList所有操作是异步的，执行效率高，但线程不安全

  vector的替代

  ```java
  List<Object>list = Collections.synchronizedList(new ArrayList<Object>());
  //使用复制容器java.util.concurrent.CopyOnWriteArrayList
  final CopyOnWriteArrayList<Object> cowList = new CopyOnWriuteArrayList();
  ```



- **Stack** 是Vector的子类，本质也是一个动态数组，不同的是，它的数据结构是先进后出

  Stack现在也不常用，因为有一个**ArrayDeque**双端队列，可以代替Stack所有功能，且执行效率比Stack高



#### 7.2.3 Map

- **HashMap** 

  继承AbstractMap，key不可重复，因为使用哈希表存储元素，所以输入数据与输出数据顺序不一致，另外HashMap的 key 和 value 均可为null ，但是只能有一个key为null

  

  java8之前用**数组**+**链表**实现，如果极端情况数据的hashcode都一样，性能会恶化O(1)->O(n)

  java8之后用**数组**+**链表**+**红黑树**实现，性能最差为O(log n)

  默认容量16，装载因子0.75，扩容后容量变为之前的两倍

  当链表大小大于8并且整个Hashmap的元素大于64就会由链表改造成为红黑树

  为什么是8，因为红黑树查找时间复杂度是O(log n) 8个元素查找需要3次，链表线性查找需要的平均次数为n/2 = 4 次

  当链表大小小于6就会由红黑树转为链表

  

- **HashTable** 

  早期提供的哈希表的实现，线程安全串行执行，性能较差，key、value不能为null

  

- **ConcurrentHashMap**

  早期的ConcurrentHashMap由分段锁实现

  当前的ConcurrentHashMap由CAS+synchronized使锁更细化

  ConcurrentHashMap不允许null键

  put方法执行时，通过hash定位数组的索引坐标，是否存在Node节点，如果没有则用CAS进行添加（链表头节点），如果添加失败则进入下一次循环，如果头节点不为空，则尝试获取头节点的同步锁，在进行操作

  

- **LinkedHashMap**

  HashMap的子类，内部使用链表记录插入顺序，使得输入与输出的记录顺序相同



- **TreeMap**

  能够把它保存的记录根据键排序，默认是按键值的升序排序，也可以指定排序的比较器，当用 Iterator 遍历时，得到的记录是排过序的；如需使用排序的映射，建议使用 TreeMap



### 7.2.4 Set

- **HashSet**

  底层基于HashMap的key实现，元素不可重复，特性同HashMap

- **LinkedHashSet**

  底层也是基于LinkedHashMap的key实现，一样元素不可重复，特性同于LinkedHashMap

- **TreeSet**

  也是基于 TreeMap 的k实现的，同样元素不可重复，特性同 TreeMap

  Set集合的实现，基本都是基于Map中的键做文章，使用Map中键不能重复、无序的特性



### 7.2.5 hashcode作用

​	对象的散列值，Object类中的方法，

​	像Hash开头的类，HashMap、HashSet、Hash等等

​	哈希代码值可以提高性能

​	实现了hashCode一定要实现equals，因为底层HashMap就是通过这2个方法判断重复对象的，先判断key的		hashCode是否相等，相等进行equals判断，equals为true覆盖，不为true以链表的形式插入

​	如果两对象equals()是true,那么它们的hashCode()值一定相等

​	如果两对象的hashCode()值相等，它们的equals不一定相等（hash冲突）



### 7.2.6 final的四种用法

### 7.2.7 序列化是什么，底层怎么实现



## 8. Java IO

### 8.1 Java IO流图

![java_io_流](https://github.com/buddhistSystem/doc/blob/main/image-storage/java_io_流.jpg)



### 8.2 基本概念

​	**同步异步针对的是被调用者**

- 同步：A调用B，B处理是同步的，直到B处理完成之后才会通知A
- 异步：A调用B，Ｂ异步处理，Ｂ收到Ａ的请求之后，会先通知Ａ收到了请求，然后异步处理，处理完成之后通过回调等方式通知Ａ



​	**阻塞和非阻塞针对的是调用者**

- 阻塞：Ａ调用Ｂ，Ａ一直等待Ｂ的返回，期间不能做其他任务，处于阻塞状态
- 非阻塞：Ａ调用B，A调用成功后可以不用一直等待B的返回，期间可以执行其他任务



**java中的3种IO模型**

- BIO(Blocking IO)同步阻塞IO

  每有一个客户端连接就需要和Server建立一个线程

  ![image-20210216014823210](https://github.com/buddhistSystem/doc/blob/main/image-storage/image-20210216014823210.png)

- NIO(New IO)同步非阻塞IO

  ![image-20210216014935931](https://github.com/buddhistSystem/doc/blob/main/image-storage/image-20210216014935931.png)

  通道和缓冲区是NIO种的核心对象，几乎每一个IO操作都要使用它们

  - 缓冲区

    Buffer是一个对象，它包含一些要写入或者刚读出的数据。在 NIO 中加入 Buffer 对象，体现了新库与原 I/O 的一个重要区别。在面向流的 I/O 中，数据直接写入或者将数据直接读到 Stream 对象中。

    

    在 NIO 库中，所有数据都是用缓冲区处理的。在读取数据时，它是直接读到缓冲区中的。在写入数据时，它是写入到缓冲区中的。任何时候访问 NIO 中的数据，都是将它放到缓冲区中。

    

    缓冲区实质上是一个数组。通常它是一个字节数组，但是也可以使用其他种类的数组。但是一个缓冲区不 仅仅 是一个数组。缓冲区提供了对数据的结构化访问，而且还可以跟踪系统的读/写进程。

    

  - 缓冲区类型

    最常用的缓冲区类型是 ByteBuffer。一个 ByteBuffer 可以在其底层字节数组上进行 get/set 操作(即字节的获取和设置)

    

    其他类型：CharBuffer、ShortBuffer、IntBuffer、LongBuffer、FloatBuffer、DoubleBuffer

    

    每一个 Buffer 类都是 Buffer 接口的一个实例。 除了 ByteBuffer，每一个 Buffer 类都有完全一样的操作，只是它们所处理的数据类型不一样。因为大多数标准 I/O 操作都使用 ByteBuffer，所以它具有所有共享的缓冲区操作以及一些特有的操作。

    

  - 通道

    Channel是一个对象，可以通过它读取和写入数据。拿 NIO 与原来的 I/O 做个比较，通道就像是流。

    所有数据都通过 Buffer 对象来处理。不会将字节直接写入通道中，相反，先将数据写入包含一个或者多个字节的缓冲区。同样，不会直接从通道中读取字节，而是将数据从通道读入缓冲区，再从缓冲区获取这个字节。

    通道类型：通道与流的不同之处在于通道是双向的。而流只是在一个方向上移动(一个流必须是 InputStream或者 OutputStream 的子类)， 而 通道 可以用于读、写或者同时用于读写。

    因为它们是双向的，所以通道可以比流更好地反映底层操作系统的真实情况。特别是在 UNIX 模型中，底层操作系统通道是双向的。

    

- AIO(Asynchronous IO)异步非阻塞IO



## 9. spring

### 9.1 IOC和DI的区别

- IOC： Inverse of control反转控制的概念，就是将原本程序中需要手动创建的对象的控制权交给spring来管理
- DI：Dependency injection依赖注入，在spring创建对象时，动态的将以有的对象注入到Bean



### 9.2 BeanFactory 接口和ApplicationContent接口的区别

- ApplicationContext接口继承BeanFactory， Srping的核心工厂是BeanFactory，BeanFactory采用延迟加载，第一次getBean时候才会初始化Bean，ApplicationContext是会在加载配置文件的时候初始化Bean

- ApplicationContext是对BeanFactory的扩展，它可以进行国际化处理，时间传递和Bean的自动装配以及不同应用层的Context实现



### 9.3 srping配置bean实例化有哪些方法

1. 使用**空构造器实例化**，使用此种方式，class属性指定的类必须有空构造器

```xml
<bean name="people" class="com.xxx.entity.People"></bean>
```

2. 使用**带参数的构造器**，可以使用<constructor-arg>标签指定构造器参数值，index表示位置，value表示常量值也可以指引用，指定引用使用ref来引用另一个Bean的定义

```xml
<bean name="people2" class="com.xxx.entity.People">
	<constructor-arg index="0" value="张三"></constructor-arg>
    <constructor-arg index="1" value="18"></constructor-arg>
    <constructor-arg index="2" ref="collection"></constructor-arg>
</bean>
```

3. 使用**静态工厂方式**实例化bean,使用这种方式除了指定必须的class属性，还要指定factory-method属性来指定实例化Bean的方法，而且使用静态工厂方法也允许指定方法参数，spring IoC容器将调用此属性指定的方法来获取Bean

   ```xml
   <bean name="bean2" class="com.xxx.Bean2Factory" factory-method="createBean2"></bean>
   ```

4. 使用**实例工厂**实例化bean，使用这种方式不能指定class属性，此时必须使用factory-bean属性来指定工厂Bean，factory-method属性指定实例化Bean的方法，而且使用实例工厂方法允许指定方法参数，方式和使用构造器方式一样

   ```xml
   <bean name="bean3Factory" class="com.xxx.Bean3Factory"></bean>
   <bean name="bean3" factory-bean="bean3Factory" factory-method="createBean3"></bean>
   ```

   

### 9.4 spring Bean 生命周期





### 9.5 spring bean 作用域

- **Singleton**：Spring只会为每一个bean创建一个实例
- **Prototype**：每一次请求（即执行getBean()方法都会产生一个bean实例）
- **Request**：针对每一个HTTP请求都会产生一个bean，该bean仅在当前request请求内	有效，仅适用于WebApplicationContext环境
- **Session**：同一个HTTP Session共享一个Bean，不同Session使用不同的Bean。该作用域仅适用于web的Spring WebApplicationContext环境



### 9.6 spring如何处理线程并发问题

通过ThreadLocal解决，ThreadLocal会为每个线程提供一个独立的变量副本，从而隔离了多个线程对数据的访问冲突，概括起来对于多线程资源共享问题，同步机制采用了以时间换空间的形式，ThreadLocal采用了以空间换时间的方式



### 9.7 ThreadLocal实现原理

每个Thread对象内部都维护了一个ThreadLocalMap这样一个ThreadLocal的Map，可以存放若干ThreadLocal

以线程自己作为Map的key，存储value，所以每个线程都是从自己的Map中读取变量，就不存在线程安全问题了



### 9.8 SpringAOP

- 连接点（JoinPoint）

  就是spring允许通知Advice的地方，如每个方法的前后，或者抛出异常时等，spring只支持方法的连接点，而AspectJ还可以在构造器或者属性注入时都行

- 切入点（Pointcut）

  目标对象,将要和已经 增强的方法

  一个类里，有15个方法，那就有15个连接点，但是并不需要在所有方法都使用通知，只是想让其中几个，在调用这几个方法之前、之后或者抛出异常时干点什么，那么就用切入点来定义这几个方法，让切入点来筛选连接点，选中需要的方法

- 切面

  切入点+通知

- 通知类型

  - 前置通知 (@Before) 方法执行之前执行
  - 后置通知 (@After) 方法执行之后执行，无论是否发生异常
  - 返回通知 (@AfterReturning) 方法正常结束后执行
  - 异常通知 (@AfterThrowing) 方法抛出异常后执行
  - 环绕通知 (@Around) 围绕方法执行

  ```java
  @Aspect//声明切面，标记类
  public class Audience
  
  @Pointcut("execution(* *.perform(..))")//定义切入点，标记方法
  public void performance(){}   
      
  @Before("performance()")//切点之前执行
  
  ```

  

### 9.9 SpringAOP应用场景

- 记录日志
- 监控方法运行时间 （监控性能）
- 权限控制
- 缓存优化 （第一次调用查询数据库，将查询结果放入内存对象， 第二次调用， 直接从内存对象返回，不需要查询数据库 ）
- 事务管理 （调用方法前开启事务， 调用方法后提交关闭事务 ）



### 9.10 AOP实现原理

动态代理：

Jdk代理：又叫接口代理

Cglib代理：又叫子类代理



### 9.11 Spring事务传播行为

| PROPAGATION_REQUIRED          | **如果当前没有事务，就新建一个事务，如果已经存在一个事务中，加入到这个事务中。这是最常见的选择。** |
| ----------------------------- | :----------------------------------------------------------- |
| **PROPAGATION_SUPPORTS**      | **支持当前事务，如果当前没有事务，就以非事务方式执行。**     |
| **PROPAGATION_MANDATORY**     | **使用当前的事务，如果当前没有事务，就抛出异常。**           |
| **PROPAGATION_REQUIRES_NEW**  | **新建事务，如果当前存在事务，把当前事务挂起。**             |
| **PROPAGATION_NOT_SUPPORTED** | **以非事务方式执行操作，如果当前存在事务，就把当前事务挂起。** |
| **PROPAGATION_NEVER**         | **以非事务方式执行，如果当前存在事务，则抛出异常。**         |
| **PROPAGATION_NESTED**        | **如果当前存在事务，则在嵌套事务内执行。如果当前没有事务，则执行与PROPAGATION_REQUIRED类似的操作。** |



### 9.12 @Transaction注解失效原因

- 在非public方法中
- 抛出的异常为checkedException，可以用rollbackFor来指定类型
- 异常提前被catch掉





## xx. 未归类

### 1.tomcat集群怎么保证同步

### 2.怎么解决超卖问题

### 3.mybaits二级缓存

Mybatis的一级缓存共享范围就是sqlSession内部，如果多个sqlsession需要共享缓存，则需要开启mybatis的二级缓存，二级缓存的区域是根据mapper的namespace划分的，如果两个mapper的namespace一样，那么他们就共享一个mapper缓存

 

开启方式：mybatis配置文件中配置cacheEnable=true同时在mapper中添加<cache>标签，并且pojo必须实现序列化接口

<cache>标签的属性：

eviction：缓存回收策略

Lru：最近最少使用对象回收

Fifo：先进先出

Soft：软引用先回收

Weak：弱引用先回收

flushinterval：缓存刷新间隔，默认不清空

readonly：是否只读，mybatis认为从缓存读取操作都是只读的，不会修改数据

size：缓存存放元素个数

type：自定义缓存的全类名

blocking：若缓存中不存在某个key，是否一直blocking，直到有数据存入

 

当然在同一个namespace中如果有insert、update、delete则需要更新缓存

<insert id="insertUser" parameterType="User" flushCache="true">