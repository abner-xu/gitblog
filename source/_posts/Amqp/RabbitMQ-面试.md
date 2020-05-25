---
title: RabbitMQ-面试
categories:
  - 后端
  - RabbitMQ
tags:
  - 面试
comments: true
toc: true
abbrlink: ffca95ac
date: 2019-09-04 22:48:46
---
# 问答
-   重复消息问题
    -   生产者->服务端出现网络抖动等问题的重发(上半场): 此时重发是MQ-client发起的，消息的处理是MQ-server,为了避免重复，对每条消息MQ系统内部必须生成一个`inner-msg-id`，全局唯一，由MQ生成对业务透明
    -   服务端->消费端出现网络抖动等问题的重发(下半场): 为了保证业务幂等性，业务消息体中，必须有一个biz-id，作为去重和幂等的依据，这个业务ID的特性是：对于同一个业务场景，全局唯一、由业务消息发送方生成，业务相关，对MQ透明、由业务消息消费方负责判重，以保证幂等，常见的有订单id,业务唯一id等

-   顺序消息问题
    问题场景1：业务上产生三条消息，分别是对数据的增加、修改、删除，而如果没有保证顺序消费，结果可能是删除、修改、增加，本来数据最终要删除，最后结果变成增加
![1.png](http://ww1.sinaimg.cn/large/007lnJOlgy1gf4n8253kpj31wm0ietcm.jpg)

    解决方案,需要保证以下几点:
    -   发送的顺序消息，必须保证在投递到同一个队列，且这个消费者只能有一个（独占模式）
    -   然后同意提交（可以合并一个大消息，或拆分多个消息，最好是拆分），并且所有消息的会话ID一致
    -   添加消息属性：顺序表及的序号、本地顺序消息的size属性，进行落库操作
    -   并行进行发送给自身的延迟消息（带上关键属性：会话ID、SIZE）进行后续处理消费

-   事物消息问题

-   消息丢失问题解决办法
    - 生产者：方案一，开启事物机制，不推荐使用，分布式环境尤其复制；方案二，开启confir模式
    - MQ：开启消息持久化
    - 消费者：关闭自动的ack,采用手动ack方式

-   高可用场景
    - 集群
    - 镜像队列：镜像队列主要有两种类型：master和slave。master和slave节点位于同一个集群中。master只要一个节点，slave可以有多个节点。生产者发送到主节点消息会同时被发往各个slave节点，除了发送消息，其他动作只会发给master，然后通过master广播给其他slave。master挂掉以后，根据slave加入的时间顺序排列，时间长的提升为master。
        
    

  



-   RabbitMQ 中的 broker 是指什么？cluster 又是指什么？
broker 是指一个或多个 erlang node 的逻辑分组，且 node 上运行着 RabbitMQ 应用程序。cluster 是在 broker 的基础之上，增加了 node 之间共享元数据的约束。

-   什么是元数据？元数据分为哪些类型？包括哪些内容？与 cluster 相关的元数据有哪些？元数据是如何保存的？元数据在 cluster 中是如何分布的？
在非 cluster 模式下，元数据主要分为 Queue 元数据（queue 名字和属性等）、Exchange 元数据（exchange 名字、类型和属性等）、Binding 元数据（存放路由关系的查找表）、Vhost 元数据（vhost 范围内针对前三者的名字空间约束和安全属性设置）。
在cluster 模式下，还包括 cluster 中 node 位置信息和 node 关系信息。元数据按照 erlang node 的类型确定是仅保存于 RAM 中，还是同时保存在 RAM 和 disk 上。元数据在cluster 中是全 node 分布的。


-   RAM node 和 disk node 的区别？
RAM node 仅将 fabric（即 queue、exchange 和 binding 等 RabbitMQ 基础构件）相关元数据保存到内存中，但 disk node 会在内存和磁盘中均进行存储。RAM node 上唯一会存储到磁盘上的元数据是 cluster 中使用的 disk node 的地址。要求在 RabbitMQ cluster 中至少存在一个 disk node

-   RabbitMQ 上的一个 queue 中存放的 message 是否有数量限制？
可以认为是无限制，因为限制取决于机器的内存，但是消息过多会导致处理效率的下降。

-   RabbitMQ 概念里的 channel、exchange 和 queue 这些东东是逻辑概念，还是对应着进程实体？这些东东分别起什么作用？
queue 具有自己的 erlang 进程；
exchange 内部实现为保存 binding 关系的查找表； 
channel 是实际进行路由工作的实体，即负责按照 routing_key 将 message 投递给queue 。由 AMQP 协议描述可知，channel 是真实 TCP 连接之上的虚拟连接，所有AMQP 命令都是通过 channel 发送的，且每一个 channel 有唯一的 ID。一个 channel 只能被单独一个操作系统线程使用，故投递到特定 channel 上的 message 是有顺序的。但一个操作系统线程上允许使用多个 channel 。channel 号为 0 的 channel 用于处理所有对于当前 connection 全局有效的帧，而 1-65535 号 channel 用于处理和特定 channel 相关的帧。
其中每一个 channel 运行在一个独立的线程上，多线程共享同一个 socket。

-   vhost 是什么？起什么作用？
vhost 可以理解为虚拟 broker ，即 mini-RabbitMQ server。其内部均含有独立的queue、exchange 和 binding 等，但最最重要的是，其拥有独立的权限系统，可以做到vhost 范围的用户控制。当然，从 RabbitMQ 的全局角度，vhost 可以作为不同权限隔离的手段（一个典型的例子就是不同的应用可以跑在不同的 vhost 中）。

-   为什么 heavy RPC 的使用场景下不建议采用 disk node ？
heavy RPC 是指在业务逻辑中高频调用 RabbitMQ 提供的 RPC 机制，导致不断创建、销毁 reply queue ，进而造成 disk node 的性能问题（因为会针对元数据不断写盘）。所以在使用 RPC 机制时需要考虑自身的业务场景。

-   向不存在的 exchange 发 publish 消息会发生什么？向不存在的 queue 执行consume 动作会发生什么？
都会收到 Channel.Close 信令告之不存在（内含原因 404 NOT_FOUND）。

-   RabbitMQ 允许发送的 message 最大可达多大？
根据 AMQP 协议规定，消息体的大小由 64-bit 的值来指定，所以你就可以知道到底能发多大的数据了。

-   什么情况下 producer 不主动创建 queue 是安全的？
    1.message是允许丢失的；
    2.实现了针对未处理消息的republish功能（例如采用Publisher Confirm 机制）。

-   “dead letter”queue 的用途？
当消息被 RabbitMQ server 投递到 consumer 后，但 consumer 却通过 Basic.Reject 进行了拒绝时（同时设置 requeue=false），那么该消息会被放入“dead letter”queue 中。该 queue 可用于排查 message 被 reject 或 undeliver 的原因。

-   什么情况下会出现 blackholed 问题？
blackholed 问题是指，向 exchange 投递了 message ，而由于各种原因导致该message 丢失，但发送者却不知道。可导致 blackholed 的情况：1.向未绑定 queue 的exchange 发送 message；2.exchange 以 binding_key key_A 绑定了 queue queue_A，但向该 exchange 发送 message 使用的 routing_key 却是 key_B。

