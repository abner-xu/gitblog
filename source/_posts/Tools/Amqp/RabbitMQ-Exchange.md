---
title: RabbitMQ-Exchange
categories:
  - 工具
  - RabbitMQ
tags:
  - RabbitMQ
comments: true
toc: true
abbrlink: 9e178502
date: 2019-09-04 22:48:46
---
# 交换器分类
RabbitMQ的Exchange（交换器）分为四类：
- direct（默认）
- headers
- fanout
- topic

其中headers交换器允许你匹配AMQP消息的header而非路由键，除此之外headers交换器和direct交换器完全一致，但性能却很差，几乎用不到，所以我们本文也不做讲解。

_注意：fanout、topic交换器是没有历史数据的，也就是说对于中途创建的队列，获取不到之前的消息。_

# direct
direct为默认的交换器类型，也非常的简单，如果路由键匹配的话，消息就投递到相应的队列，如图：
<div><img src="http://ww1.sinaimg.cn/large/007lnJOlgy1gcz4nahazsj30as0deaaq.jpg"/><img src="http://ww1.sinaimg.cn/large/007lnJOlgy1gcz5lcc4o6j30cl07i0sy.jpg"/></div>


_注意：不能使用for循环单个消息消费来替代持续消息消费，因为这样性能很低；_
- 公平调度
当接收端订阅者有多个的时候，direct会轮询公平的分发给每个订阅者（订阅者消息确认正常）

- 消息的发后既忘特性
发后既忘模式是指接受者不知道消息的来源，如果想要指定消息的发送者，需要包含在发送内容里面，这点就像我们在信件里面注明自己的姓名一样，只有这样才能知道发送者是谁。

- 消息确认
看了上面的代码我们可以知道，消息接收到之后必须使用channel.basicAck()方法手动确认（非自动确认删除模式下），那么问题来了。

- 消息收到未确认会怎么样？
如果应用程序接收了消息，因为bug忘记确认接收的话，消息在队列的状态会从“Ready”变为“Unacked”，如图：
![rabbitmq-unacked.png](http://ww1.sinaimg.cn/large/007lnJOlgy1gcz4qxvyoaj30ic02gdfo.jpg)
_总结：消费者消费的每条消息都必须确认。_

- 消息拒绝
消息在确认之前，可以有两个选择：
  - 选择1：断开与Rabbit的连接，这样Rabbit会重新把消息分派给另一个消费者；
  - 选择2：拒绝Rabbit发送的消息使用channel.basicReject(long deliveryTag, boolean requeue)，参数1：消息的id；参数2：处理消息的方式，如果是true Rabbib会重新分配这个消息给其他订阅者，如果设置成false的话，Rabbit会把消息发送到一个特殊的“死信”队列，用来存放被拒绝而不重新放入队列的消息。

# fanout交换器——发布/订阅模式
不处理路由键。你只需要简单的将队列绑定到交换机上。一个发送到交换机的消息都会被转发到与该交换机绑定的所有队列上。很像子网广播，每台子网内的主机都获得了一份复制的消息。Fanout交换机转发消息是最快的。 
<div><img src="http://ww1.sinaimg.cn/large/007lnJOlgy1gcz5dpum3vj30890aigmg.jpg"><img src="http://ww1.sinaimg.cn/large/007lnJOlgy1gcz5dczg54j30cl08m3yu.jpg"></div>

# topic
topic交换器运行和fanout类似，但是可以更灵活的匹配自己想要订阅的信息，这个时候routingKey路由键就排上用场了，使用路由键进行消息（规则）匹配。
假设我们现在有一个日志系统，会把所有日志级别的日志发送到交换器，warning、log、error、fatal，但我们只想处理error以上的日志，要怎么处理？这就需要使用topic路由器了。
topic路由器的关键在于定义路由键，定义routingKey名称不能超过255字节，使用“.”作为分隔符，例如：com.mq.rabbit.error。
<div><img src="http://ww1.sinaimg.cn/large/007lnJOlgy1gcz5tem5nsj30bp0elabi.jpg"><img src="http://ww1.sinaimg.cn/large/007lnJOlgy1gcz5temiurj30f90870tz.jpg"></div>

