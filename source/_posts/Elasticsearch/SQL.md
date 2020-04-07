---
title: elasticsearch query 语法
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
# SQL语法
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

## full-text search 全文检索
GET /Product/cpu/_search
例如：desc字段内容去被倒排索引一一检索，包含任意词条的数据会被反驳
```json
{
  "query": {
      "match": {
        "desc": "cpu chaopin pianyi"
      }    
  }
}
```

## phrase search 短语检索
GET /Product/cpu/_search
例如：desc字段内容必须全匹配短语`chaopin pianyi`
```json
{
  "query": {
      "match_phrase": {
        "desc": "chaopin pianyi"
      }    
  }
}
```

## highlight search 高亮检索
GET /Product/cpu/_search
例如：desc字段内容必须全匹配短语`chaopin pianyi`
```json
{
  "query": {
      "match_phrase": {
        "desc": "chaopin pianyi"
      }    
  }
}
```

# 复合查询
## aggs 聚合查询
GET /Product/cpu/_search
```json
{
  "aggs": {
    "demo_tags": {
      "terms": {
        "field": "tag"
      }
    }
  }
}
```
设置字段为true
PUT /product/cpu/_mapping
{
  "properties": {
    "tag":{
      "type": "text",
      "fielddata": true
    }
  }
}
## aggs 聚合分组求平均
GET /Product/cpu/_search
```json
{
  "aggs": {
    "demo_tags": {
      "terms": {
        "field": "tag"
      },
      "aggs": {
        "avg_demo_price": {
          "avg": {
            "field": "price"
          }
        }
      }
    }
  }
}
```

## aggs 聚合分组求平均后排序
GET /Product/cpu/_search
```json
{
  "size": 0, 
  "aggs": {
    "demo_tags": {
      "terms": {
        "field": "tag",
        "order": {
          "avg_price": "desc"
        }
      },
      "aggs": {
        "avg_demo_price": {
          "avg": {
            "field": "price"
          }
        }
      }
    }
  }
}
```

## aggs 范围区间聚合排序
GET /Product/cpu/_search
```json
{
  "size": 0, 
  "aggs": {
    "group_tags": {
      "range": {
        "field": "",
        "ranges": [
          {
            "from": 50,
            "to": 100
          }
        ]
      },
      "aggs": {
        "NAME": {
          "AGG_TYPE": {}
        }
      }
    }
  }
}
```
