---
title: redis总结
categories:
  - 后端
  - Redis
tags:
  - 面试
comments: true
toc: true
abbrlink: 90bec65a
date: 2019-02-27 20:49:03
---
#  Redis为什么那么快

1. 纯内存操作
2. 单线程操作，避免了频繁的上下文切换
3. 采用了非阻塞I/O多路复用机制

我们的redis-client在操作的时候，会产生具有不同事件类型的socket。在服务端，有一段I/0多路复用程序，将其置入队列之中。然后，文件事件分派器，依次去队列中取，转发到不同的事件处理器中。

--------------------

# Redis数据类型({% post_link Redis/单线程的redis为什么快 [底层数据]%})

1. String,Hash,List,Set,SortedSet
1. Pub/Sub
2. HyperLogLog(2.8.9版本新增):用来做基数统计的算法，HyperLogLog 的优点是，在输入元素的数量或者体积非常非常大时，计算基数所需的空间总是固定 的、并且是很小的。使用场景最常见的就是计算网站UV等，对数据精度要求不高
3. Geo（3.2版本新增）：GEO(地理位置)的支持，主要是对经纬度一个位置计算等特性
4. BitMap
5. BloomFilter 
![data-struct](http://ww2.sinaimg.cn/large/0078bOVFgy1g0n97yi9czj30a504hjri.jpg)
![data-struct](http://ww2.sinaimg.cn/large/0078bOVFgy1g0n991tb0hj30rp0cqmyi.jpg)

--------------------

# Redis的过期策略以及内存淘汰机制

1.  三种过期策略
    - 定时删除：在设置键的过期时间的同时，创建一个定时器(timer)，让定时器在键的过期时间来临时，立即执行对键的删除操作；
    - 惰性删除：放任键过期不管，但是每次从键空间中获取键时，都检查取得的键是否过期，如果过期的话，就删除该键；如果没有过期，那就返回该键；
    - 定期删除：每隔一段时间，程序就对数据库进行一次检查，删除里面的过期键。至于删除多少过期键，以及要检查多少个数据库，则由算法决定。

Redis采用的是定期删除+惰性删策略。  

    为什么不用定时删除策略？定时删除策略需要定时器来监视key，过期则自动删除。虽然内存及时释放了，但是CPU消耗大。在大并发的情况下，这一策略得不偿失

Redis采用的是定期删除+惰性删策略工作机制。  

    定期删除，redis默认每100ms检查一次是否存在过期key，有则删除。需要说明的是redis并不是100ms检查所有的key一次，而是随机进行抽取检查。因此，惰性删除派上用处。

惰性删策略延伸出来的问题就是，redis缓存淘汰机制

2.  Redis(3.0版本)6种缓存淘汰机制
    1.  no-enviction(驱逐)：禁止驱逐数据（不删除数据策略，达到最大的内存限制时，如果有更多的数据写入，返回错误给客户端）
    2.  allkeys-lru：所有key通用，优先删除最少使用的key（less recently used,LRU算法）
    3.  allkeys-random ：所有key通用，随机删除一部分key
    4.  volatile-lru：只限于设置了expire的部分，优先删除最少使用的key（less recently used,LRU算法）
    5.  volatile-random：只限于设置了 expire 的部分; 随机删除一部分key
    6.  volatile-ttl：只限于设置了 expire 的部分; 优先删除剩余时间(time to live,TTL) 短的key。

**注意：如果没有设置 expire 的key, 不满足先决条件(prerequisites); 那么 volatile-lru, volatile-random 和 volatile-ttl 策略的行为, 和 noeviction(不删除) 基本上一致。**

一般来说：如果分为热数据与冷数据, 推荐使用allkeys-lru策略。 也就是, 其中一部分key经常被读写. 如果不确定具体的业务特征, 那么allkeys-lru是一个很好的选择。 如果需要循环读写所有的key, 或者各个key的访问频率差不多, 可以使用allkeys-random策略, 即读写所有元素的概率差不多。  

假如要让 Redis 根据 TTL 来筛选需要删除的key, 请使用volatile-ttl策略。

--------------------

# Redis持久化原理

1.  快照（特点：bgsave做镜像全量持久化）
    缺省情况下，Redis把数据快照存放在磁盘上的二进制文件中，文件名为dump.rdb。你可以配置Redis的持久化策略，例如数据集中每N秒钟有超过M次更新，就将数据写入磁盘；或者你可以手工调用命令SAVE或BGSAVE。
    工作原理:
      1.  主进程开启一个 Redis forks（子进程）.
      2.  子进程开始将数据写到临时RDB文件中。
      3.  当子进程完成写RDB文件，用新文件替换老文件。
      4.  bgsave的原理是什么？你给出两个词汇就可以了，fork和cow。fork是指redis通过创建子进程来进行bgsave操作，cow指的是copy on write，子进程创建后，父子进程共享数据段，父进程继续提供读写服务，写脏的页面数据会逐渐和子进程分离开来。

    ![fork](http://ww2.sinaimg.cn/large/0078bOVFgy1g0mlshrku0j30gn053gm7.jpg)

2.  AOF（特点：AOF增量持久化）

    AOF持久化以日志的形式记录服务器所处理的每一个写、删除操作，查询操作不会记录，以文本的方式记录，可以打开文件看到详细的操作记录。 

    ![aof](http://ww2.sinaimg.cn/large/0078bOVFgy1g0mltf2mfsj30hj037aan.jpg)

--------------------

# Redis主从复制(3.0开始支持)原理
1.  全量同步
    1.	当启动一个slave node的时候，它会发送一个PSYNC命令给master
    2.	如果这是slave node重新链接master，master会将缺少的数据发送给slave，如果是第一次链接master，则会触发一次full resynchronization,开始 full resynchronization的时候，master启动一个后台线程，先将现有数据生成一个零时的rdb文件，生成文件后，master会将这个rdb文件发送给slave，slave会先把这个rdb文件存放到本地磁盘，然后在加载到内存，然后master会将生成rdb这段时间内接收到的在内存中的数据发送给slave，slave也会接收这份数据。
    3.	slave如果跟master网络故障，断开了，当重新连接上以后，master发现有多个slave都来重新连接，master会生成一个rdb文件，将这个文件同时发送个多个slave node
    
![full_sync](http://ww2.sinaimg.cn/large/0078bOVFgy1g0mm2zwx3qj30mn0dzjrv.jpg)
    
2.  主从复制的断点续传
    1.	redis从2.8开始就支持断点续传功能，即当slave与master断开后，重新连接时，会继续从上一次断开的点继续传送数据，而不是full resynchronization。
    2.	master会在内存中创建一个backlog，master和slave都会保存一个offset,slave还有一个master id,offset就是保存在backlog中的，如果slave和master网络断开，重新连接后slave会让master从replica offset开始续传。但是如果没有找到offset，则会触发full resynchronization。
3. 无磁盘化复制
    1.	master在内存中直接创建rdb,然后直接发送给slave,不会存入本地磁盘
    2.	参数配置  
        repl-diskless-sync  
        repl-diskless-sync-delay, 等待一定时长在复制，因为要等更多的slave重新连接
4. 过期key处理
    1. slave不会有过期Key,只有master有过期key,如果master过期了一个可以或者通过LRU算法淘汰了一个key，那么master会模拟发送一个del命令给slave

--------------------

# Redis-Cluster集群
<div align=center><img src="http://ww2.sinaimg.cn/large/0078bOVFgy1g0natm1efxj30dr0fut9k.jpg" width=256 height=256 /></div>

1.  所有的redis节点彼此互联(PING-PONG机制),内部使用二进制协议优化传输速度和带宽。
2.  节点的fail是通过集群中超过半数的节点检测失效时才生效。
3.  客户端与redis节点直连,不需要中间proxy层.客户端不需要连接集群所有节点,连接集群中任何一个可用节点即可。
4.  redis-cluster把所有的物理节点映射到[0-16383]slot上（不一定是平均分配）,cluster 负责维护node<->slot<->value。
5.  Redis集群预分好16384个桶，当需要在 Redis 集群中放置一个 key-value 时，根据 CRC16(key) mod 16384的值，决定将一个key放到哪个桶中。

为什么是16384（2^14）个？
在redis节点发送心跳包时需要把所有的槽放到这个心跳包里，以便让节点知道当前集群信息，16384=16k，在发送心跳包时使用char进行bitmap压缩后是2k（2 * 8 (8 bit) * 1024(1k) = 2K），也就是说使用2k的空间创建了16k的槽数。

虽然使用CRC16算法最多可以分配65535（2^16-1）个槽位，65535=65k，压缩后就是8k（8 * 8 (8 bit) * 1024(1k) = 8K），也就是说需要需要8k的心跳包，作者认为这样做不太值得；并且一般情况下一个redis集群不会有超过1000个master节点，所以16k的槽位是个比较合适的选择。

--------------------

#  Redis哨兵
<div align=center>
<img src="http://ww2.sinaimg.cn/large/0078bOVFgy1g0y43vh0ilj30ay07g3z3.jpg" />

在Server1 掉线后：

<img src="http://ww2.sinaimg.cn/large/0078bOVFgy1g0y43vh0ilj30ay07g3z3.jpg" />

升级Server2 为新的主服务器：

<img src="http://ww2.sinaimg.cn/large/0078bOVFgy1g0y477tgrvj30as082wfb.jpg" />
</div>

1.  Sentinel的作用：
    1.  Master 状态监测
    2.  如果Master 异常，则会进行Master-slave 转换，将其中一个Slave作为Master，将之前的Master作为Slave 
    3.  Master-Slave切换后，master_redis.conf、slave_redis.conf和sentinel.conf的内容都会发生改变，即master_redis.conf中会多一行slaveof的配置，sentinel.conf的监控目标会随之调换 

2.  Sentinel的工作方式:
    1.  每个Sentinel以每秒钟一次的频率向它所知的Master，Slave以及其他 Sentinel 实例发送一个 PING 命令 
    2.  如果一个实例（instance）距离最后一次有效回复 PING 命令的时间超过 down-after-milliseconds 选项所指定的值， 则这个实例会被 Sentinel 标记为主观下线。 
    3.  如果一个Master被标记为主观下线，则正在监视这个Master的所有 Sentinel 要以每秒一次的频率确认Master的确进入了主观下线状态。 
    4.  当有足够数量的 Sentinel（大于等于配置文件指定的值）在指定的时间范围内确认Master的确进入了主观下线状态， 则Master会被标记为客观下线 
    5.  在一般情况下， 每个 Sentinel 会以每 10 秒一次的频率向它已知的所有Master，Slave发送 INFO 命令 
    6.  当Master被 Sentinel 标记为客观下线时，Sentinel 向下线的 Master 的所有 Slave 发送 INFO 命令的频率会从 10 秒一次改为每秒一次 
    7.  若没有足够数量的 Sentinel 同意 Master 已经下线， Master 的客观下线状态就会被移除。 
    8.  若 Master 重新向 Sentinel 的 PING 命令返回有效回复， Master 的主观下线状态就会被移除。

--------------------

# Redis和数据库双写一致性问题

一致性问题是分布式系统常见问题，可以分为最终一致性和强一致性。所以弄清诉求
数据库强一致性，不放缓存，我们所做的一切只是保证最终一致性，另外无法完全避免，讨论三种更新策略：

1. 先更新数据库，再更新缓存
2. 先删除缓存，再更新数据库
3. 先更新数据库，再删除缓存


1.  先更新数据库，再更新缓存
这套方案，大家是普遍反对的，为什么呢？有如下两点原因：

原因一、线程安全问题，同时有请求A和请求B进行更新操作，那么会出现：

    线程A更新了数据库
    线程B更新了数据库
    线程B更新了缓存
    线程A更新了缓存

    这就出现请求A更新缓存应该比请求B更新缓存早才对，但是因为网络等原因，B比A更早更新了缓存。这就导致了脏数据，因此不考虑！

原因二、业务场景考虑

    1）如果是写数据库场景比较多，读数据库场景比较少业务需求。"先更新数据库，再更新缓存"这种方案会导致，数据压根还没读到，缓存就被频繁的更新浪费性能
    2）如果写入数据库是经过复杂计算以后再更新数据库，那么每次写入数据库后更新缓存，性能存在浪费

2.  先删除缓存，再更新数据库 

该方案会导致不一致的原因：同时有一个请求A进行更新操作，另一个请求B进行查询操作。那么就会出现以下情形：

情况一：多进程读写原因
```
请求A进行写操作，删除缓存
请求B查询发现缓存不存在
请求B去数据库查询得到旧值
请求B将旧值写入缓存
请求A将新值写入数据库
上诉请求出现不一致的情况，如果没采用缓存过期策略。则缓存数据一直是脏数据。
```
情况二：MYSQL主从分离原因
```
请求A进行写操作，删除缓存；
请求A将数据写入数据库了；
请求B查询缓存发现，缓存没有值；
请求B去从库查询，这时，还没有完成主从同步，因此查询到的是旧值；
请求B将旧值写入缓存；
数据库完成主从同步，从库变为新值；
```


解决方案：采用延迟双删策略。先删除缓存，再删除数据库，进程休眠1秒再次删除缓存

3.  先更新数据库，再删除缓存
    这种情况不存在并发问题么？
```
不是的。假设这会有两个请求，一个请求A做查询操作，一个请求B做更新操作，那么会有如下情形产生：
（1）缓存刚好失效；
（2）请求A查询数据库，得一个旧值；
（3）请求B将新值写入数据库；
（4）请求B删除缓存；
（5）请求A将查到的旧值写入缓存；
ok，如果发生上述情况，确实是会发生脏数据。
```
   

解决方案：发生上述情况有一个先天性条件，就是6.1中步骤（3）的写数据库操作比步骤（2）的读数据库操作耗时更短，才有可能使得步骤（4）先于步骤（5）。可是，大家想想，数据库的读操作的速度远快于写操作的（不然做读写分离干嘛，做读写分离的意义就是因为读操作比较快，耗资源少），因此步骤（3）耗时比步骤（2）更短，这一情形很难出现。  首先，给缓存设有效时间是一种方案。其次，采用策略2（先删除缓存，再更新数据库）里给出的异步延时删除策略，保证读请求完成以后，再进行删除操作。

--------------------

#   如何解决redis的并发竞争key问题

分析:这个问题大致就是，同时有多个子系统去set一个key。这个时候要注意什么呢？大家思考过么。需要说明一下，博主提前百度了一下，发现答案基本都是推荐用redis事务机制。博主不推荐使用redis的事务机制。因为我们的生产环境，基本都是redis集群环境，做了数据分片操作。你一个事务中有涉及到多个key操作的时候，这多个key不一定都存储在同一个redis-server上。因此，redis的事务机制，十分鸡肋。

解决方案

1. 如果对key操作不要求顺序  

    这种情况下，准备一个分布式锁，谁抢到锁谁set即可

2. 如果对key操作要求顺序  

    假设有一个key1,系统A需要将key1设置为valueA,系统B需要将key1设置为valueB,系统C需要将key1设置为valueC.   
    期望按照key1的value值按照 valueA–>valueB–>valueC的顺序变化。这种时候我们在数据写入数据库的时候，需要保存一个时间戳。假设时间戳如下  
    系统A key 1 {valueA 3:00}  
    系统B key 1 {valueB 3:05}  
    系统C key 1 {valueC 3:10}  
    那么，假设这会系统B先抢到锁，将key1设置为{valueB 3:05}。接下来系统A抢到锁，发现自己的valueA的时间戳早于缓存中的时间戳，那就不做set操作了。以此类推。  
    或者使用队列，将set操作进行串联即可

--------------------

#   redis常见性能问题和解决方案
1.  Master写内存快照，save命令调度rdbSave函数，会阻塞主线程的工作，当快照比较大时对性能影响是非常大的，会间断性暂停服务，所以Master最好不要写内存快照。
2.  Master AOF持久化，如果不重写AOF文件，这个持久化方式对性能的影响是最小的，但是AOF文件会不断增大，AOF文件过大会影响Master重启的恢复速度。Master最好不要做任何持久化工作，包括内存快照和AOF日志文件，特别是不要启用内存快照做持久化,如果数据比较关键，某个Slave开启AOF备份数据，策略为每秒同步一次。
3.  Master调用BGREWRITEAOF重写AOF文件，AOF在重写的时候会占大量的CPU和内存资源，导致服务load过高，出现短暂服务暂停现象。
4.  Redis主从复制的性能问题，为了主从复制的速度和连接的稳定性，Slave和Master最好在同一个局域网内

--------------------

# Redis6.0 多线程
其实本质只是在网络IO上面实现了多线程读取和写入，然后进行执行队列，执行还是单线程
![1.jpeg](http://ww2.sinaimg.cn/large/007lnJOlgy1gdoxcw7xwhj30cf0ah0tr.jpg)
加入多线程 IO 之后，整体的读流程如下:

- 主线程负责接收建连请求，读事件到来(收到请求)则放到一个全局等待读处理队列
- 主线程处理完读事件之后，通过 RR(Round Robin) 将这些连接分配给这些 IO 线程，然后主线程忙等待(spinlock 的效果)状态
- IO 线程将请求数据读取并解析完成(这里只是读数据和解析并不执行)
- 主线程执行所有命令并清空整个请求等待读处理队列(执行部分串行)

上面的这个过程是完全无锁的，因为在 IO 线程处理的时主线程会等待全部的 IO 线程完成，所以不会出现data race的场景。


# Redis新特性
1. Redis Module
    1.  任何C/C++程序现在都可以运行在Redis上
    2.  Modules是用一种本地的方式来扩展Redis的新用例和功能
    3.  使用现有的或者添加新的数据结构
    4.  享受简单，无限可扩展性和高可用性的同时保持着redis的本机的速度
2. Redis Search

    高性能的全文搜索引擎（Faster, in-memory, highly available full text search），可作为Redis Module运行在Redis上。但是它与其他Redis搜索库不同的是，它不使用Redis内部数据结构，例如：集合、排序集（ps.后面会写一篇基于Redis的数据结构来设计搜索引擎），Redis原声的搜索还是有很大的局限性，简单的分词搜索是可以满足，但是应用到复杂的场景就不太适合。

3. Redis ML

    机器学习模型服务器