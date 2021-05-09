---
title: go语言编程模式
categories:
  - 后端
  - Golang
comments: true
toc: true
abbrlink: 5e42e587
date: 2021-05-06 02:45:37
---
# 性能提示

- 如果需要把数字转换成字符串，使用 strconv.Itoa() 比 fmt.Sprintf() 要快一倍左右。
- 尽可能避免把String转成[]Byte ，这个转换会导致性能下降。
- 如果在 for-loop 里对某个 Slice 使用 append()，请先把 Slice 的容量扩充到位，这样可以避免内存重新分配以及系统自动按 2 的 N 次方幂进行扩展但又用不到的情况，从而避免浪费内存。
- 使用StringBuffer 或是StringBuild 来拼接字符串，性能会比使用 + 或 +=高三到四个数量级。
- 尽可能使用并发的 goroutine，然后使用 sync.WaitGroup 来同步分片操作。
- 避免在热代码中进行内存分配，这样会导致 gc 很忙。尽可能使用 sync.Pool 来重用对象。
- 使用 lock-free 的操作，避免使用 mutex，尽可能使用 sync/Atomic包
- 使用 I/O 缓冲，I/O 是个非常非常慢的操作，使用 bufio.NewWrite() 和 bufio.NewReader() 可以带来更高的性能。
- 对于在 for-loop 里的固定的正则表达式，一定要使用 regexp.Compile() 编译正则表达式。性能会提升两个数量级。
- 如果你需要更高性能的协议，就要考虑使用 protobuf 或 msgp 而不是 JSON，因为 JSON 的序列化和反序列化里使用了反射。
- 你在使用 Map 的时候，使用整型的 key 会比字符串的要快，因为整型比较比字符串比较要快。

# 接口编程
```go

type Country struct {
    Name string
}

type City struct {
    Name string
}

type Printable interface {
    PrintStr()
}
func (c Country) PrintStr() {
    fmt.Println(c.Name)
}
func (c City) PrintStr() {
    fmt.Println(c.Name)
}

c1 := Country {"China"}
c2 := City {"Beijing"}
c1.PrintStr()
c2.PrintStr()
```
可以看到，这段代码中使用了一个 Printable 的接口，而 Country 和 City 都实现了接口方法 PrintStr() 把自己输出。然而，这些代码都是一样的，能不能省掉呢？其实，我们可以使用“结构体嵌入”的方式来完成这个事，如下所示：
```go

type WithName struct {
    Name string
}

type Country struct {
    WithName
}

type City struct {
    WithName
}

type Printable interface {
    PrintStr()
}

func (w WithName) PrintStr() {
    fmt.Println(w.Name)
}

c1 := Country {WithName{ "China"}}
c2 := City { WithName{"Beijing"}}
c1.PrintStr()
c2.PrintStr()
```
引入一个叫 WithName的结构体，但是这会带来一个问题：在初始化的时候变得有点乱。那么，有没有更好的方法呢？再来看另外一个解。
```go

type Country struct {
    Name string
}

type City struct {
    Name string
}

type Stringable interface {
    ToString() string
}
func (c Country) ToString() string {
    return "Country = " + c.Name
}
func (c City) ToString() string{
    return "City = " + c.Name
}

func PrintStr(p Stringable) {
    fmt.Println(p.ToString())
}

d1 := Country {"USA"}
d2 := City{"Los Angeles"}
PrintStr(d1)
PrintStr(d2)
```
在这段代码中，我们可以看到，我们使用了一个叫Stringable 的接口，我们用这个接口把“业务类型” Country 和 City 和“控制逻辑” Print() 给解耦了。于是，只要实现了Stringable 接口，都可以传给 PrintStr() 来使用。

# 接口完整性检查
```go

type Shape interface {
    Sides() int
    Area() int
}
type Square struct {
    len int
}
func (s* Square) Sides() int {
    return 4
}
func main() {
    s := Square{len: 5}
    fmt.Printf("%d\n",s.Sides())
}
```
可以看到，Square 并没有实现 Shape 接口的所有方法，程序虽然可以跑通，但是这样的编程方式并不严谨，如果我们需要强制实现接口的所有方法，那该怎么办呢？
```go
var _ Shape = (*Square)(nil)
```
声明一个 _ 变量（没人用）会把一个 nil 的空指针从 Square 转成 Shape，这样，如果没有实现完相关的接口方法，编译器就会报错：
> cannot use (*Square)(nil) (type *Square) as type Shape in assignment: *Square does not implement Shape (missing Area method)

# Functional Options 编程模式
```go
package main

import (
	"crypto/tls"
	"fmt"
	"time"
)

type Option func(*Server)

type Server struct {
	Addr     string
	Port     int
	Protocol string
	Timeout  time.Duration
	MaxConns int
	TLS      *tls.Config
}

func Protocol(p string) Option {
	return func(s *Server) {
		s.Protocol = p
	}
}
func Timeout(timeout time.Duration) Option {
	return func(s *Server) {
		s.Timeout = timeout
	}
}
func MaxConns(maxconns int) Option {
	return func(s *Server) {
		s.MaxConns = maxconns
	}
}
func TLS(tls *tls.Config) Option {
	return func(s *Server) {
		s.TLS = tls
	}
}
func NewService(addr string, port int, options ...func(*Server)) (*Server, error) {
	srv := Server{
		Addr:     addr,
		Port:     port,
		Protocol: "tcp",
		Timeout:  30 * time.Second,
		MaxConns: 1000,
		TLS:      nil,
	}
	for _, option := range options {
		option(&srv)
	} //...
	return &srv, nil
}

func main() {
	server, _ := NewService("localhost", 80, Protocol("ftp"),Timeout(5*10))
	fmt.Println(server)
}

```

# Map,Reduce,Filter 模式
```go

type Employee struct {
    Name     string
    Age      int
    Vacation int
    Salary   int
}

var list = []Employee{
    {"Hao", 44, 0, 8000},
    {"Bob", 34, 10, 5000},
    {"Alice", 23, 5, 9000},
    {"Jack", 26, 0, 4000},
    {"Tom", 48, 9, 7500},
    {"Marry", 29, 0, 6000},
    {"Mike", 32, 8, 4000},
}


func EmployeeCountIf(list []Employee, fn func(e *Employee) bool) int {
    count := 0
    for i, _ := range list {
        if fn(&list[i]) {
            count += 1
        }
    }
    return count
}

func EmployeeFilterIn(list []Employee, fn func(e *Employee) bool) []Employee {
    var newList []Employee
    for i, _ := range list {
        if fn(&list[i]) {
            newList = append(newList, list[i])
        }
    }
    return newList
}

func EmployeeSumIf(list []Employee, fn func(e *Employee) int) int {
    var sum = 0
    for i, _ := range list {
        sum += fn(&list[i])
    }
    return sum
}

//统计有多少员工大于 40 岁

old := EmployeeCountIf(list, func(e *Employee) bool {
    return e.Age > 40
})
fmt.Printf("old people: %d\n", old)
//old people: 2
```

