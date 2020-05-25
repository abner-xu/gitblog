---
title: nginx总结
categories:
  - 后端
  - NGINX
tags:
  - 面试
comments: true
toc: true
abbrlink: c92afadf
date: 2019-03-01 15:47:07
---
# nginx的特性
-   非阻塞、高并发连接：处理2-3万并发连接数，官方监测能支持5万并发
-   内存消耗小：开启10个nginx才占150M内存，Nginx采取了分阶段资源分配技术
-   内置的健康检查功能
-   master/worker结构：一个master进程(管理work进程)，生成一个或者多个worker进程（处理请求）
-   事件驱动：通信机制采用epoll模型

# nginx 的 upstream目前支持 4 种方式的分配 
- 轮询默认的方式 ：每个请求按时间顺序逐一分配到不同的后端服务器，如果后端服务器down掉，能自动剔除。 
- 权重weight ： 指定轮询几率，weight和访问比率成正比，用于后端服务器性能不均的情况。 
- ip_hash ：  每个请求按访问ip的hash结果分配，这样每个访客固定访问一个后端服务器，可以解决session的问题。  
- fair（第三方） ：按后端服务器的响应时间来分配请求，响应时间短的优先分配。  
- url_hash（第三方）：


# 惊群效应
主进程（master 进程）首先通过 socket() 来创建一个 sock 文件描述符用来监听，然后fork生成子进程（workers 进程），子进程将继承父进程的 sockfd（socket 文件描述符），之后子进程 accept() 后将创建已连接描述符（connected descriptor），然后通过已连接描述符来与客户端通信。

那么，由于所有子进程都继承了父进程的 sockfd，那么当连接进来时，所有子进程都将收到通知并“争着”与它建立连接，这就叫“惊群现象”。大量的进程被激活又挂起，只有一个进程可以accept() 到这个连接，这当然会消耗系统资源。

# 惊群现象的处理
Nginx 提供了一个 accept_mutex 这个东西，这是一个加在accept上的一把共享锁。即每个 worker 进程在执行 accept 之前都需要先获取锁，获取不到就放弃执行 accept()。有了这把锁之后，同一时刻，就只会有一个进程去 accpet()，这样就不会有惊群问题了。 accept_mutex 是一个可控选项，我们可以显示地关掉，默认是打开的。

# master进程作用
- 接收来自外界的信号
- 向各worker进程发送信号
- 监控worker进程的运行状态，当worker进程退出后(异常情况下)，会自动重新启动新的worker进程

# Nginx采用的 IO多路复用模型epoll
epoll通过在Linux内核中申请一个简易的文件系统（文件系统一般用什么数据结构实现？B+树），其工作流程分为三部分：
-   调用 int epoll_create(int size) 建立一个epoll对象，内核会创建一个eventpoll结构体，用于存放通过epoll_ctl()向 epoll 对象中添加进来的事件，这些事件都会挂载在红黑树中。
-   调用 int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event) 在 epoll 对象中为 fd 注册事件，所有添加到epoll中的事件都会与设备驱动程序建立回调关系，也就是说，当相应的事件发生时会调用这个sockfd的回调方法，将sockfd添加到 eventpoll 中的双链表
-   调用 int epoll_wait(int epfd, struct epoll_event * events, int maxevents, int timeout) 来等待事件的发生，timeout 为 -1 时，该调用会阻塞直到有事件发生

这样，注册好事件之后，只要有 fd 上事件发生，epoll_wait() 就能检测到并返回给用户，用户就能”非阻塞“地进行 I/O 了。

epoll() 中内核则维护一个链表， epoll_wait 直接检查链表是不是空就知道是否有文件描述符准备好了。（epoll 与 select 相比最大的优点是不会随着 sockfd 数目增长而降低效率，使用 select() 时，内核采用轮训的方法来查看是否有 fd 准备好，其中的保存 sockfd 的是类似数组的数据结构 fd_set，key 为 fd ，value 为 0 或者 1。）

能达到这种效果，是因为在内核实现中 epoll 是根据每个 sockfd 上面的与设备驱动程序建立起来的回调函数实现的。那么，某个 sockfd 上的事件发生时，与它对应的回调函数就会被调用，来把这个 sockfd 加入链表，其他处于“空闲的”状态的则不会。在这点上， epoll 实现了一个”伪”AIO。但是如果绝大部分的 I/O 都是“活跃的”，每个 socket 使用率很高的话，epoll效率不一定比 select 高（可能是要维护队列复杂）。

可以看出，因为一个进程里只有一个线程，所以一个进程同时只能做一件事，但是可以通过不断地切换来“同时”处理多个请求。