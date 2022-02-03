

# 锁之呼吸

​		锁在并发编程中有着举足轻重的地位，因为它是保证多线程访问共享资源数据一致性的唯一办法。Java大陆中我们第一次接触到的锁是`synchronized`关键字，然后就是本期的主人公Lock接口。

​		Lock接口是 *Java1.5* 版本之后被引入的，来源于大名鼎鼎的 **J.U.C** 包下(即 `java.util.concurrent`)，接下来由鄙人**（漆黑炼焰使）**带领各位从Lock的实现类`ReentrantLock`入手，一层层揭开它的神秘面纱。*（掀起了你的盖头来，让我来亲亲你的脸(*￣3￣)╭）*

## 初入江湖(lock)

```java
import java.util.concurrent.locks.ReentrantLock;

public class ReentrantLockDemo {

    private static final ReentrantLock reentrantLock = new ReentrantLock();

    public static void main(String[] args) {
        new Thread(() -> {
            reentrantLock.lock();
            try {
                //do something
            } finally {
                reentrantLock.unlock();
            }
        }).start();
    }
}
```

​		废话不多说，这里我直接献上队友`ReentrantLock`的技能说明，相信大家看过之后应该有跟我一样的感受。使用`ReentrantLock`给资源上锁是一件如此让人心旷神怡的事情，此时好多程序猿不禁热泪盈眶，拍案叫绝。但作为一名合格的游戏攻略使，搜集彩蛋，发现隐藏剧情，才是游戏真正的乐趣。*（画外音：翻源码还被你说的这么清新脱俗）*

### 偶遇小虾米(ReentrantLock)

```java
public class ReentrantLock implements Lock {
    
    private final Sync sync;
    
    abstract static class Sync extends AbstractQueuedSynchronizer {
        abstract void lock();
        //...
    }
    
    static final class NonfairSync extends Sync {//非公平锁
        //...
    }
    
    static final class FairSync extends Sync {//公平锁
        //...
    }
    
    public ReentrantLock() {
        sync = new NonfairSync();//默认是非公平锁
    }
    
    public ReentrantLock(boolean fair) {
        sync = fair ? new FairSync() : new NonfairSync();//fair=true是公平锁,fair=false是非公平锁
    }
    
    public void lock() {
        sync.lock();//加锁
    }
    //...
}
```

​		上述是`ReentrantLock`部分源码，为了方便解释我只截取了一部分。首先`ReentrantLock`定义了一个`Sync`内部抽象类，还顺便完成两个`Sync`的实现类`NonfairSync`（非公平锁）和`FairSync`（公平锁）。

​		说到这里我有必要科普一下什么是公平锁和非公平锁？

​		公平锁就是排队，所有线程都只能去队尾排队。

​		非公平锁就是插队，所有线程先尝试抢锁，抢锁失败后再去队尾排队。

​		科普完之后我们继续看，`ReentrantLock`的加锁操作实际上是使用`sync.lock()`方法，而这个方法是`Sync`类里定义的抽象方法`abstract void lock()`，那么很明显，真正的宝箱`lock`肯定隐藏于`NonfairSync`和`FairSync`这两个实现类里。

我们先看`NonfairSync`。

### 天地不公(NonfairSync)

```java
public class ReentrantLock implements Lock {
    
    private final Sync sync;
    
    abstract static class Sync extends AbstractQueuedSynchronizer {
        abstract void lock();
        
        final boolean nonfairTryAcquire(int acquires) {
            final Thread current = Thread.currentThread();
            int c = getState();
            if (c == 0) {
                if (compareAndSetState(0, acquires)) {
                    setExclusiveOwnerThread(current);
                    return true;
                }
            }
            else if (current == getExclusiveOwnerThread()) {
                int nextc = c + acquires;
                if (nextc < 0)
                    throw new Error("Maximum lock count exceeded");
                setState(nextc);
                return true;
            }
            return false;
        }
        //...
    }
    
    static final class NonfairSync extends Sync {
        
        final void lock() {
            if (compareAndSetState(0, 1))
                setExclusiveOwnerThread(Thread.currentThread());
            else
                acquire(1);
        }
        
        protected final boolean tryAcquire(int acquires) {
            return nonfairTryAcquire(acquires);
        }
    }
    //...
}
```

​		完了歇菜了，这回看不懂了。此时肯定有不少观众盆友心里面浮现出徐大师的《八骏马》，嘴上骂骂咧咧道：“你小子TM一下子copy这么多英文字符有屁用，你问问老子有一句看懂的没？”。圣僧远道而来稍安勿躁，消消气，消消气。您没看懂主要怪我，我一激灵没copy全。

​		打铁还需自身硬，要想掌握锁之呼吸必须练好内家功法。小伙子我看你骨骼惊奇，一定是个练武的奇才，我这里有一本武林秘籍你要不要学啊？

## 山洞秘籍(AQS)

