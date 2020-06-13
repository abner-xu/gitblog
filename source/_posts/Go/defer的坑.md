---
title: Go 中 defer坑
categories:
  - 后端
  - Golang
comments: true
toc: true
date: 2019-08-28 17:02:04
---
# defer nil函数
```go
func() {
    var run func() = nil
    defer run()
    
    fmt.Println("runs")
}
//output
runs
panic: runtime error: invalid memory address or nil pointer dereference
```
名为 func 的函数一直运行至结束，然后 defer 函数会被执行且会因为值为 nil 而产生 panic 异常。然而值得注意的是，run() 的声明是没有问题，因为在外围函数运行完成后它才会被调用。

---

# 循环中使用defer
`慎重在循环中使用defer`，因为结果出人意料
```go
func demo(){
	for{
		row,err:=db.Query("select .....")
		if err!=nil{
			...
		}
		defer row.close()
	}
}
```
在上面的例子中，defer row.Close() 在循环中的延迟函数会在函数结束过后运行，而不是每次 for 循环结束之后。这些延迟函数会不停地堆积到延迟调用栈中，最终可能会导致一些不可预知的问题。
- 解决方案1：不使用defer
```go
func demo(){
	for{
		row,err:=db.Query("select .....")
		if err!=nil{
			...
		}
		row.close()
	}
}
```
- 解决方案2：移交给函数
这样每次匿名函数执行完，会执行defer
```go
func demo(){
	for{
		func(){
			row,err:=db.Query("select .....")
            if err!=nil{
                ...
            }
            defer row.close()
		}()
	}
}
```

## 循环Z-A(倒叙)
```go
func main() {
    for i := 0; i < 4; i++ {
        defer fmt.Print(i)
    }
}
//output
3
2
1
0
```



---

# 延迟调用含有闭包的函数
```go
type database struct{}

func (db *database) connect() (disconnect func()) {
    fmt.Println("connect")
    return func() {
        fmt.Println("disconnect")
    }
}

//运行 
db := &database{}
defer db.connect()

fmt.Println("query db...")

//output
query db...
connect
```
最终 disconnect 并没有输出，最后只有 connect ，这是一个 bug，最终的情况是 connect() 执行结束后，其执行域得以被保存起来，但内部的闭包并不会被执行。

- 解决方案
```go

func() {
    db := &database{}  close := db.connect()
    defer close()
    fmt.Println("query db...")
}

```
---

# 在执行块中使用 defer
想要在执行块执行结束后执行在块内延迟调用的函数，但事实并非如此，它们只会在块所属的函数执行结束后才被执行，这种情况适用于所有的代码块除了上文的函数块例如，for，switch 等
```go
func main() {
    {
        defer func() {
            fmt.Println("block: defer runs")
        }()
            
        fmt.Println("block: ends")
    }
    
    fmt.Println("main: ends")
}
//output
block: ends
main: ends
block: defer runs
```
- 解决方案
```go
func main() {
    func() {
        defer func() {
            fmt.Println("func: defer runs")
        }()
    
        fmt.Println("func: ends")
    }()
    
    fmt.Println("main: ends")
}
```

--- 
