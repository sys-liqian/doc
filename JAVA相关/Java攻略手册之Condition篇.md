# Condition

​		等待通知机制

## await

```java
public abstract class AbstractQueuedSynchronizer
    extends AbstractOwnableSynchronizer {
    
    static final class Node {
        
        //表示该节点处于等待状态
        static final int CONDITION = -2;
        
        volatile int waitStatus;
        
        volatile Thread thread;
        
        Node nextWaiter;
        
        Node(Thread thread, int waitStatus) {
            this.waitStatus = waitStatus;
            this.thread = thread;
        }
        //...
    }
    
    public class ConditionObject implements Condition {
        
        //<---我在这里，从这里开始看
        public final void await() throws InterruptedException {
            if (Thread.interrupted())//如果当前线程已经中断，直接抛异常
                throw new InterruptedException();
            Node node = addConditionWaiter();//将当前线程添加到等待队列
            int savedState = fullyRelease(node);//释放当前节点持有的锁，失败会抛异常
            int interruptMode = 0;//中断标识，方便最后处理中断
            while (!isOnSyncQueue(node)) {//一旦当前节点退出等待队列就取消循环
                LockSupport.park(this);//阻塞
                if ((interruptMode = checkInterruptWhileWaiting(node)) != 0)//当前节点被标记中断后也可以退出循环
                    break;
            }
            if (acquireQueued(node, savedState)//阻塞式获取锁，详情参考《Java攻略手册之Lock篇》。
                && interruptMode != THROW_IE)
                interruptMode = REINTERRUPT;//夺锁过程中若被标记中断，就等到方法结束时再次将当前线程标记中断。
            if (node.nextWaiter != null)//若当前节点有后继节点就清洗一次等待队列，把该节点删除
                unlinkCancelledWaiters();
            if (interruptMode != 0)
                reportInterruptAfterWait(interruptMode);//处理中断
        }
        
        //将当前线程加入等待队列
        private Node addConditionWaiter() {
            Node t = lastWaiter;//等待队列尾节点
            if (t != null && t.waitStatus != Node.CONDITION) {//若尾节点不处于等待状态，就把所有非等待节点从等待队列中踢出去。
                unlinkCancelledWaiters();
                t = lastWaiter;//从新指定尾节点
            }
            Node node = new Node(Thread.currentThread(), Node.CONDITION);//new一个新节点，保存当前线程，等待状态设为-2。
            if (t == null)//若尾节点为null，说明等待队列未初始化，让头节点指向新节点，完成初始化。从这里我们能够知道等待队列不同于同步队列，等待队列不带头节点。
                firstWaiter = node;
            else//否则只需在尾节点后续接上新节点即可，从这里我们又知道了第二条讯息，等待队列是单向的。
                t.nextWaiter = node;
            lastWaiter = node;//把新节点设为新的尾节点
            return node;
        }
        
        //从等待队列中把已取消的节点删除
        //假如现在的等待如下，括号里表示节点的等待状态：
//        +------+    +-------+    +-------+    +------+    +-------+
//        | 0(1) |--->| 1(-2) |--->| 2(-2) |--->| 3(1) |--->| 4(-2) |
//        +------+    +-------+    +-------+    +------+    +-------+
        //从方法出来后就变成这样了：
//        +-------+    +-------+    +-------+
//        | 1(-2) |--->| 2(-2) |--->| 4(-2) |
//        +-------+    +-------+    +-------+
        private void unlinkCancelledWaiters() {
            Node t = firstWaiter;
            Node trail = null;
            while (t != null) {
                Node next = t.nextWaiter;
                if (t.waitStatus != Node.CONDITION) {
                    t.nextWaiter = null;
                    if (trail == null)
                        firstWaiter = next;
                    else
                        trail.nextWaiter = next;
                    if (next == null)
                        lastWaiter = trail;
                }
                else
                    trail = t;
                t = next;
            }
        }
        
        //表示await()方法结束后需再次将线程标记中断
        private static final int REINTERRUPT =  1;
        
        //表示await()方法结束后直接抛异常
        private static final int THROW_IE    = -1;
        
        //告诉await()怎样处理线程中断
        private int checkInterruptWhileWaiting(Node node) {
            return Thread.interrupted() ?
                (transferAfterCancelledWait(node) ? THROW_IE : REINTERRUPT) :
                0;//不处理
        }
        
        //处理中断
        private void reportInterruptAfterWait(int interruptMode)
            throws InterruptedException {
            if (interruptMode == THROW_IE)//若中断没有受signal(通知)影响就抛异常
                throw new InterruptedException();
            else if (interruptMode == REINTERRUPT)//若signal(通知)先于中断发生就重新标记中断
                selfInterrupt();//重新标记中断，详情参考《Java攻略手册之Lock篇》。
        }
        //...
    }
    
    //释放当前节点持有的锁，失败就将当前节点的等待状态标记为1(已取消)，并抛出异常。
    final int fullyRelease(Node node) {
        boolean failed = true;
        try {
            int savedState = getState();//获取锁状态
            if (release(savedState)) {//释放锁，详情参考《Java攻略手册之Lock篇》。
                failed = false;
                return savedState;
            } else {
                throw new IllegalMonitorStateException();
            }
        } finally {
            if (failed)
                node.waitStatus = Node.CANCELLED;
        }
    }
    
    //判断当前节点处不处于同步队列
    final boolean isOnSyncQueue(Node node) {
        if (node.waitStatus == Node.CONDITION || node.prev == null)//若当前节的等待状态等于-2，或者没有前驱节点(因为同步队列带头节点一定有前驱节点)，就说明它不在同步队列里。
            return false;
        if (node.next != null)//若当前节点后继有人说明它存在于同步队列，因为等待队列的后继引用是nextWaiter，next和prev都是同步队列的东西。
            return true;
        //node.prev有时候不为null，若该节点加入同步队列CAS失败时就会出现这种情况。这时只能去同步队列里循环判断了。
        return findNodeFromTail(node);
    }
    
    //从后向前遍历，探寻当前节点处不处于同步队列
    private boolean findNodeFromTail(Node node) {
        Node t = tail;
        for (;;) {
            if (t == node)
                return true;
            if (t == null)
                return false;
            t = t.prev;
        }
    }
    
    //判断中断是否在通知(signal)之后发生
    final boolean transferAfterCancelledWait(Node node) {
        if (compareAndSetWaitStatus(node, Node.CONDITION, 0)) {//CAS成功，说明中断发生后，并没受到signal搅合，因为signal操作的第一步也是compareAndSetWaitStatus(node, Node.CONDITION, 0)。
            enq(node);//加入同步队列，详情参考《Java攻略手册之Lock篇》。
            return true;//返回true，表示await()需要抛异常
        }
        //CAS失败并不能表示signal先于中断发生，只能说在CAS之前它俩都发生过了。此时AQS独断专行，强行认为signal先于中断发生，等到signal将node加入到同步队列后，返回false，告诉await()需再次将当前线程中断。
        while (!isOnSyncQueue(node))//一直等到signal将当前节点(node)加入到同步队列
            Thread.yield();//让出CPU一小会儿
        return false;//返回false，告诉await()再次将当前线程中断
    }
    //...
}
```

