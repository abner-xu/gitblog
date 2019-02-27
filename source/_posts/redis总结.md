---
title: redis总结
categories:
  - 后端
  - Redis
tags:
  - 面试知识
comments: true
toc: true
date: 2019-02-27 20:49:03
---
# 1.Redis为什么那么快
1. 纯内存操作
2. 单线程操作，避免了频繁的上下文切换
3. 采用了非阻塞I/O多路复用机制
> 我们的redis-client在操作的时候，会产生具有不同事件类型的socket。在服务端，有一段I/0多路复用程序，将其置入队列之中。然后，文件事件分派器，依次去队列中取，转发到不同的事件处理器中。

# 2.Redis的过期策略以及内存淘汰机制
## 三种过期策略
- 定时删除：在设置键的过期时间的同时，创建一个定时器(timer)，让定时器在键的过期时间来临时，立即执行对键的删除操作；
- 惰性删除：放任键过期不管，但是每次从键空间中获取键时，都检查取得的键是否过期，如果过期的话，就删除该键；如果没有过期，那就返回该键；
- 定期删除：每隔一段时间，程序就对数据库进行一次检查，删除里面的过期键。至于删除多少过期键，以及要检查多少个数据库，则由算法决定。

1. Redis采用的是定期删除+惰性删策略。  

    为什么不用定时删除策略？定时删除策略需要定时器来监视key，过期则自动删除。虽然内存及时释放了，但是CPU消耗大。在大并发的情况下，这一策略得不偿失

2. Redis采用的是定期删除+惰性删策略工作机制。  

    定期删除，redis默认每100ms检查一次是否存在过期key，有则删除。需要说明的是redis并不是100ms检查所有的key一次，而是随机进行抽取检查。因此，惰性删除派上用处。

3. 惰性删策略延伸出来的问题就是，redis缓存淘汰机制
## Redis(3.0版本)6种缓存淘汰机制
1. no-enviction(驱逐)：禁止驱逐数据（不删除数据策略，达到最大的内存限制时，如果有更多的数据写入，返回错误给客户端）
2. allkeys-lru：所有key通用，优先删除最少使用的key（less recently used,LRU算法）
3. allkeys-random ：素有key通用，随机删除一部分key
4. volatile-lru：只限于设置了expire的部分，优先删除最少使用的key（less recently used,LRU算法）
5. volatile-random：只限于设置了 expire 的部分; 随机删除一部分key
6. volatile-ttl：只限于设置了 expire 的部分; 优先删除剩余时间(time to live,TTL) 短的key。
> 注意： 如果没有设置 expire 的key, 不满足先决条件(prerequisites); 那么 volatile-lru, volatile-random 和 volatile-ttl 策略的行为, 和 noeviction(不删除) 基本上一致。  
一般来说:如果分为热数据与冷数据, 推荐使用allkeys-lru策略。 也就是, 其中一部分key经常被读写. 如果不确定具体的业务特征, 那么allkeys-lru是一个很好的选择。 如果需要循环读写所有的key, 或者各个key的访问频率差不多, 可以使用allkeys-random策略, 即读写所有元素的概率差不多。 假如要让 Redis 根据 TTL 来筛选需要删除的key, 请使用volatile-ttl策略。

# 3.Redis和数据库双写一致性问题
