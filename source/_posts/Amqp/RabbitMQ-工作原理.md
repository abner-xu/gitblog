---
title: RabbitMQ-工作原理
categories:
  - 后端
  - RabbitMQ
tags:
  - RabbitMQ
comments: true
toc: true
abbrlink: 776c5902
date: 2019-09-04 22:48:46
---

# 工作机制
在了解消息通讯之前首先要了解3个概念：生产者、消费者和代理。
- 生产者：消息的创建者，负责创建和推送数据到消息服务器；
- 消费者：消息的接收方，用于处理数据和确认消息；
- 代理：就是RabbitMQ本身，用于扮演“快递”的角色，本身不生产消息，只是扮演“快递”的角色。

## 消息发送原理
你的应用程序和`Rabbit Server`之间会创建一个`TCP`连接，一旦`TCP`打开，并通过了认证，认证就是你试图连接Rabbit之前发送的Rabbit服务器连接信息和用户名和密码，有点像程序连接数据库，一旦认证通过你的应用程序和Rabbit就创建了一条`AMQP信道（Channel）`。
信道是创建在“真实”TCP上的虚拟连接，AMQP命令都是通过信道发送出去的，每个信道都会有一个唯一的ID，不论是发布消息，订阅队列或者介绍消息都是通过信道完成的。

## 为什么直接通过TCP发送命名
对于操作系统来说创建和销毁TCP会话是非常昂贵的开销，假设高峰期每秒有成千上万条连接，每个连接都要创建一条TCP会话，这就造成了TCP连接的巨大浪费，而且操作系统每秒能创建的TCP也是有限的，因此很快就会遇到系统瓶颈。
如果我们每个请求都使用一条TCP连接，既满足了性能的需要，又能确保每个连接的私密性，这就是引入信道概念的原因。

## 名词解释
包括：ConnectionFactory（连接管理器）、Channel（信道）、Exchange（交换器）、Queue（队列）、RoutingKey（路由键）、BindingKey（绑定键）。

- ConnectionFactory（连接管理器）：应用程序与Rabbit之间建立连接的管理器，程序代码中使用；
- Channel（信道）：消息推送使用的通道；
- Exchange（交换器）：用于接受、分配消息；
- Queue（队列）：用于存储生产者的消息；
- RoutingKey（路由键）：用于把生成者的数据分配到交换器上；
- BindingKey（绑定键）：用于把交换器的消息绑定到队列上；

![rabbit-producer.png](http://ww1.sinaimg.cn/large/007lnJOlgy1gcz3m1jf2gj30mi07zgna.jpg)


## 消息持久化
Rabbit队列和交换器有一个不可告人的秘密，就是默认情况下重启服务器会导致消息丢失，那么怎么保证Rabbit在重启的时候不丢失呢？答案就是消息持久化。

当你把消息发送到Rabbit服务器的时候，你需要选择你是否要进行持久化，但这并不能保证Rabbit能从崩溃中恢复，想要Rabbit消息能恢复必须满足3个条件：

投递消息的时候durable设置为true，消息持久化，代码：`channel.queueDeclare(x, true, false, false, null)`，参数2设置为true持久化；
设置投递模式deliveryMode设置为2（持久），代码：`channel.basicPublish(x, x, MessageProperties.PERSISTENT_TEXT_PLAIN,x)`，参数3设置为存储纯文本到磁盘；
消息已经到达持久化交换器上；
消息已经到达持久化的队列；

### 持久化工作原理
Rabbit会将你的持久化消息写入磁盘上的持久化日志文件，等消息被消费之后，Rabbit会把这条消息标识为等待垃圾回收。
### 持久化的缺点
消息持久化的优点显而易见，但缺点也很明显，那就是性能，因为要写入硬盘要比写入内存性能较低很多，从而降低了服务器的吞吐量，尽管使用SSD硬盘可以使事情得到缓解，但他仍然吸干了Rabbit的性能，当消息成千上万条要写入磁盘的时候，性能是很低的。