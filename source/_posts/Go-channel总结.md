---
title: Go-channel总结
categories:
  - 分类1
  - 分类2
tags:
  - 标签1
comments: true
toc: true
abbrlink: a9a93a3c
date: 2019-11-06 15:28:28
---
>本文收集来源： http://lessisbetter.site/2019/01/20/golang-channel-all-usage/

# channel的使用场景
把channel用在数据流动的地方：
- 消息传递、消息过滤
- 信号广播
- 事件订阅与广播
- 请求、响应转发
- 任务分发
- 结果汇总
- 并发控制
- 同步与异步

# channel的基本操作和注意事项
channel 存在3种状态
1.  nil,未初始化，刚刚申明或者手动复制为nil
2.  active，正常运行中的可读可写
3.  closed,关闭时，**千万不要认为关闭以后，channel的值是nil**
channel 可进行3种操作
1.  读
2.  写
3.  关闭
3种状态存在9种情况

操作 | nil的channel |  正常channel  |  已关闭channel  
-|-|-|-
<- ch | 阻塞 | 成功or阻塞 | 读到零值 
ch <- | 阻塞 | 成功or阻塞 | panic 
close(ch) | 	panic | 成功 | panic 

对于nil通道的情况，也并非完全遵循上表，有1个特殊场景：当nil的通道在select的某个case中时，这个case会阻塞，但不会造成死锁

# 下面介绍使用channel的10种常用操作
## 使用for range读channel

### 场景

当需要不断从channel读取数据时。

### 原理：

使用for-range读取channel，这样既安全又便利，当channel关闭时，for循环会自动退出，无需主动监测channel是否关闭，可以防止读取已经关闭的channel，造成读到数据为通道所存储的数据类型的零值。

### 用法：
```go
for x := range ch{
    fmt.Println(x)
}
```

## 使用v,ok := <-ch + select操作判断channel是否关闭

### 场景

 `v,ok := <-ch + select`操作判断channel是否关闭
### 原理：

ok的结果和含义：
```
- `true`：读到通道数据，不确定是否关闭，可能channel还有保存的数据，但channel已关闭。
- `false`：通道关闭，无数据读到。
```
从关闭的channel读值读到是channel所传递数据类型的零值，这个零值有可能是发送者发送的，也可能是channel关闭了。

`_, ok := <-ch`与select配合使用的，当ok为false时，代表了channel已经close。

下面解释原因，`_,ok := <-ch`对应的函数是`func chanrecv(c *hchan, ep unsafe.Pointer, block bool) (selected, received bool)`，入参block含义是当前goroutine是否可阻塞，当block为false代表的是select操作，不可阻塞当前goroutine的在channel操作，否则是普通操作（即`_, ok`不在select中）。返回值selected代表当前操作是否成功，主要为select服务，返回**received代表是否从channel读到有效值。**它有3种返回值情况：
- block为false，即执行select时，如果channel为空，返回(false,false)，代表select操作失败，没接收到值。
- 否则，如果channel已经关闭，并且没有数据，ep即接收数据的变量设置为零值，返回(true,false)，代表select操作成功，但channel已关闭，没读到有效值。
- 否则，其他读到有效数据的情况，返回(true,ture)。

我们考虑_, ok := <-ch和select结合使用的情况。

情况1：当chanrecv返回(false,false)时，本质是select操作失败了，所以相关的case会阻塞，不会执行，比如下面的代码：
```go

func main() {
	ch := make(chan int)
	select {
	case v, ok := <-ch:
		fmt.Printf("v: %v, ok: %v\n", v, ok)
	default:
		fmt.Println("nothing")
	}
}

// 结果：
// nothing
```

情况2：下面的结果会是零值和false：
```go
func main() {
	ch := make(chan int)

	// 增加关闭
	close(ch)

	select {
	case v, ok := <-ch:
		fmt.Printf("v: %v, ok: %v\n", v, ok)
	}
}

// v: 0, ok: false
```
情况3的received为true，即_, ok中的ok为true，不做讨论了，只讨论ok为false的情况。

最后ok为false的时候，只有情况2，此时channel必然已经关闭，我们便可以在select中用ok判断channel是否已经关闭。


### 用法：
```go
func main() {
	ch := make(chan int, 1)

	// 发送1个数据关闭channel
	ch <- 1
	close(ch)
	print("close channel\n")

	// 不停读数据直到channel没有有效数据
	for {
		select {
		case v, ok := <-ch:
			print("v: ", v, ", ok:", ok, "\n")
			if !ok {
				print("channel is close\n")
				return
			}	
		default:
			print("nothing\n")
		}
	}
}

// 结果
// close channel
// v: 1, ok:true
// v: 0, ok:false
// channel is close
```