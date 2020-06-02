---
title: Go基础-iota
categories:
  - 后端
  - Golang
tags:
  - go基础
comments: true
toc: true
abbrlink: 15af66ed
date: 2019-01-27 22:00:40
---

`iota-go语言中的常量计数器，只能在常量表达式中使用`

## iota只能在常量的表达式中使用。
```go
fmt.Println(iota) 
编译错误： undefined: iota
```

## 每次 const 出现时，都会让 iota 初始化为0.【自增长】
```go
const a = iota // a=0
const (
  b = iota          //b=0
  c                      //c=1
)
```

## 枚举类型定义
```go
type Weekday int
const (
    Sunday Weekday = iota
    Monday
    Tuesday
    Wednesday
    Thursday
    Friday
    Saturday
)

//可以类似调用枚举类一样调用
println(Weekday(Saturday))   

```

## 可跳过的值
```go
type AudioOutput int
const (
    OutMute AudioOutput = iota // 0
    OutMono                       // 1
    OutStereo                     // 2
    _
    _
    OutSurround                // 5
)
```

## 位掩码表达式
`iota 可以做更多事情，而不仅仅是 increment。更精确地说，iota 总是用于 increment，但是它可以用于表达式，在常量中的存储结果值。`
```go
const (
    IgEggs Allergen = 1 << iota // 1 << 0 which is 00000001
    IgChocolate                             // 1 << 1 which is 00000010
    IgNuts                                       // 1 << 2 which is 00000100
    IgStrawberries                        // 1 << 3 which is 00001000
    IgShellfish                                // 1 << 4 which is 00010000
)
```

## 定义bit单位
```go
type ByteSize float64
const (
    _           = iota                   // ignore first value by assigning to blank identifier
    KB ByteSize = 1 << (10 * iota)       // 1 << (10*1)
    MB                                   // 1 << (10*2)
    GB                                   // 1 << (10*3)
    TB                                   // 1 << (10*4)
    PB                                   // 1 << (10*5)
    EB                                   // 1 << (10*6)
    ZB                                   // 1 << (10*7)
    YB                                   // 1 << (10*8)
)
```

## 定义在一行的情况(iota 在下一行增长，而不是立即取得它的引用)
`注意他们是逗号分隔常量，并不是换行`
1. 场景一
```go
const (
    Apple, Banana = iota , iota 
    Cherimoya, Durian
    Elderberry, Fig
)
// Apple: 0, Banana: 0,
// Cherimoya: 1, Durian: 1, 
// Elderberry: 2, Fig: 2
```
2. 场景二,每一换行都按照前一行的表达式进行增加
```go
const (
    Apple, Banana = iota+1 , iota+1 
    Cherimoya, Durian
    Elderberry, Fig
)
// Apple: 1, Banana: 1,
// Cherimoya: 2, Durian: 2, 
// Elderberry: 3, Fig: 3
```
## 中间插队
```go
const (
    i = iota
    j = 3.14
    k = iota
    l
)
那么打印出来的结果是 i=0,j=3.14,k=2,l=3
```
