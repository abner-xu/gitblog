---
title: 单线程的redis为什么快
categories:
  - 后端
  - Redis
tags:
  - 面试
comments: true
toc: true
date: 2019-03-10 15:26:21
---
Redis性能如此高的原因，我总结了如下几点：

1.  纯内存操作
2.  单线程
3.  高效的数据结构
4.  合理的数据编码
5.  其他方面的优化

在 Redis 中，常用的几种数据结构和应用场景如下：

1.  String：缓存、计数器、分布式锁等。
2.  List：链表、队列、微博关注人时间轴列表等。
3.  Hash：用户信息、Hash 表等。
4.  Set：去重、赞、踩、共同好友等。
5.  Zset：访问量排行榜、点击量排行榜等。
6.  HyperLogLog: 网站UV,独立IP计算等，主要也是一些去重计算，对数据精度要求不高，主要由于计算数据空间是固定的
7.  Geo：GEO(地理位置)的支持，主要是对经纬度一个位置计算等特性

# 字符串(重点掌握)
Redis 是用 C 语言开发完成的，但在 Redis 字符串中，并没有使用 C 语言中的字符串，而是用一种称为 SDS（Simple Dynamic String）的结构体来保存字符串。

<div align=center><img src="https://ws1.sinaimg.cn/large/0078bOVFgy1g0xzlkq5x1j309w06iaag.jpg"></div>

```c++
struct sdshdr {
    int len;
    int free;
    char buf[];
}
```
SDS 的结构如上图：

    len：用于记录 buf 中已使用空间的长度。
    free：buf 中空闲空间的长度。
    buf[]：存储实际内容。

例如：执行命令 set key value，key 和 value 都是一个 SDS 类型的结构存储在内存中。
## SDS 与 C 字符串的区别
### 常数时间内获得字符串长度
C 字符串本身不记录长度信息，每次获取长度信息都需要遍历整个字符串，复杂度为 O(n)；C 字符串遍历时遇到'\0‘ 时结束。

SDS 中 len 字段保存着字符串的长度，所以总能在常数时间内获取字符串长度，复杂度是 O(1)。

### 避免缓冲区溢出
假设在内存中有两个紧挨着的两个字符串，s1="xxxxx"和 s2="yyyyy"  
由于在内存上紧紧相连，当我们对 s1 进行扩充的时候，将 s1=“xxxxxzzzzz”后，由于没有进行相应的内存重新分配，导致 s1 把 s2 覆盖掉，导致 s2 被莫名其妙的修改。  
但 SDS 的 API 对 zfc 修改时首先会检查空间是否足够，若不充足则会分配新空间，避免了缓冲区溢出问题。

### 减少字符串修改时带来的内存重新分配的次数
由于C语言修改字符需要重新分配空间  
而SDS实现了预分配和惰性释放  
预分配规则：SDS空间进行扩充时，会分配足够的内存空间还会分配额外未使用的空间。<font color=red>如果对 SDS 修改后，len 的长度小于 1M，那么程序将分配和 len 相同长度的未使用空间。举个例子，如果 len=10，重新分配后，buf 的实际长度会变为 10(已使用空间)+10(额外空间)+1(空字符)=21。如果对 SDS 修改后 len 长度大于 1M，那么程序将分配 1M 的未使用空间。</font>

惰性空间释放：当对 SDS 进行缩短操作时，程序并不会回收多余的内存空间，而是使用 free 字段将这些字节数量记录下来不释放，后面如果需要 append 操作，则直接使用 free 中未使用的空间，减少了内存的分配。


# 字典-了解即可
Redis底层hash结构如下：
```c++
typedef struct dict{
      dictType *type;
    void *privdata;
    dictht ht[2];
    int trehashidx;
}


typedef struct dictht{
    //哈希表数组
    dectEntrt **table;
    //哈希表大小
    unsigned long size;
    //
    unsigned long sizemask;
    //哈希表已有节点数量
    unsigned long used;
}
```
重要的两个字段是 dictht 和 trehashidx
## Rehash
> Rehash解释：随着操作的不断执行， 哈希表保存的键值对会逐渐地增多或者减少， 为了让哈希表的负载因子（load factor）维持在一个合理的范围之内， 当哈希表保存的键值对数量太多或者太少时， 程序需要对哈希表的大小进行相应的扩展或者收缩。扩展和收缩哈希表的工作可以通过执行 rehash （重新散列）操作来完成