```java
public abstract class AbstractQueuedSynchronizer extends AbstractOwnableSynchronizer {
    
    private volatile int state;
    
    public final void acquire(int arg) {
        if (!tryAcquire(arg) &&
            acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
            selfInterrupt();
    }
    
    protected final boolean compareAndSetState(int expect, int update) {
        return unsafe.compareAndSwapInt(this, stateOffset, expect, update);
    }
    
    private static final Unsafe unsafe = Unsafe.getUnsafe();
    private static final long stateOffset;

    static {
        try {
            stateOffset = unsafe.objectFieldOffset
                (AbstractQueuedSynchronizer.class.getDeclaredField("state"));
            //...
        } catch (Exception ex) { throw new Error(ex); }
    }
    //...
}
```

这回copy的差不多了，什么？有的观众光着一膀子腱子肌，提着菜刀杀过来了？

“克里斯关下门！”

我按捺住心中的忐忑慢慢跟您说，不过在说之前我先给大伙儿灌输两个概念：

1. `AbstractQueuedSynchronizer`（同步器，简称AQS）是用来构建锁的基础类，它使用设计模式中的模板模式简化了锁操作，其中`acquire(arg)`方法内部调用了交由子类实现的`tryAcquire(arg)`方法。
2. AQS主要依赖`volatile int state`成员变量来控制同步状态。

我们一步步来，先看`NonfairSync`真正的`lock`方法，下述。

```java
static final class NonfairSync extends Sync {
        
    final void lock() {
        if (compareAndSetState(0, 1))//①
            setExclusiveOwnerThread(Thread.currentThread());//②
        else
            acquire(1);//③，注意这里传入的参数arg=1
    }
}
```

​		执行步骤①这行代码使用的是AQS中的下述代码，其作用是将AQS中的同步状态 *(state)* 用*CAS*的方式从0改为1，如果更改成功*（即 state=1）*AQS则认为执行`lock`方法的线程已经获取到锁，接着执行步骤②。

这里我顺便简单介绍一下什么是CAS？

Compare and Swap(CAS)，比较后替换，是CPU的一种无锁算法，说白了就是乐观锁。CPU通过`cmpxchg`指令对寄存器中的旧值(A)和内存中的原值(V)进行比较，当且仅当内存值(V)等于旧值(A)时，CPU才会使用原子操作将内存值(V)更新为新值(B)，否则不执行任何操作。对这一过程还不清楚的童鞋可以去了解Java的内存模型(JMM)，详情参考《Java攻略手册之volatile篇》。

```java
public abstract class AbstractQueuedSynchronizer extends AbstractOwnableSynchronizer {
    
    private volatile int state;//同步状态，我为了方便理解经常叫作锁状态

    protected final boolean compareAndSetState(int expect, int update) {
        //以CAS的方式改变int的值，stateOffset内存地址(V)，expect旧值(A)，update新值(B)，成功则返回true。
        return unsafe.compareAndSwapInt(this, stateOffset, expect, update);
    }
    
    private static final Unsafe unsafe = Unsafe.getUnsafe();
    private static final long stateOffset;

    static {
        try {
            //Unsafe类里的大部分方法都被native修饰，所以看不到源码，我也只能向大家口头解释一下它的作用。Unsafe是Java为我们提供的一个手动管理内存的类，而它的objectFieldOffset(field)方法可以返回成员变量的内存地址。
            stateOffset = unsafe.objectFieldOffset
                (AbstractQueuedSynchronizer.class.getDeclaredField("state"));
            //...
        } catch (Exception ex) { throw new Error(ex); }
    }
    //...
}
```

​		步骤②这行代码使用的是`AbstractOwnableSynchronizer`抽象类中的`setExclusiveOwnerThread(thread)`方法，这个方法其实只是将当前获得锁的Thread（线程）保存起来。

​		因为`Sync`继承`AbstractQueuedSynchronizer`，`AbstractQueuedSynchronizer`又继承`AbstractOwnableSynchronizer`，而`Sync`又是`ReentrantLock`中的一个成员变量，所以`ReentrantLock`这个锁中有`sync.exclusiveOwnerThread`这么一个成员变量保存着当前获取到锁的线程。

```java
public abstract class AbstractOwnableSynchronizer {
    private transient Thread exclusiveOwnerThread;

    //将当前获取锁的线程保存起来
    protected final void setExclusiveOwnerThread(Thread thread) {
        exclusiveOwnerThread = thread;
    }
    
    //返回当前获取锁的线程
    protected final Thread getExclusiveOwnerThread() {
        return exclusiveOwnerThread;
    }
}
```

步骤①如果更改失败，就得执行步骤③，而步骤③是AQS提供的方法，如下。其内部使用了子类（也就是`NonfairSync`）实现的`tryAcquire(arg)`方法，这与我之前说到的 **概念1** 不谋而合。

```java
public abstract class AbstractQueuedSynchronizer extends AbstractOwnableSynchronizer {
    
    public final void acquire(int arg) {
        if (!tryAcquire(arg)//④
            &&
            acquireQueued(addWaiter(Node.EXCLUSIVE), arg)//⑤
           )
            selfInterrupt();//⑥
    }
    //...
}
```

先不管步骤⑤和⑥，我们只看步骤④。

### 小试牛刀(tryAcquire)

