---
title: elasticsearch query dsl
categories:
  - 后端
  - elasticsearch
tags:
  - elasticsearch
comments: true
toc: true
abbrlink: ac5ac9f
date: 2019-07-28 09:51:14
---
# 基本概念
## 查询所有
GET /Product/cpu/_search
```json
{
  "query": { "match_all": {} }
}
```
## 单条件匹配和排序
GET /Product/cpu/_search
```json
{
  "query": { 
    "match": {
        "name":"amd"
     } 
  },
  "sort":[
    {"price":"desc"}
  ] 
}
```

## 查询指定的字段
GET /Product/cpu/_search
```json
{
  "query": { "match_all": {} },
  "_source":["name","price"]
}
```

## filter数据过滤
GET /Product/cpu/_search
例如：cpu名称包含amd,且价格大于1000
```json
{
  "query": {
   "bool": {
      "must":{
        "match":{ 
          "name": "amd"
        }         
      },
      "filter":{
          "range":{
            "price": {"gt":1000}
          }   
       }      
    } 
  }
}
```