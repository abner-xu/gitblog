---
title: Go基础-信道
categories:
  - 后端
  - Golang
tags:
  - go基础
comments: true
toc: true
abbrlink: 90315ea4
date: 2019-01-21 22:20:39
---

信道是协程之间通信的管道，从一端发送数据，另一端接收数据。

# 信道声明
- `var c chan int`,声明了 nil 信道。nil 信道没什么作用，既不能发送数据也不能接受数据
- `c:=make(chan int)`,使用 make 函数创建了可用的信道 c。

---
# 读写数据
```go
c := make(chan int)
// 写数据
c <- data   

// 读数据
variable <- c  // 方式一
<- c              // 方式二
```

---


# 解决生产环境使用timeSleep
```go
func printHello(c chan bool) {
    fmt.Println("hello world goroutine")
    <- c    // 读取信道的数据
}
 
func main() {
    c := make(chan bool)
    go printHello(c)
    c <- true    // main 协程阻塞
    fmt.Println("main goroutine")
}
//output
hello world goroutine
main goroutine
```

--- 
# 死锁（只读不写或者只读不写）
```go
func main() {
    c := make(chan bool)
    c <- true    // 只写不读
    fmt.Println("main goroutine")
}
```
---

# 关闭信道与 for loop
```go
func printNums(ch chan int) {
    for i := 0; i < 10; i++ {
        ch <- i
    }
    close(ch)
}

func main() {
    ch := make(chan int)
    go printNums(ch)
    for {
        v, ok := <-ch
        if ok == false {     // 通过 ok 判断信道是否关闭
            fmt.Println(v, ok)
            break
        }
        fmt.Println(v, ok)
    }
}
```

--- 
# 缓冲信道和普通信道
**普通信道是`无缓冲的，读写信道会立马阻塞当前协程`。对于缓冲信道，写不会阻塞当前信道直到信道满了，同理，读操作也不会阻塞当前信道除非信道没数据**

# 总结
{% post_link Go/channel总结 [channel总结]%}