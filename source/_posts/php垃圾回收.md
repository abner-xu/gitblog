---
title: php垃圾回收引发的一些底层了解
categories:
  - 后端
  - PHP
tags:
  - PHPGC垃圾
  - 面试
comments: true
toc: true
date: 2019-03-09 13:47:23
---
# 底层的运行原理和机制
## 四层体系架构图
![底层](https://ws1.sinaimg.cn/large/0078bOVFgy1g0wp6w9yegj30ee0epdi4.jpg)

Zend引擎：Zend整体用纯C实现，是PHP的内核部分，它将php代码翻译(词法、语法解析等一系列编译过程)为可执行opcode的 处理并实现相应的处理方法、实现了基本的数据结构(如hashtable、oo)、内存分配及管理、提供了相应的api方法供外部调用，是一切的核心，所 有的外围功能均围绕Zend实现。

Extensions：围绕着Zend引擎，extensions通过组件式的方式提供各种基础服务，我们常见的各种内置函数(如array 系列)、标准库等都是通过extension来实现，用户也可以根据需要实现自己的extension以达到功能扩展、性能优化等目的(如贴吧正在使用的 PHP中间层、富文本解析就是extension的典型应用)。

Sapi：Sapi全称是Server Application Programming Interface，也就是服务端应用编程接口，Sapi通过一系列钩子函数，使得PHP可以和外围交互数据，这是PHP非常优雅和成功的一个设计，通过 sapi成功的将PHP本身和上层应用解耦隔离，PHP可以不再考虑如何针对不同应用进行兼容，而应用本身也可以针对自己的特点实现不同的处理方式。

上层应用：这就是我们平时编写的PHP程序，通过不同的sapi方式得到各种各样的应用模式，如通过webserver实现web应用、在命令行下以脚本方式运行等等。


# PHP执行的几个阶段
![阶段](https://ws3.sinaimg.cn/large/0078bOVFgy1g0whssv186j30u01ev0w1.jpg)

> PHP 是一门托管型语言，在 PHP 编程中，程序员不需要手工处理内存资源的分配与释放（使用 C 编写 PHP 或 Zend 扩展除外），这就意味着 PHP 本身实现了垃圾回收机制（Garbage Collection）。在[PHP官方网站](http://php.net/manual/zh/features.gc.php)可以看到对垃圾回收机制的介绍。
 
# 引用计数基本知识
PHP在内核中是通过zval这个结构体来存储变量的，在Zend/zend.h文件中找到了其定义：
PHP5定义如下
```$xslt
struct _zval_struct {
     union {
          long lval;
          double dval;
          struct {
               char *val;
               int len;
          } str;
          HashTable *ht;
          zend_object_value obj;
          zend_ast *ast;
     } value;
     zend_uint refcount__gc;
     zend_uchar type;
     zend_uchar is_ref__gc;
};
```
PHP7定义如下
```$xslt
struct _zval_struct {
    union {
        zend_long         lval;             /* long value */
        double            dval;             /* double value */
        zend_refcounted  *counted;
        zend_string      *str;
        zend_array       *arr;
        zend_object      *obj;
        zend_resource    *res;
        zend_reference   *ref;
        zend_ast_ref     *ast;
        zval             *zv;
        void             *ptr;
        zend_class_entry *ce;
        zend_function    *func;
        struct {
            uint32_t w1;
            uint32_t w2;
        } ww;
    } value;
    union {
        struct {
            ZEND_ENDIAN_LOHI_4(
                zend_uchar    type,         /* active type */
                zend_uchar    type_flags,
                zend_uchar    const_flags,
                zend_uchar    reserved)     /* call info for EX(This) */
        } v;
        uint32_t type_info;
    } u1;
    union {
        uint32_t     var_flags;
        uint32_t     next;                 /* hash collision chain */
        uint32_t     cache_slot;           /* literal cache slot */
        uint32_t     lineno;               /* line number (for ast nodes) */
        uint32_t     num_args;             /* arguments number for EX(This) */
        uint32_t     fe_pos;               /* foreach position */
        uint32_t     fe_iter_idx;          /* foreach iterator index */
    } u2;
};

```
我们定义一个PHP变量如下：
```$xslt
$var = "laruence";
$var_dup = $var;
unset($var);
```
1.  第一行代码创建了一个字符串变量，申请了一个大小为9字节的内存，保存了字符串”laruence”和一个NULL(\0)的结尾。
2.  第二行定义了一个新的字符串变量，并将变量var的值”复制”给这个新的变量。
3.  第三行unset了变量var
这样的代码在我们平时的脚本中是很常见的，如果PHP对于每一个变量赋值都重新分配内存，copy数据的话，那么上面的这段代码公要申请18个字节的内存空间，而我们也很容易的看出来，上面的代码其实根本没有必要申请俩份空间，PHP的开发者也看出来了：

PHP中的变量是用一个存储在symbol_table中的符号名，对应一个zval来实现的，比如对于上面的第一行代码，会在symbol_table中存储一个值”var”, 对应的有一个指针指向一个zval结构，变量值”laruence”保存在这个zval中，所以不难想象，对于上面的代码来说，我们完全可以让”var”和”var_dup”对应的指针都指向同一个zval就可以了。

PHP也是这样做的，这个时候就需要介绍过zval结构中的refcount字段了。

refcount,顾名思义，记录了当前的zval被引用的计数。

> 不准确但却通俗的说：
  refcount：多少个变量是一样的用了相同的值，这个数值就是多少。
  is_ref：bool类型，当refcount大于2的时候，其中一个变量用了地址&的形式进行赋值，好了，它就变成1了。
  
在 PHP 中可以通过 xdebug 扩展中提供的方法来查看变量的计数变化： 

**第一步：查看内部结构**
```$xslt
$name = "这是一段内存测试";
 xdebug_debug_zval('name');
会得到
name:(refcount=1, is_ref=0),string '这是一段内存测试' (length=18)
```
**第二步：查看内部结构**
```$xslt
$name = "这是一段内存测试";
$temp_name = $name;
xdebug_debug_zval('name');
会得到
name:(refcount=2, is_ref=0),string '这是一段内存测试' (length=18)
看到了吧，refcount＋1了。
```
**第三步：引用赋值**
```$xslt
$name = "这是一段内存测试";
$temp_name = &$name;
xdebug_debug_zval('name');
会得到
name:(refcount=2, is_ref=0),string '这是一段内存测试' (length=18)
看到了吧，refcount＋1了。
引用赋值会导致zval通过is_ref来标记是否存在引用的情况。
```
**第四步：数组型的变量**
```$xslt
$name = ['a'=>'这是一段', 'b'=>'内存测试'];
xdebug_debug_zval('name');
会得到
name:
(refcount=1, is_ref=0),
array (size=2)
  'a' => (refcount=1, is_ref=0),string '这是一段' (length=9)
  'b' => (refcount=1, is_ref=0),string '内存测试' (length=9)
还挺好理解的，对于数组来看是一个整体，对于内部kv来看又是分别独立的整体，各自都维护着一套zval的refount和is_ref。
```
**第五步：销毁变量**
```$xslt
$name = "这是一段内存测试";
$temp_name = $name;
xdebug_debug_zval('name');
unset($temp_name);
xdebug_debug_zval('name');
会得到
name:(refcount=2, is_ref=0),string '这是一段内存测试' (length=18)
name:(refcount=1, is_ref=0),string '这是一段内存测试' (length=18)
refcount计数减1，说明unset并非一定会释放内存，当有两个变量指向的时候，并非会释放变量占用的内存，只是refcount减1.
```

# PHP的内存管理机制

通过上面的案例，知道了zval的原理以后，接下来通过PHP来看一下内存管理机制是怎么样的

## 外在的内存变换

代码示例A：

```$xslt
//获取内存方法，加上true返回实际内存，不加则返回表现内存
var_dump(memory_get_usage());
$name = "这是一段内存测试";
var_dump(memory_get_usage());
unset($name);
var_dump(memory_get_usage());
```

会得到：

    int 1593248
    int 1593384
    int 1593248
    
大致过程：定义变量->内存增加->清除变量->内存恢复

## 潜在的内存变化
当执行：$name="这是一段内存测试"; 的时候，内存的分配做了2件事情：

1.  为变量名分配内存，存入符号表
2.  为变量分配内存

代码示例B：
```$xslt
var_dump(memory_get_usage());
for($i=0;$i<100;$i++)
{
    $a = "test".$i;
    $$a = "hello";    
}
var_dump(memory_get_usage());
for($i=0;$i<100;$i++)
{
    $a = "test".$i;
    unset($$a);    
}
var_dump(memory_get_usage());
```

会得到：

    int 1596864
    int 1612080
    int 1597680

这里可以发现内存并没有全部收回来

这里由于PHP核心数据Hashtable来说，由于未知性，定义的时候不可能一次性分配足够的内存块，所以初始分配的内存使用完成以后，进行扩容，而HashTable只扩容不减少，所以就出现了上面的情况：当存入100个变量的时候，符号表不够用了就进行一次扩容，当unset的时候只释放了"<font color=red>为变量值分配的内存</font>"，而"<font color=blue>为变量名分配的内存</font>"是在符号表的，符号表并没有缩减，所以没有收回来的内存是被符号表占去了

# 潜在的内存申请与释放设计

php和C语言一样，也是需要进行内存申请，只不过这些操作都封装在底层了，php使用者无感知。

首先我们要打破一个思维：php不像C语言那样，只有你显示的调用内存分配API才会有相关的内存分配。也就是说，在PHP中，我们看不到内存分配。

比如说
```php
$a="laruence";
```
隐式的内存分配点就有：
1. 为变量名分配内存，存入符号表
2. 为变量值分配内存

所以不能看表象

别怀疑php的unset确实能是否内存（当然还要结合引用和计数），导致这个释放不是C语言意义上的释放，不是交回给OS，对于PHP来说，它自身提供了一套和C语言对内存分配相似的内存管理API
```php
emalloc(size_t size);
efree(void *ptr);
ecalloc(size_t nmemb, size_t size);
erealloc(void *ptr, size_t size);
estrdup(const char *s);
estrndup(const char *s, unsigned int length);
```
这些API和C的API意义对应， 在PHP内部都是通过这些API来管理内存的。

当我们调用emalloc申请内存的时候，PHP并不是简单的向OS要内存， 而是会像OS要一个大块的内存, 然后把其中的一块分配给申请者，这样当再有逻辑来申请内存的时候， 就不再需要向OS申请内存了， 避免了频繁的系统调用。

比如如下的例子:
```php
var_dump(memory_get_usage(TRUE)); //注意获取的是real_size
$a = "laruence";
var_dump(memory_get_usage(TRUE));
unset($a);
var_dump(memory_get_usage(TRUE));
//输出
int(262144)
int(262144)
int(262144)
```
也就是我们在定义变量$a的时候, PHP并没有向系统申请新内存.

同样的, 在我们调用efree释放内存的时候, PHP也不会把内存还给OS, 而会把这块内存, 归入自己维护的空闲内存列表. 而对于小块内存来说, 更可能的是, 把它放到内存缓存列表中去(后记, 某些版本的PHP, 比如我验证过的PHP7.2, 在调用get_memory_usage()的时候, 不会减去内存缓存列表中的可用内存块大小, 导致看起来, unset以后内存不变).

# php中垃圾是如何定义的？
首先我们需要定义一下“垃圾”的概念，GC负责清理的垃圾是指变量的容器zval还存在，但是又没有任何变量名指向此zval。因此GC判断是否为垃圾的一个重要标准是有没有变量名指向变量容器zval。

假设我们有一段PHP代码，使用了一个临时变量$tmp存储了一个字符串，在处理完字符串之后，就不需要这个$tmp变量了，$tmp变量对于我们来说可以算是一个“垃圾”了，但是对于GC来说，$tmp其实并不是一个垃圾，$tmp变量对我们没有意义，但是这个变量实际还存在，$tmp符号依然指向它所对应的zval，GC会认为PHP代码中可能还会使用到此变量，所以不会将其定义为垃圾。

那么如果我们在PHP代码中使用完$tmp后，调用unset删除这个变量，那么$tmp是不是就成为一个垃圾了呢。很可惜，GC仍然不认为$tmp是一个垃圾，因为$tmp在unset之后，refcount减少1变成了0(这里假设没有别的变量和$tmp指向相同的zval),这个时候GC会直接将$tmp对应的zval的内存空间释放，$tmp和其对应的zval就根本不存在了。此时的$tmp也不是新的GC所要对付的那种“垃圾”。

# PHP垃圾回收的相关配置
可以通过修改配置文件 php.ini 中的 zend.enable_gc 来打开或关闭 PHP 的垃圾回收机制，也可以通过调用 gc_enable() 或 gc_disable() 打开或关闭 PHP 的垃圾回收机制。

在 PHP5.3 中即使关闭了垃圾回收机制，PHP 仍然会记录可能根到根缓冲区，只是当根缓冲区满额时，不会自动运行垃圾回收，当然，任何时候您都可以通过手工调用 gc_collect_cycles() 函数强制执行内存回收。