由上段代码，我们可知 dict 中存储了一个 dictht 的数组，长度为 2，表明这个数据结构中实际存储着两个哈希表 ht[0] 和 ht[1]，为什么要存储两张 hash 表呢？   
当然是为了Rehash,Rehash的过程
- 为 ht[1] 分配空间。如果是扩容操作，ht[1] 的大小为第一个大于等于 ht[0].used*2 的 2^n；如果是缩容操作，ht[1] 的大小为第一个大于等于 ht[0].used 的 2^n。
- 将 ht[0] 中的键值 Rehash 到 ht[1] 中。
- 当 ht[0] 全部迁移到 ht[1] 中后，释放 ht[0]，将 ht[1] 置为 ht[0]，并为 ht[1] 创建一张新表，为下次 Rehash 做准备。

## 渐进式 Rehash
上面提到的如果ht[0]全部移动到ht[1]中，如果数据量小很快，如果数据量很大则会有影响使用
所以redis采用了分多次、渐进式的迁移策略
- 为 ht[1] 分配空间，让字典同时拥有 ht[0] 和 ht[1] 两个哈希表。
- 字典中维护一个 rehashidx，并将它置为 0，表示 Rehash 开始。
- 在 Rehash 期间，每次对字典操作时，程序还顺便将 ht[0] 在 rehashidx 索引上的所有键值对 rehash 到 ht[1] 中，当 Rehash 完成后，将 rehashidx 属性+1。当全部 rehash 完成后，将 rehashidx 置为 -1，表示 rehash 完成。
注意，由于维护了两张 Hash 表，所以在 Rehash 的过程中内存会增长。另外，在 Rehash 过程中，字典会同时使用 ht[0] 和 ht[1]。

所以在删除、查找、更新时会在两张表中操作，在查询时会现在第一张表中查询，如果第一张表中没有，则会在第二张表中查询。但新增时一律会在 ht[1] 中进行，确保 ht[0] 中的数据只会减少不会增加。

# 跳跃表-了解即可
Zset 是一个有序的链表结构，其底层的数据结构是跳跃表 skiplist，其结构如下：
```c++
typedef struct zskiplistNode {
    //成员对象
   robj *obj;
    //分值
   double score;
    //后退指针
   struct zskiplistNode *backward;
    //层
   struct zskiplistLevel {
        struct zskiplistNode *forward;//前进指针
        unsigned int span;//跨度
   } level[];
 } zskiplistNode;

typedef struct zskiplist {
    //表头节点和表尾节点
   struct zskiplistNode *header, *tail;
    //表中节点的的数量
   unsigned long length;
    //表中层数最大的节点层数
   int level;
 } zskiplist;
```
<div align=center><img src=https://ws2.sinaimg.cn/large/0078bOVFgy1g0y2zae71yj30e8064405.jpg></div>

前进指针：用于从表头向表尾方向遍历。

后退指针：用于从表尾向表头方向回退一个节点，和前进指针不同的是，前进指针可以一次性跳跃多个节点，后退指针每次只能后退到上一个节点。

跨度：表示当前节点和下一个节点的距离，跨度越大，两个节点中间相隔的元素越多。

在查询过程中跳跃着前进。由于存在后退指针，如果查询时超出了范围，通过后退指针回退到上一个节点后仍可以继续向前遍历。

# 压缩列表-了解即可
压缩列表 ziplist 是为 Redis 节约内存而开发的，是列表键和字典键的底层实现之一。

当元素个数较少时，Redis 用 ziplist 来存储数据，当元素个数超过某个值时，链表键中会把 ziplist 转化为 linkedlist，字典键中会把 ziplist 转化为 hashtable。

ziplist 是由一系列特殊编码的连续内存块组成的顺序型的数据结构，ziplist 中可以包含多个 entry 节点，每个节点可以存放整数或者字符串。

<div align=center><img src=https://ws1.sinaimg.cn/large/0078bOVFgy1g0y37uuzoqj30u00dcwnf.jpg></div>

# 编码转化（掌握）
Redis 使用对象（redisObject）来表示数据库中的键值，当我们在 Redis 中创建一个键值对时，至少创建两个对象，一个对象是用做键值对的键对象，另一个是键值对的值对象。

