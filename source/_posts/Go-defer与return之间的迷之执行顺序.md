---
title: Go 中 defer 与 return 之间的迷之执行顺序
categories:
  - 后端
  - Golang
comments: true
toc: true
date: 2019-06-24 17:02:04
---
偶然间发现了一个有意思的地方：在使用`defer`时，匿名返回值的函数和命名返回值的函数的返回结果是不一样的。具体见如下代码:
```go
//
// defer_test1.go
// Copyright (C) 2019 bryce <pyplgo@gmail.com>
//
// Distributed under terms of the MIT license.
//

package main

import "fmt"

func WithoutNamedReturnValue() int {
    var i int
    defer func() {
        i++
        fmt.Println("defer2 in WithoutNamedReturnValu", i)
    }()

    defer func() {
        i++
        fmt.Println("defer1 in WithoutNamedReturnValu", i)
    }()

    return i
}

func WithNamedReturnValue() (j int) {
    defer func() {
        j++
        fmt.Println("defer2 in WithNamedReturnValu", j)
    }()

    defer func() {
        j++
        fmt.Println("defer1 in WithNamedReturnValu", j)
    }()

    return j
}

func main() {
    fmt.Println(WithoutNamedReturnValue())
    fmt.Println(WithNamedReturnValue())
}

```
```go
//output
// 结果1
defer1 in WithoutNamedReturnValu 1
defer2 in WithoutNamedReturnValu 2
0

//结果2
defer1 in WithNamedReturnValu 1
defer2 in WithNamedReturnValu 2
2
```
可以看出，命名返回值的函数的返回值被`defer`修改了。在 Go Tour 中，官方在介绍`defer`时是这么说的：

> A defer statement defers the execution of a function until the surrounding function returns. (翻译：deferred语句将函数的执行推迟到周围函数返回时执行。)

如果按照这个理解，`defer`应该没有修改函数返回值的可能，因为`defer`是 until the surrounding function returns 才执行的。然后查阅官方给的<a href="https://blog.golang.org/defer-panic-and-recover">补充材料</a>，然后发现`defer`的执行有以下三个规则：
```html
1、 A deferred function’s arguments are evaluated when the defer statement is evaluated.（当计算deferred语句时，将计算deferred函数的参数。）

2、 Deferred function calls are executed in Last In First Out order after the surrounding function returns.（延迟函数调用是在周围函数返回后按Last - in - First - Out顺序执行的。）

3、 Deferred functions may read and assign to the returning function’s named return values.（延迟函数可以读取并分配返回函数的指定返回值。）

```
这个第三点就是出现文中开头代码结果 2 的原因。那么为什么结果 1 中`defer`没有修改返回值呢？我们可以推测，其实在函数最终返回前，`defer`函数就已经执行了，在结果 1 中，由于`defer`函数是对函数内部变量`i`进行操作，所以没有影响到返回值。在结果 2 
中，由于返回值已经被提前声明，所以`defer`函数能够在`return`语句对返回值赋值之后，继续对返回值进行操作。

总结一下就是，函数的整个返回过程应该是：
- return对返回变量赋值，如果是匿名返回值就先声明再赋值；
- 执行defer函数；
- return携带返回值返回。