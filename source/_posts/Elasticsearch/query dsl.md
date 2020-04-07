---
title: elasticsearch query dsl
categories:
  - 后端
  - elasticsearch
tags:
  - elasticsearch
comments: true
toc: true
date: 2019-07-28 09:51:14
---
# 基本概念
## 查询所有
```json
GET /Product/cpu/_search
{
  "query": { "match_all": {} }
}
```
## 单条件匹配和排序
```json
GET /Product/cpu/_search
{
  "query": { 
    "match": {
        "name":"amd"
     } 
  },
  "sort":{
    "price":"desc"
  }
}
```