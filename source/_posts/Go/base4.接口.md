---
title: Go基础-接口
categories:
  - 后端
  - Golang
tags:
  - go基础
comments: true
toc: true
abbrlink: 15a86a0a
date: 2018-01-20 22:20:39
---

# 什么是接口
在一些面向对象的编程语言中，例如 Java、PHP 等，接口定义了对象的行为，只指定了对象应该做什么。行为的具体实现取决于对象。

在 Go 语言中，接口是一组方法的集合，但不包含方法的实现、是抽象的，接口中也不能包含变量。当一个类型 T 提供了接口中所有方法的定义时，就说 T 实现了接口。接口指定类型应该有哪些方法，类型决定如何去实现这些方法。

--- 

# 接口声明
```go
type Shape interface {
    Area() float32
}
```
上面的代码定义了接口类型 Shape，接口中包含了一个不带参数、返回值为 float32  的方法 Area()。任何实现了方法 Area() 的类型 T，我们就说它实现了接口 Shape。
```go
func main() {
    var s Shape
    fmt.Println("value of s is", s)
    fmt.Printf("type of s is %T\n", s)
}

//output
value of s is <nil>
type of s is <nil>
```

---

# 接口的类型值

#### 静态类型和动态类型
- 变量的类型在声明时指定、且不能改变，称为`静态类型`。
- 接口类型的静态值就是接口本身。
- 接口没有静态值，它指向的是动态值。
- 接口类型的变量存的是实现接口的类型的值。该值就是接口的动态值，实现接口的类型就是接口的动态类型。
```go
type Iname interface {
    Mname()
}

type St1 struct {}
func (St1) Mname() {}
type St2 struct {}
func (St2) Mname() {}

func main() {
    var i Iname = St1{}
    fmt.Printf("type is %T\n",i)
    fmt.Printf("value is %v\n",i)
    i = St2{}
    fmt.Printf("type is %T\n",i)
    fmt.Printf("value is %v\n",i)
}
//output 
type is main.St1
value is {}
type is main.St2
value is {}
```
变量`i`的静态类型是`Iname`,是不能改变的。动态类型却是不固定的。第一次分配是 `St1` 第二次是`St2`,动态值都是`空结构体`
有时候，接口的动态类型又称为`具体类型`，当访问的时候，返回的是底层的动态值类型

#### nil值
```go
type Iname interface {
    Mname()
}
type St struct {}
func (St) Mname() {}
func main() {
    var t *St
    if t == nil {
        fmt.Println("t is nil")
    } else {
        fmt.Println("t is not nil")
    }
    var i Iname = t
    fmt.Printf("%T\n", i)
    if i == nil {
        fmt.Println("i is nil")
    } else {
        fmt.Println("i is not nil")
    }
    fmt.Printf("i is nil pointer:%v",i == (*St)(nil))
}
//output
t is nil
*main.St
i is not nil
i is nil pointer:true
```
`当且仅当动态值和动态类型都为 nil 时，接口类型值才为 nil`。上面的代码，给变量 i  赋值之后，i 的动态值是 nil，但是动态类型却是 *St， i 是一个 nill 指针，所以条件不成立。

Go语言规范：
```go
 var x interface{}  // x is nil and has static type interface{}
 var v *T           // v has value nil, static type *T
 x = 42             // x has value 42 and dynamic type int
 x = v              // x has value (*T)(nil) and dynamic type *T
```

---

# 实现接口
```go
type Shape interface {
    Area() float32
}

type Rect struct {
    width  float32
    height float32
}
//结构体实现了接口
func (r Rect) Area() float32 {
    return r.width * r.height
}

func main() {
    var s Shape
    s = Rect{5.0, 4.0}
    r := Rect{5.0, 4.0}
    fmt.Printf("type of s is %T\n", s)
    fmt.Printf("value of s is %v\n", s)
    fmt.Println("area of rectange s", s.Area())
    fmt.Println("s == r is", s == r)
}
//output
type of s is main.Rect
value of s is {5 4}
area of rectange s 20
s == r is true
```

# 空接口
```go
func Println(a ...interface{}) (n int, err error) {}
```
例如：
```go
type MyString string
type Rect struct {
    width  float32
    height float32
}
func explain(i interface{}) {
    fmt.Printf("type of s is %T\n", i)
    fmt.Printf("value of s is %v\n\n", i)
}
func main() {
    ms := MyString("Seekload")
    r := Rect{5.0, 4.0}
    explain(ms)
    explain(r)
}
//output
type of s is main.MyString
value of s is Seekload

type of s is main.Rect
value of s is {5 4}
```
上面的代码，创建了自定义的字符串类型 MyString 、结构体 Rect 和 explain() 函数。explain() 函数的形参是空接口，所以可以接收任意类型的值。


# 实现多个接口
```go
type Shape interface {
	Area() float32
}
 
type Object interface {
	Perimeter() float32
}

type Circle struct {
	radius float32
}

func (c Circle) Area() float32 {
    return math.Pi * (c.radius * c.radius)
}

func (c Circle) Perimeter() float32 {
   return 2 * math.Pi * c.radius
}

func main() {
    c := Circle{3}
    var s Shape = c
    var p Object = c
    fmt.Println("area: ", s.Area())
    fmt.Println("perimeter: ", p.Perimeter())
}
//output
area:  28.274334
perimeter:  18.849556
```