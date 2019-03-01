---
title: nginx总结
categories:
  - 后端
  - 面试
tags:
  - 面试知识
comments: true
toc: true
date: 2019-03-01 15:47:07
---
# nginx的特性

-	非阻塞、高并发连接：处理2-3万并发连接数，官方监测能支持5万并发

-	内存消耗小：开启10个nginx才占150M内存，Nginx采取了分阶段资源分配技术

-	内置的健康检查功能

-	master/worker结构：一个master进程(管理work进程)，生成一个或者多个worker进程（处理请求）

-	事件驱动：通信机制采用epoll模型

# nginx 的 upstream目前支持 4 种方式的分配 

- 轮询默认的方式 ：每个请求按时间顺序逐一分配到不同的后端服务器，如果后端服务器down掉，能自动剔除。 

- 权重weight ： 指定轮询几率，weight和访问比率成正比，用于后端服务器性能不均的情况。 

- ip_hash ：  每个请求按访问ip的hash结果分配，这样每个访客固定访问一个后端服务器，可以解决session的问题。  

- fair（第三方） ：按后端服务器的响应时间来分配请求，响应时间短的优先分配。  

- url_hash（第三方）：

# Nginx epoll多进程浅析

master进程先建好需要listen的socket后，然后再fork出多个woker进程，这样每个work进程都可以去accept这个socket。当一个client连接到来时，所有accept的work进程都会受到通知，但只有一个进程可以accept成功，其它的则会accept失败。Nginx提供了一把共享锁accept_mutex来保证同一时刻只有一个work进程在accept连接，从而解决惊群问题。当一个worker进程accept这个连接后，就开始读取请求，解析请求，处理请求，产生数据后，再返回给客户端，最后才断开连接，这样一个完成的请求就结束了。

## 惊群效应

 每个worker进程都是从master进程fork过来。在master进程里面，先建立好需要listen的socket之 后，然后再fork出多个worker进程，这样每个worker进程都可以去accept这个socket(当然不是同一个socket，只是每个进程 的这个socket会监控在同一个ip地址与端口，这个在网络协议里面是允许的)。一般来说，当一个连接进来后，所有在accept在这个socket上 面的进程，都会收到通知，而只有一个进程可以accept这个连接，其它的则accept失败。