```java
public class ReentrantLock implements Lock {
    
    private final Sync sync;
    
    abstract static class Sync extends AbstractQueuedSynchronizer {
        
        //非公平锁真正尝试占有锁的逻辑，目前这里的acquires=1，如有疑问请看步骤③
        final boolean nonfairTryAcquire(int acquires) {
            final Thread current = Thread.currentThread();//当前线程
            int c = getState();//获取AQS同步状态，这里不会出现脏读，因为state被volatile修饰，保证了可见性。
            if (c == 0) {//state=0表示锁目前处于空闲状态
                if (compareAndSetState(0, acquires)) {//尝试CAS更新同步状态。有小伙伴可能会有疑问，为啥state已经使用volatile了保证了可见性，这里还要使用CAS？这个问题问的好，说明你有真正思考问题，要解释这个问题不是一言两句就能说清楚的，我会在《Java攻略手册之volatile篇》再做解答。(彩蛋编号：Lock-2.1-A)
                    setExclusiveOwnerThread(current);//更新成功，保存当前线程
                    return true;//成功持有锁(state=1)
                }//聪明的你肯定也发现了，这段if代码不就是nonfairSync.lock()方法里的①②步骤吗？思考：为什么之前已经写过，这儿还要写一次？答案请参考：天下大同(FairSync)。
            }
            else if (current == getExclusiveOwnerThread()) {//当c!=0表示锁已经被某个线程占有。判断当前线程是不是就是那个占有锁的线程，ReentrantLock就是这样实现可重入锁的。
                int nextc = c + acquires;//记录重入次数
                if (nextc < 0)//保证锁状态不混乱，锁状态只有>=0，不存在<0的情况。
                    throw new Error("Maximum lock count exceeded");
                setState(nextc);//因为当前线程已经获取到锁了，所以没必要使用CAS
                return true;
            }
            return false;//夺锁失败
        }
        //...
    }
    
    static final class NonfairSync extends Sync {
        
        //我在这里，从这里开始看
        protected final boolean tryAcquire(int acquires) {
            return nonfairTryAcquire(acquires);//调用Sync实现的nonfairTryAcquire方法，也就是说NonfairSync的tryAcquire方法其实Sync内部已经实现了。
        }
        //...
    }
    //...
}

public abstract class AbstractQueuedSynchronizer extends AbstractOwnableSynchronizer {
    
    private volatile int state;
    
    //就是单纯的get方法
    protected final int getState() {
        return state;
    }
    
    //也是单纯的set方法
    protected final void setState(int newState) {
        state = newState;
    }
    //...
}
```

​		能看到这儿我不得不恭喜您，能在我如此不遗余力贴源码的情况下读到现在，说明您还是挺努力的。大部分程序员只要愿意其实都能读懂源码，但是往往很多人选择半途而废。不过我也不得不告诉您一个残酷的现实，有关`ReentrantLock`上锁的过程我们只进行了一半，后面的路更荆棘。如果你没有面对Boss的勇气，一听到Boss的BGM就忍不住战栗，那我劝你看视频云通关就好。

​		“学而不思则罔，思而不学则殆”，说到这儿，我们不妨停一停。前面的代码不管 *Doug Lea* 大神（J.U.C包的作者）写的多么巧夺天工，说破天了也只是将锁状态 *(state)* 从0改到1，与加锁一点意义都没有。那么他又是如何保证同一时间只能有一个线程持有锁的呢？我们继续看步骤⑤和⑥。

​		步骤④如果夺锁成功便直接结束，但如果没有得到锁就得先执行步骤⑤。而步骤⑤的第一个操作就是`Node.EXCLUSIVE`，所以要了解AQS夺取锁失败的后续流程，首先就得先了解它的内部类`Node`。

### 结伴同行(Node)

```java
public abstract class AbstractQueuedSynchronizer extends AbstractOwnableSynchronizer {

    private transient volatile Node head;
    
    private transient volatile Node tail;

    static final class Node {

        volatile Node prev;

        volatile Node next;

        volatile Thread thread;

        Node(Thread thread, Node mode) {
            this.nextWaiter = mode;
            this.thread = thread;
        }
        //...
    }
    //...
}
```

​		大家看到这个节构是不是有一种似曾相识的感觉？这不就是`LinkedList`的底层，链表它老人家吗？How old are you?（怎么老是你）

