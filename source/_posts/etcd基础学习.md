---
title: etcd基础学习
categories:
  - 后端
  - ETCD
tags:
  - etcd
comments: true
toc: true
date: 2019-03-23 22:21:13
---

# API操作
### put & get
> etcd底层是按照key有序存储
```shell
1：普通
ETCDCTL_API=3 etcdctl put "name" "abc"

ETCDCTL_API=3 etcdctl get "name" "abc"
name
abc

2：前缀用法
ETCDCTL_API=3 etcdctl put "/sh/jobs/job1" "exe1"
ETCDCTL_API=3 etcdctl put "/sh/jobs/job2" "bbb2"

ETCDCTL_API=3 etcdctl get "/sh/jobs/" --prefix
/sh/jobs/job1
exe1
/sh/jobs/job2
bbb2
```


### del
```shell
ETCDCTL_API=3 etcdctl dek "name"
1
```


### watch，监听变化
```shell
ETCDCTL_API=3 etcdctl watch "/sh/jobs/" --prefix
PUT
/sh/jobs/job3
bbb2

```
-------