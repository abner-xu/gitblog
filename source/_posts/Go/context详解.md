---
title: Go-context详解
categories:
  - 后端
  - Golang
comments: true
toc: true
abbrlink: 5f8522f1
date: 2019-11-06 13:31:17
---



# 背景

golang在1.6.2的时候还没有自己的context，在1.7的版本中就把golang.org/x/net/context包被加入到了官方的库中。golang 的 Context包，是专门用来简化对于处理单个请求的多个goroutine之间与请求域的数据、取消信号、截止时间等相关操作，这些操作可能涉及多个 API 调用。

比如有一个网络请求Request，每个Request都需要开启一个goroutine做一些事情，这些goroutine又可能会开启其他的goroutine。这样的话， 我们就可以通过Context，来跟踪这些goroutine，并且通过Context来控制他们的目的，这就是Go语言为我们提供的Context，中文可以称之为“上下文”。

另外一个实际例子是，在Go服务器程序中，每个请求都会有一个goroutine去处理。然而，处理程序往往还需要创建额外的goroutine去访问后端资源，比如数据库、RPC服务等。由于这些goroutine都是在处理同一个请求，所以它们往往需要访问一些共享的资源，比如用户身份信息、认证token、请求截止时间等。而且如果请求超时或者被取消后，所有的goroutine都应该马上退出并且释放相关的资源。这种情况也需要用Context来为我们取消掉所有goroutine

如果要使用可以通过 go get golang.org/x/net/context 命令获取这个包。

# Context原理
Context 的调用应该是链式的，通过`WithCancel`，`WithDeadline`，`WithTimeout`或`WithValue`派生出新的 Context.当父 Context 被取消时，其派生的所有 Context 都将取消.

通过`context.WithXXX`都将返回新的 Context 和 CancelFunc.调用 CancelFunc 将取消子代，移除父代对子代的引用，并且停止所有定时器.未能调用 CancelFunc 将泄漏子代，直到父代被取消或定时器触发.go vet工具检查所有流程控制路径上使用 CancelFuncs.

# 遵循规则
遵循以下规则，以保持包之间的接口一致，并启用静态分析工具以检查上下文传播.
- 不要将 Contexts 放入结构体，相反`context`应该作为第一个参数传入，命名为`ctx. func DoSomething（ctx context.Context，arg Arg）error { // ... use ctx ... }`
- 即使函数允许，也不要传入`nil`的 Context.如果不知道用哪种 Context，可以使用`context.TODO()`.
- 使用context的Value相关方法只应该用于在程序和接口中传递的和请求相关的元数据，不要用它来传递一些可选的参数.
- 相同的 Context 可以传递给在不同的goroutine；Context 是并发安全的.

# Context包
Context结构

```go
type Context interface {
    // 在Context超时或取消时（即结束了）返回一个关闭的channel
    // 即如果当前Context超时或取消时，Done方法会返回一个channel，然后其他地方就可以通过判断Done方法是否有返回（channel），如果有则说明Context已结束
    // 故其可以作为广播通知其他相关方本Context已结束，请做相关处理.
    Done() <-chan struct{}

    // 返回Context取消的原因
    Err() error

    // 返回Context的超时时间（超时返回场景）
    Deadline() (deadline time.Time, ok bool)

    // 值返回与键关联的值，如果没有则返回nil。
    Value(key interface{}) interface{}
}
```

所有方法

```go
func Background() Context
func TODO() Context

func WithCancel(parent Context) (ctx Context, cancel CancelFunc)
func WithDeadline(parent Context, deadline time.Time) (Context, CancelFunc)
func WithTimeout(parent Context, timeout time.Duration) (Context, CancelFunc)
func WithValue(parent Context, key, val interface{}) Context
```

上面可以看到Context是一个接口，想要使用就得实现其方法.在context包内部已经为我们实现好了两个空的Context，可以通过调用Background()和TODO()方法获取.一般的将它们作为Context的根，往下派生.