​		没错，其实AQS就是把没有获取到锁的线程保存在一个链表里面，而这个链表就是那些倚老卖老的程序员经常挂在嘴边的同步队列（嘿嘿，所以我将这章起名为结伴同行，太有才了！），好吧，我们静下心来梳理这个队列。

  1. 这是一个双向队列，有前驱结点`prev`以及后继结点`next`。

  2. 这个队列是有头结点的。抱歉，如果只根据上面的代码您是看不出来这点的（那个谁谁谁把你手里的板砖放下）。接下来我将带领大家认识什么是带头结点的队列，以及为什么要带头结点？答案请参考[BOSS战](#BOSS战(park))。（彩蛋编号：Lock-2.2-A）

我们先看`addWaiter(mode)`方法，带图解的唔~

```java
public abstract class AbstractQueuedSynchronizer extends AbstractOwnableSynchronizer {

    private transient volatile Node head;
    
    private transient volatile Node tail;

    static final class Node {
        
        static final Node EXCLUSIVE = null;
        
        //表示该节点由于超时或中断已被取消
        static final int CANCELLED =  1;

        //表示该结点的后继结点已被（或即将被）阻塞，用来提醒该结点在释放或取消时必须唤醒其后继结点
        static final int SIGNAL    = -1;
        
        volatile int waitStatus;

        volatile Node prev;

        volatile Node next;

        volatile Thread thread;

        Node() {
        }

        Node(Thread thread, Node mode) {
            this.nextWaiter = mode;
            this.thread = thread;
            //this.waitStatus = 0;
        }
        //...
    }

    //我在这里，从这里开始看，mode=null
    private Node addWaiter(Node mode) {
        Node node = new Node(Thread.currentThread(), mode);//new了一个新结点，并将当前线程保存下来，也就是夺锁失败的线程。
        Node pred = tail;//同步队列尾结点，被volatile修饰保证了可见性
        if (pred != null) {//若尾结点不为null，说明之前有其它倒霉线程也没抢到锁
            node.prev = pred;//让新结点的前驱指向同步队列的尾结点，如下图所示。（题外话：如果屏幕不够宽这种图可能会很难看）
//                     prev          prev           prev
//          +------+  <----+-----+  <----+------------+  <----+-----+
//          | head |       |     |       | pred(tail) |       | new |
//          +------+---->  +-----+---->  +------------+       +-----+
//                  next          next
            if (compareAndSetTail(pred, node)) {//使用CAS尝试将同步队列的尾结点的引用指向新结点，如下图。注意：这个地方只是把tail的引用指向新结点(new)，并没有改pred的引用，至于原因请看下面对compareAndSetTail方法的解释。而使用CAS就是避免多线程竞争，导致有的线程没有被正确的加入到同步队列中去，如果这句话不好理解请参考后续。（彩蛋编号：Lock-2.2-B）
//                     prev          prev           prev
//          +------+  <----+-----+  <----+------+  <----+-----------+
//          | head |       |     |       | pred |       | new(tail) |
//          +------+---->  +-----+---->  +------+       +-----------+
//                  next          next
                pred.next = node;//让同步队列过去尾结点的后继指向新结点，注意过去二字，因为真正的尾结点在上一步已经成为新结点了，如下图。
//                     prev          prev           prev
//          +------+  <----+-----+  <----+------+  <----+-----------+
//          | head |       |     |       | pred |       | new(tail) |
//          +------+---->  +-----+---->  +------+---->  +-----------+
//                  next          next           next
                return node;//返回新结点
            }
        }
        enq(node);//若尾结点为null，说明同步队列为null，此时需要初始化同步队列。若尾结点不为null，但是CAS尝试失败（即：compareAndSetTail(pred, node)），说明多线程存在竞争需要重新加入尾结点。
        return node;
    }

    //这个方法主要是为了将新结点以安全的方式(CAS)加入到同步队列尾，直到成功
    private Node enq(final Node node) {
        for (;;) {//死循环，直到成功加入同步队列
            Node t = tail;//同步队列尾结点
            if (t == null) {//若尾结点为null，表示同步队列为null，需要初始化。
                if (compareAndSetHead(new Node()))//以CAS方式将一个空结点加入到同步队列的头结点，若成功则初始化完成，若失败就继续循环。头结点是空对象的这种队列我们称之为带头结点的队列，终于对上了。
                    tail = head;//同步队列的尾结点也指向头结点，循环继续。
            } else {//若同步队列初始化完成，又或许是之前的方法（即：compareAndSetTail(pred, node)）新结点加入同步队列失败，就会进入这段代码。注意观察应该不难发现，这段代码我们刚刚研究过，就是我画的那些鬼画符，除了返回不一样，其余一模一样。注意：这个地方返回的结点其实是当前同步队列倒数第二个结点。
                node.prev = t;
                if (compareAndSetTail(t, node)) {
                    t.next = node;
                    return t;
                }
            }
        }
    }
    
    /**下面的代码就是CAS改变具体值的方法，因为被native修饰，所以看不到源码，就算看到我也看不懂QAQ。**/

    private static final Unsafe unsafe = Unsafe.getUnsafe();
    private static final long headOffset;
    private static final long tailOffset;

    static {
        try {
            headOffset = unsafe.objectFieldOffset
                    (AbstractQueuedSynchronizer.class.getDeclaredField("head"));
            //tailOffset绑定tail内存地址的代码在这
            tailOffset = unsafe.objectFieldOffset
                    (AbstractQueuedSynchronizer.class.getDeclaredField("tail"));
            //...
        } catch (Exception ex) {
            throw new Error(ex);
        }
    }

    private final boolean compareAndSetHead(Node update) {
        return unsafe.compareAndSwapObject(this, headOffset, null, update);
    }

    private final boolean compareAndSetTail(Node expect, Node update) {
        //这里的tailOffset是tail的内存地址，而expect只是为了输入旧值用于CAS对比，并不会对expect本身有任何修改。
        return unsafe.compareAndSwapObject(this, tailOffset, expect, update);
    }
    //...
}
```

现在没有获取到锁的线程已经被安全的加入到同步队列中去了，但也只是如此，还是没锁啥事情啊？我们带着这样的疑问继续看......

### BOSS战(park)

```java
public abstract class AbstractQueuedSynchronizer extends AbstractOwnableSynchronizer {
    
    static final class Node {
        
        //返回当前结点的前驱结点，不存在就抛异常
        final Node predecessor() throws NullPointerException {
            Node p = prev;
            if (p == null)
                throw new NullPointerException();
            else
                return p;
        }
        //...
    }

    //我在这里，从这里开始看
    //该方法会一直自旋尝试获取锁，直至成功
    final boolean acquireQueued(final Node node, int arg) {
        boolean failed = true;
        try {
            boolean interrupted = false;
            for (;;) {
                final Node p = node.predecessor();//该结点(node)的前驱结点
                if (p == head && tryAcquire(arg)) {//如果该结点的前驱结点刚好是头结点，那么就让该结点尝试获取一次锁，我以后会将这种结点称作首元结点。
                    setHead(node);//获取锁成功，就将首元结点升级为头结点
                    p.next = null;//随后将过去的头结点的后继结点指向null，可以认为将过去的头结点与同步队列断开。
                    failed = false;
                    return interrupted;//返回false，告诉步骤⑥没必要处理线程中断的情况
                }
                if (shouldParkAfterFailedAcquire(p, node)//再次判断该结点是否需要阻塞
                    &&
                    parkAndCheckInterrupt()//若需要，直接阻塞
                   )
                    interrupted = true;
            }//总节一下这个死循环干的三件事：
             //1. 如果当前结点(node)是首元结点，让它尝试获取锁；
             //2. 如果当前结点不是首元结点，那么它的前驱结点凡是已取消的都会被删除，删除干净后将新的前驱结点等待状态改为-1；
             //3. 一旦前驱结点的等待状态被改为-1后，当前结点会第二次进入循环，若仍没持有锁，那就直接阻塞。
             //彩蛋编号Lock-4-A：其实这个死循环还干了第4件事：已阻塞的结点被唤醒时(unpark)，它将从parkAndCheckInterrupt()方法苏醒过来，再次循环去争取锁，夺锁成功顺便把早已获得过锁的结点（头结点）从同步队列中删除。如此既更新了同步队列，也保证了一个线程不管之前有没有被阻塞，在它走出lock()方法后一定持有了锁。如果你现在还理解不了，我建议你先把这篇文章都看完，最后回过头来再去思考这个问题。
        } finally {
            if (failed)//只要代码运行正常cancelAcquire(node)永远也不会被执行到，一旦发生异常就需要进一步处理了。那么什么情况下会抛异常呢？
                //情况有两种：
                //1. node.predecessor()，抛出NullPointerException异常等于无事发生；
                //2. tryAcquire(arg)，如果是尝试获取锁异常，说明锁状态混乱（state<0说白了就是这把锁已经失效了），需要将该结点从同步队列中踢出去。
                cancelAcquire(node);
        }
    }
    
    //这个方法的主要目的是为了判断当前结点(node)是否需要阻塞，顺便对它的前驱结点(pred)做一些处理
    private static boolean shouldParkAfterFailedAcquire(Node pred, Node node) {
        int ws = pred.waitStatus;//前驱结点的等待状态
        if (ws == Node.SIGNAL)//若前驱结点的等待状态waitStatus=-1，标志着当前结点(node)应该被阻塞。
            return true;
        if (ws > 0) {//如果前驱结点的状态waitStatus>0，标志着前驱结点由于超时或中断已被取消，那么便将前驱结点从同步队列中移除，直到没有这样的前驱结点。
            do {
                node.prev = pred = pred.prev;
            } while (pred.waitStatus > 0);
            pred.next = node;
        } else {//每个结点的最终目的是让它的前驱结点状态变为-1，用来表示前驱结点释放锁后记得唤醒它去竞争锁。
            compareAndSetWaitStatus(pred, ws, Node.SIGNAL);
        }
        return false;//表示该结点需要继续尝试获取锁
    }
    
    //阻塞当前线程
    private final boolean parkAndCheckInterrupt() {
        LockSupport.park(this);//阻塞当前线程，这才是保证多线程同一时刻只能有一个线程访问临界资源的罪魁祸首。LockSupport类里大部分调用的都是Unsafe，看不到源码。
        return Thread.interrupted();//返回当前线程的中断状态
    }
    
    //发生异常，将该结点移除同步队列
    private void cancelAcquire(Node node) {
        if (node == null)
            return;

        node.thread = null;//把该结点保存的线程删除

        Node pred = node.prev;//前驱结点
        while (pred.waitStatus > 0)//这个循环似曾相识，shouldParkAfterFailedAcquire(pred, node)方法里面也有。
            node.prev = pred = pred.prev;

        Node predNext = pred.next;//注意这个predNext有可能不是当前节点(node)，上面的循环只是针对node结点的前驱结点做替换，而它们的后继结点一个没变，如图。
//  +------+ <---+-----------------+ <---------------------------------------------------------+------+
//  |      |     |     pred        | <---+------------------------+ <---+----------------+     |      |
//  | head |     | (waitStatus=-1) |     | predNext(waitStatus=1) |     | (waitStatus=1) |     | node |
//  +------+---> +-----------------+---> +------------------------+---> +----------------+---> +------+

        node.waitStatus = Node.CANCELLED;//由于该结点异常，所以将该结点的等待状态改为已取消(waitStatus=1)，方便后继结点执行shouldParkAfterFailedAcquire(pred, node)时干掉它。

        //彩蛋编号Lock-2.2-A：
        //通过后面这部分代码不难发现，在删除结点时，作者并没有特意处理头结点，这就是链表带头结点的好处，降低了代码的复杂度。
        if (node == tail && compareAndSetTail(node, pred)) {//如果该结点是尾结点需要重新指定尾结点
            compareAndSetNext(pred, predNext, null);//尾结点维护完成再将尾结点(pred)的后继结点删除。思考为啥shouldParkAfterFailedAcquire(pred, node)方法里面直接pred.next = node，而这里却需要CAS？答案请参考后续。（彩蛋编号：Lock-2.3-B）
        } else {//如果该结点不是尾结点，又或许是在维护尾结点时失败了，就跳过该结点，去连接它的后继结点。造成尾结点维护失败的原因如下：
//线程A马上要执行compareAndSetTail(node, pred)之前的队列情况如下：
//          +------+  <----+-----+  <----+------+  <----+------------+
//          | head |       |     |       | pred |       | node(tail) |
//          +------+---->  +-----+---->  +------+---->  +------------+
//此时线程B执行完addWaiter(mode)方法加入了新的等待结点(如下)，造成CAS失败。
//          +------+  <----+-----+  <----+------+  <----+------+  <----+-----------+
//          | head |       |     |       | pred |       | node |       | new(tail) |
//          +------+---->  +-----+---->  +------+---->  +------+---->  +-----------+
            int ws;
            if (pred != head &&
                ((ws = pred.waitStatus) == Node.SIGNAL ||
                 (ws <= 0 && compareAndSetWaitStatus(pred, ws, Node.SIGNAL))) &&
                pred.thread != null) {
                Node next = node.next;
                if (next != null && next.waitStatus <= 0)//如果后继结点没有被取消，就让后继结点提前。
                    compareAndSetNext(pred, predNext, next);
            } else {//如果前驱是头节点，又或许前驱结点已取消，则需唤醒该结点的后继结点
                unparkSuccessor(node);
            }

            node.next = node;//这个结点已经被同步队列抛弃，虽然它的前驱还指向同步队列，但同步队列已经没有引用指向它了，不久便会被GC清除。
        }
    }
    
    //唤醒该结点的后继结点，如果它没有后继结点则去唤醒等待时间最长的结点。
    private void unparkSuccessor(Node node) {
        int ws = node.waitStatus;
        if (ws < 0)
            compareAndSetWaitStatus(node, ws, 0);//将该结点的等待状态改为0，表示它是新结点（waitStatus=0是新结点入队时的默认状态）。对于cancelAcquire(node)方法其实这行代码可有可无，反正该结点迟早被GC清理。但这行代码会在解锁操作(unlock)中被赋予意义，unlock会唤醒同步队列的首元结点，此时这行代码会将头结点的等待状态改为0，若被唤醒的首元结点尝试获取锁失败了（非公平锁有其他线程插队成功），就能通过shouldParkAfterFailedAcquire(pred, node)方法将头结点的等待状态改为-1，再次阻塞首元结点。
        
        Node s = node.next;
        //如果该结点是尾结点，或者该结点的后继结点已取消，就从同步队列尾一直向前遍历，直到找到排在队列最前面处于阻塞状态的结点（等待时间最长的结点）。
        if (s == null || s.waitStatus > 0) {
            s = null;
            for (Node t = tail; t != null && t != node; t = t.prev)
                if (t.waitStatus <= 0)
                    s = t;
        }
        if (s != null)
            LockSupport.unpark(s.thread);//唤醒后继结点，如果存在
    }
    
    //将该结点设置为头结点
    private void setHead(Node node) {
        head = node;//将该结点提前成头结点
        node.thread = null;//把该结点保存的线程删除
        node.prev = null;//将该结点与前驱结点断开
    }
    
    private static final Unsafe unsafe = Unsafe.getUnsafe();
    private static final long waitStatusOffset;

    static {
        try {
            waitStatusOffset = unsafe.objectFieldOffset
                (Node.class.getDeclaredField("waitStatus"));
            //...
        } catch (Exception ex) { throw new Error(ex); }
    }
    
    private static final boolean compareAndSetWaitStatus(Node node,
                                                         int expect,
                                                         int update) {
        return unsafe.compareAndSwapInt(node, waitStatusOffset,
                                        expect, update);
    }
    //...
}
```

## lock线（终）

`ReentrantLock`加锁的所有逻辑我们已经阅读完毕，总结一下*BOSS*的战斗阶段：

第一阶段：当前线程尝试占有锁
第二阶段：抢锁失败的线程将被加入同步队列进行阻塞
第三阶段：当前线程自旋抢锁时一旦发生异常就会被移出同步队列

趁热打铁我们只剩最后一行代码了，请看步骤⑥。

```java
public abstract class AbstractQueuedSynchronizer extends AbstractOwnableSynchronizer {
    
    public final void acquire(int arg) {
        if (!tryAcquire(arg)//④
            &&
            acquireQueued(addWaiter(Node.EXCLUSIVE), arg)//⑤
           )
            selfInterrupt();//⑥
    }
    
    static void selfInterrupt() {
        Thread.currentThread().interrupt();//将当前线程标记中断，如果您对线程的标记中断不了解请参考《Java攻略手册之Thread篇》。
    }
    //...
}
```

​		步骤⑥无非是当前线程在被唤醒后发现自己被标记了中断，隐忍不发等到步骤⑤执行完成后则再次将自己标记中断罢了。

​		解释一下什么是标记中断？当线程*(ThreadA)*内部执行了`wait()`等方法被阻塞后，其他线程*(ThreadB)*执行`ThreadA.interrupt()`方法就能让*ThreadA*退出阻塞并抛异常，标记中断并不能真正的让线程停下来，只是单纯的将线程的中断状态*(interrupt)*改为true而已。

​		自此，我们终于将`lock`线的结局真正通关了，可喜可贺。玩游戏全收集的确很累，一路走来感谢您的陪伴！不过我们之间的故事并没有结束，我将在`unlock`旅程中等待您的到来......

### 天下大同(FairSync)

​		我好像遗漏了点什么？阿巴阿巴，说了一大堆，把公平锁忘了，罪该万死。为了表达我的歉意，我们玩玩小游戏《找不同》。

```java
public class ReentrantLock implements Lock {
    
    private final Sync sync;
    
    abstract static class Sync extends AbstractQueuedSynchronizer {
        abstract void lock();
        //...
    }
    
    static final class FairSync extends Sync {
        
        final void lock() {
            //if (compareAndSetState(0, 1))
            //    setExclusiveOwnerThread(Thread.currentThread());
            //else
            acquire(1);//不同点①，少了一步插队操作，如上注释。
        }

        protected final boolean tryAcquire(int acquires) {
            final Thread current = Thread.currentThread();
            int c = getState();
            if (c == 0) {
                if (!hasQueuedPredecessors()//不同点②，如果在此之前已经有结点排队了，就直接排队去吧。
                    &&
                    compareAndSetState(0, acquires)) {
                    setExclusiveOwnerThread(current);
                    return true;
                }
            }
            else if (current == getExclusiveOwnerThread()) {
                int nextc = c + acquires;
                if (nextc < 0)
                    throw new Error("Maximum lock count exceeded");
                setState(nextc);
                return true;
            }
            return false;
        }
    }
    //...
}


public abstract class AbstractQueuedSynchronizer extends AbstractOwnableSynchronizer {
    
    //判断同步队列中有没有结点
    public final boolean hasQueuedPredecessors() {
        Node t = tail;
        Node h = head;
        Node s;
        return h != t &&
            ((s = h.next) == null || s.thread != Thread.currentThread());
    }
    //...
}
```

## 再续前缘(unlock)

​		二周目我们尝试另一种结局，其实走过`lock`线的诸位我倒是不建议再继续看下去了，你已经长大了，脚下的路得自己走。

```java
public class ReentrantLock implements Lock {
    
    private final Sync sync;
    
    abstract static class Sync extends AbstractQueuedSynchronizer {
        
        //尝试释放锁，releases=1
        protected final boolean tryRelease(int releases) {
            int c = getState() - releases;//锁被持有的状态为1，锁空闲的状态是0，所以直接减。
            if (Thread.currentThread() != getExclusiveOwnerThread())//如果当前线程没持有锁就抛异常
                throw new IllegalMonitorStateException();
            boolean free = false;
            if (c == 0) {//如果锁状态为0，表示锁释放成功
                free = true;
                setExclusiveOwnerThread(null);//删除锁保存的线程
            }
            setState(c);//保存锁状态，因为当前线程必定持有锁，不存在竞争，所以没有CAS的必要。
            return free;//如果锁状态不为0，表示锁释放失败
        }
        //...
    }
    
    //我在这里，从这里开始看
    public void unlock() {
        sync.release(1);
    }
    //...
}


public abstract class AbstractQueuedSynchronizer extends AbstractOwnableSynchronizer {
    
    //真正释放锁的逻辑
    public final boolean release(int arg) {
        if (tryRelease(arg)) {//尝试释放锁，若释放成功别忘记唤醒同步队列里的首元结点
            Node h = head;
            if (h != null && h.waitStatus != 0)
                unparkSuccessor(h);//唤醒等待时间最长的结点（首元结点），这个方法我们之前讨论过，老朋友了。
            return true;
        }
        return false;//释放锁失败直接返回false
    }
    //...
}
```

​		哈哈，有木有一种被我欺骗的感脚？有木有一种怅然若失的感脚？╰(*°▽°*)╯是滴，这些方法你都见过，就算连起来我们也看的懂。So Easy，妈妈再也不用担心我的学习。

​		可惜，直到现在你还不能放弃思考，仔细想一想，`unlock()`方法只是改变了锁状态，也顺便唤醒了后继结点。问题是，后继结点如何再次争取锁的？后继结点又是怎么把它的前驱结点（即已经获取过锁的僵尸结点）从同步队列中删除的？答案请参考[BOSS战](#BOSS战(park))。（彩蛋编号：Lock-4-A）

## 后续

​		看到后续还再死撑的肯定是真爱了，你绝对是那种电影看完还窝着不走等着放彩蛋的人，绝对是！好吧，星爷曾说：“只有大片才有彩蛋”，为了响应号召我就大言不惭的加点彩蛋。

​		注意：AQS的`acquire(arg)`方法是独占式获取同步状态，简称独占锁。独占锁不知道总知道排它锁吧，排它锁不知道总知道写锁吧，什么？你什么都不知道？......我建议你先别看AQS了，有时间不如去学数据库(T_T)。有独占就有共享，有关共享锁的源码我就不陪伴大家了(因为懒)，有兴趣的童鞋可自行观看`ReentrantReadWriteLock`读写锁。

​		我们有缘再见，拜拜~

### 彩蛋编号Lock-2.2-B：

```java
private Node addWaiter(Node mode) {
    Node node = new Node(Thread.currentThread(), mode);
    
    Node pred = tail;
    if (pred != null) {
        node.prev = pred;//①
        if (compareAndSetTail(pred, node)) {//② 假如不使用CAS，直接写成这样：tail = node，我们看看会发生什么问题。
            pred.next = node;//③
            return node;
        }
    }
    enq(node);
    return node;
}
//假设此时有两个线程同时执行步骤①，如图所示。
//                                              +-------+----------+
//                                              |prev   | Thread-2 |
//                                              v       +----------+
//                     prev          prev           prev
//          +------+  <----+-----+  <----+------+  <----+----------+
//          | head |       |     |       | pred |       | Thread-1 |
//          +------+---->  +-----+---->  +------+       +----------+
//                  next          next
//之后Thread-1没有执行步骤②，而是走了我写的代码 tail = node;
//                                              +-------+----------+
//                                              |prev   | Thread-2 |
//                                              v       +----------+
//                     prev          prev           prev
//          +------+  <----+-----+  <----+------+  <----+----------------+
//          | head |       |     |       | pred |       | Thread-1(tail) |
//          +------+---->  +-----+---->  +------+       +----------------+
//                  next          next
//Thread-1紧接着执行步骤③，目前看起来并没什么问题
//                                              +-------+----------+
//                                              |prev   | Thread-2 |
//                                              v       +----------+
//                     prev          prev           prev
//          +------+  <----+-----+  <----+------+  <----+----------------+
//          | head |       |     |       | pred |       | Thread-1(tail) |
//          +------+---->  +-----+---->  +------+---->  +----------------+
//                  next          next           next
//这时候Thread-2开始搞事情了，执行我的 tail = node;
//                                              +-------+----------------+
//                                              |prev   | Thread-2(tail) |
//                                              v       +----------------+
//                     prev          prev           prev
//          +------+  <----+-----+  <----+------+  <----+----------+
//          | head |       |     |       | pred |       | Thread-1 |
//          +------+---->  +-----+---->  +------+---->  +----------+
//                  next          next           next
//最后Thread-2执行步骤③
//                                              +-------+----------------+
//                                              |prev   | Thread-2(tail) |
//                                              v    +> +----------------+
//                     prev          prev           X
//          +------+  <----+-----+  <----+------+  X  <----+----------+
//          | head |       |     |       | pred | X        | Thread-1 |
//          +------+---->  +-----+---->  +------++         +----------+
//                  next          next           next
//从上述图例可以看出，Thread-1最终并没有加入到同步队列中，而是被Thread-2顶替了，导致Thread-1没有被正确的加入到同步队列中去。
```

### 彩蛋编号Lock-2.3-B：

```java
private static boolean shouldParkAfterFailedAcquire(Node pred, Node node) {
    int ws = pred.waitStatus;
    if (ws == Node.SIGNAL)
        return true;
    if (ws > 0) {
        do {
            node.prev = pred = pred.prev;
        } while (pred.waitStatus > 0);
        pred.next = node;//①
    } else {
        compareAndSetWaitStatus(pred, ws, Node.SIGNAL);
    }
    return false;
}

private void cancelAcquire(Node node) {
    if (node == null)
        return;

    node.thread = null;

    Node pred = node.prev;
    while (pred.waitStatus > 0)
        node.prev = pred = pred.prev;

    Node predNext = pred.next;

    node.waitStatus = Node.CANCELLED;

    if (node == tail && compareAndSetTail(node, pred)) {//②
        compareAndSetNext(pred, predNext, null);//③
    } else {
        int ws;
        if (pred != head &&
            ((ws = pred.waitStatus) == Node.SIGNAL ||
             (ws <= 0 && compareAndSetWaitStatus(pred, ws, Node.SIGNAL))) &&
            pred.thread != null) {
            Node next = node.next;
            if (next != null && next.waitStatus <= 0)
                compareAndSetNext(pred, predNext, next);
        } else {
            unparkSuccessor(node);
        }

        node.next = node;
    }
}

//为什么同样的操作，步骤①和步骤③有着截然相反的待遇？（提示：问题切入点可以从步骤②里面的这个判断入手 node == tail）
//步骤①虽然没有CAS控制，但是每个线程只能控制自己所处的结点，删除自己所处结点的前驱结点，每个结点各司其职，不存在相互竞争；
//而步骤③控制的可是同步队列的尾结点，这个结点容易被addWaiter(mode)方法更新，受新增结点控制，所以只能交由CAS控制。
```