## signal

```java
public class ReentrantLock implements Lock {
    abstract static class Sync extends AbstractQueuedSynchronizer {
        
        //判断当前线程是否持有锁
        protected final boolean isHeldExclusively() {
            return getExclusiveOwnerThread() == Thread.currentThread();
        }
        //...
    }
    //...
}


public abstract class AbstractQueuedSynchronizer
    extends AbstractOwnableSynchronizer {
    
    public class ConditionObject implements Condition {
        
        //我在这里，从这里开始看
        public final void signal() {
            if (!isHeldExclusively())//当前线程没持有锁就抛异常
                throw new IllegalMonitorStateException();
            Node first = firstWaiter;//等待队列头节点
            if (first != null)
                doSignal(first);//真正的通知逻辑
        }
        
        //让等待队列的第一个等待节点加入同步队列去争取锁
//假如现在的等待队列是这样子，括号里是节点的等待状态：
//        +------+    +-------+    +-------+    +------+    +-------+
//        | 0(1) |--->| 1(-2) |--->| 2(-2) |--->| 3(1) |--->| 4(-2) |
//        +------+    +-------+    +-------+    +------+    +-------+
        //从方法出来后就变成这样了：
//        +-------+    +------+    +-------+
//        | 2(-2) |--->| 3(1) |--->| 4(-2) |
//        +-------+    +------+    +-------+
        private void doSignal(Node first) {
            do {
                if ( (firstWaiter = first.nextWaiter) == null)
                    lastWaiter = null;
                first.nextWaiter = null;
            } while (!transferForSignal(first)//判断当前节点是否已取消，没有就将它加入到同步队列
                     && (first = firstWaiter) != null);
        }
        //...
    }
    
    //将当前节点标记取消，并加入到同步队列
    final boolean transferForSignal(Node node) {
        if (!compareAndSetWaitStatus(node, Node.CONDITION, 0))//如果CAS失败，说明当前节点已经退出等待队列
            return false;

        Node p = enq(node);//将当前节点加入到同步队列，并返回前驱节点
        int ws = p.waitStatus;//前驱节点的等待状态
        if (ws > 0 || !compareAndSetWaitStatus(p, ws, Node.SIGNAL))//如果前驱节点已取消就释放当前节点
            LockSupport.unpark(node.thread);//唤醒
        return true;
    }
    //...
}
```