# WithCancel 例子
WithCancel 以一个新的 Done channel 返回一个父 Context 的拷贝.
```go
 func WithCancel(parent Context) (ctx Context, cancel CancelFunc) {
         c := newCancelCtx(parent)
         propagateCancel(parent, &c)
         return &c, func() { c.cancel(true, Canceled) }
     }
     
     // newCancelCtx returns an initialized cancelCtx.
     func newCancelCtx(parent Context) cancelCtx {
         return cancelCtx{
             Context: parent,
             done:    make(chan struct{}),
         }
     }
```
此示例演示使用一个可取消的上下文，以防止 goroutine 泄漏.示例函数结束时，defer 调用 cancel 方法，gen goroutine 将返回而不泄漏.
```go
package main

import (
    "context"
    "fmt"
)

func main() {
    gen := func(ctx context.Context) <-chan int {
        dst := make(chan int)
        n := 1
        go func() {
            for {
                select {
                case <-ctx.Done():
                    return // returning not to leak the goroutine
                case dst <- n:
                    n++
                }
            }
        }()
        return dst
    }

    ctx, cancel := context.WithCancel(context.Background())
    defer cancel() // cancel when we are finished consuming integers

    for n := range gen(ctx) {
        fmt.Println(n)
        if n == 5 {
            break
        }
    }
}
```
# WithDeadline 例子
```go
  func WithDeadline(parent Context, deadline time.Time) (Context, CancelFunc) {
         if cur, ok := parent.Deadline(); ok && cur.Before(deadline) {
             // The current deadline is already sooner than the new one.
             return WithCancel(parent)
         }
         c := &timerCtx{
             cancelCtx: newCancelCtx(parent),
             deadline:  deadline,
         }
   ......
```
可以清晰的看到，当派生出的子 Context 的deadline在父Context之后，直接返回了一个父Context的拷贝.故语义上等效为父.

WithDeadline 的最后期限调整为不晚于 d 返回父上下文的副本.如果父母的截止日期已经早于 d，WithDeadline （父，d） 是在语义上等效为父.返回的上下文完成的通道关闭的最后期限期满后，返回的取消函数调用时，或当父上下文完成的通道关闭，以先发生者为准.

看看官方的例子：
```go
package main

import (
    "context"
    "fmt"
    "time"
)

func main() {
    d := time.Now().Add(50 * time.Millisecond)
    ctx, cancel := context.WithDeadline(context.Background(), d)

    //即使ctx将会过期，还是最好将其调用
    //在任何情况下都具有取消功能。 否则可能会使
    //上下文及其父对象的生存时间超出了必要。
    defer cancel()

    select {
    case <-time.After(1 * time.Second):
        fmt.Println("overslept")
    case <-ctx.Done():
        fmt.Println(ctx.Err())
    }
}
```

# WithTimeout 例子
```go
func WithTimeout(parent Context, timeout time.Duration) (Context, CancelFunc) {
         return WithDeadline(parent, time.Now().Add(timeout))
     }
```
官方例子：
```go
package main

import (
    "context"
    "fmt"
    "time"
)

func main() {
    // Pass a context with a timeout to tell a blocking function that it
    // should abandon its work after the timeout elapses.
    ctx, cancel := context.WithTimeout(context.Background(), 50*time.Millisecond)
    defer cancel()

    select {
    case <-time.After(1 * time.Second):
        fmt.Println("overslept")
    case <-ctx.Done():
        fmt.Println(ctx.Err()) // prints "context deadline exceeded"
    }
}
```
# WithValue
```go
  func WithValue(parent Context, key, val interface{}) Context {
         if key == nil {
             panic("nil key")
         }
         if !reflect.TypeOf(key).Comparable() {
             panic("key is not comparable")
         }
         return &valueCtx{parent, key, val}
     }
```
WithValue 返回的父与键关联的值在 val 的副本.

使用上下文值仅为过渡进程和 Api 的请求范围的数据，而不是将可选参数传递给函数.

提供的键必须是可比性和应该不是字符串类型或任何其他内置的类型以避免包使用的上下文之间的碰撞.WithValue 用户应该定义自己的键的类型.为了避免分配分配给接口 {} 时，上下文键经常有具体类型结构 {}.另外，导出的上下文关键变量静态类型应该是一个指针或接口.

看看官方例子：
```go
package main

import (
    "context"
    "fmt"
)

func main() {
    type favContextKey string

    f := func(ctx context.Context, k favContextKey) {
        if v := ctx.Value(k); v != nil {
            fmt.Println("found value:", v)
            return
        }
        fmt.Println("key not found:", k)
    }

    k := favContextKey("language")
    ctx := context.WithValue(context.Background(), k, "Go")

    f(ctx, k)
    f(ctx, favContextKey("color"))
}
```

> 文章来源：https://mojotv.cn/2019/06/26/golang-context