例如我们执行 SET MSG XXX 时，键值对的键是一个包含了字符串“MSG“的对象，键值对的值对象是包含字符串”XXX”的对象。

redisObject 的结构如下：
```C++
typedef struct redisObject{
    //类型
   unsigned type:4;
   //编码
   unsigned encoding:4;
   //指向底层数据结构的指针
   void *ptr;
    //...
 }robj;
```
其中 type 字段记录了对象的类型，包含字符串对象、列表对象、哈希对象、集合对象、有序集合对象。  
ptr 指针字段指向对象底层实现的数据结构，而这些数据结构是由 encoding 字段决定的，每种对象至少有两种数据编码：

<div align=center><img src=https://ws1.sinaimg.cn/large/0078bOVFgy1g0y3ppam19j30u00h37ct.jpg></div>
可以通过 object encoding key 来查看对象所使用

## String 对象的编码转化
String 对象的编码可以是 int 或 raw，对于 String 类型的键值，如果我们存储的是纯数字，Redis 底层采用的是 int 类型的编码，如果其中包括非数字，则会立即转为 raw 编码：
```shell
127.0.0.1:6379> set str 1
OK
127.0.0.1:6379> object encoding str
"int"
127.0.0.1:6379> set str 1a
OK
127.0.0.1:6379> object encoding str
"raw"
127.0.0.1:6379>
```

## List 对象的编码转化
List 对象的编码可以是ziplist 或 linkedlist，对于 List 类型的键值，当列表对象同时满足以下两个条件时，采用 ziplist 编码：
- 列表对象保存的所有字符串元素的长度都小于 64 字节。
- 列表对象保存的元素个数小于 512 个。
如果不满足这两个条件的任意一个，就会转化为 linkedlist 编码。注意：这两个条件是可以修改的，在 redis.conf 中：
```ini
list-max-ziplist-entries 512
list-max-ziplist-value 64
```

## Set 类型的编码转化
Set 对象的编码可以是 intset 或 hashtable，intset 编码的结构对象使用整数集合作为底层实现，把所有元素都保存在一个整数集合里面。
```shell
127.0.0.1:6379> sadd set 1 2 3
(integer) 3
127.0.0.1:6379> object encoding set
"intset"
127.0.0.1:6379>
```
如果 set 集合中保存了非整数类型的数据时，Redis 会将 intset 转化为 hashtable：
```shell
127.0.0.1:6379> sadd set 1 2 3
(integer) 3
127.0.0.1:6379> object encoding set
"intset"
127.0.0.1:6379> sadd set a
(integer) 1
127.0.0.1:6379> object encoding set
"hashtable"
 127.0.0.1:6379>
```
当 Set 对象同时满足以下两个条件时，对象采用 intset 编码：
- 保存的所有元素都是整数值（小数不行）。
- Set 对象保存的所有元素个数小于 512 个。
不能满足这两个条件的任意一个，Set 都会采用 hashtable 存储。注意：第两个条件是可以修改的，在 redis.conf 中：
```ini
set-max-intset-entries 512
```

## Hash 对象的编码转化
Hash 对象的编码可以是 ziplist 或 hashtable，当 Hash 以 ziplist 编码存储的时候，保存同一键值对的两个节点总是紧挨在一起，键节点在前，值节点在后：
当 Hash 对象同时满足以下两个条件时，Hash 对象采用 ziplist 编码：
- Hash 对象保存的所有键值对的键和值的字符串长度均小于 64 字节。
- Hash 对象保存的键值对数量小于 512 个。
如果不满足以上条件的任意一个，ziplist 就会转化为 hashtable 编码。注意：这两个条件是可以修改的，在 redis.conf 中：
```ini
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
```
## Zset 对象的编码转化
Zset 对象的编码可以是 ziplist 或 zkiplist，当采用 ziplist 编码存储时，每个集合元素使用两个紧挨在一起的压缩列表来存储。

第一个节点存储元素的成员，第二个节点存储元素的分值，并且按分值大小从小到大有序排列。

当 Zset 对象同时满足一下两个条件时，采用 ziplist 编码：

- Zset 保存的元素个数小于 128。
- Zset 元素的成员长度都小于 64 字节。
如果不满足以上条件的任意一个，ziplist 就会转化为 zkiplist 编码。注意：这两个条件是可以修改的，在 redis.conf 中：
```ini
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
```