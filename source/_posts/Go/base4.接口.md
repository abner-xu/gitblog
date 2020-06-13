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
date: 2019-01-20 22:20:39
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
`当且仅当动态值和动态类型都为 nil 时，接口类型值才为 nil`。上面的代码，给变量 i  赋值之后，i 的动态值是 nil，但是动态类型却是 *St， i 是一个 nil 指针，所以条件不成立。

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

---

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

---

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
如果修改
```go
fmt.Println("area: ", p.Area())
fmt.Println("perimeter: ", s.Perimeter())
//output
p.Area undefined (type Object has no field or method Area)
s.Perimeter undefined (type Shape has no field or method Perimeter)
```
因为 s 的静态类型是 Shape，而 p 的静态类型是 Object，此问题可以使用`类型断言`

---

# 类型断言
类型断言可以用来获取接口的底层值，通常的语法：`i.(Type)`，其中 i 是接口，Type 是类型或接口。编译时会自动检测 i 的动态类型与 Type 是否一致。
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
    var s Shape = Circle{3}
    c := s.(Circle)
    var p Object = c
    fmt.Printf("%T\n",c)
    fmt.Printf("%v\n",c)
    fmt.Println("area: ", c.Area())
    fmt.Println("perimeter: ", c.Perimeter())
}
//output
main.Circle
{3}
area:  28.274334
perimeter:  18.849556
```
上面的代码，我们可以通过 c 访问接口 s 的底层值，也可以通过 c 分别调用方法 Area() 和 Perimeter()，这就解决了上面遇到的问题。
`在语法 i.(Type) 中，如果 Type 没有实现 i 所属的接口，编译的时候会报错；或者 i 的动态值不是 Type，则会报 panic 错误`。怎么解决呢？可以使用下面的语法:`value, ok := i.(Type)`

---

# 类型选择
```go
func switchType(i interface{}) {
     switch i.(type) {
     case string:
         fmt.Printf("string and value is %s\n", i.(string))
     case int:
         fmt.Printf("int and value is %d\n", i.(int))
     default:
         fmt.Printf("Unknown type\n")
     }
}
func main() {
    switchType("Seekload")
    switchType(27)
    switchType(true)
}
//output
string and value is Seekload
int and value is 27
Unknown type
```
`注意：只有接口类型才可以进行类型选择`。其他类型，例如 int、string等是不能

---

# 接口嵌套
Go 语言中，接口不能去实现别的接口也不能继承，但是可以通过嵌套接口创建新接口
```go
type Math interface {
	Shape
	Object
}
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
    var m Math = c
    fmt.Printf("%T\n", m )
    fmt.Println("area: ", m.Area())
    fmt.Println("perimeter: ", m.Perimeter())
}
//output
main.Circle
area:  28.274334
perimeter:  18.849556
```
上面的代码，通过嵌套接口 Shape 和 Object，创建了新的接口 Math。任何类型如果实现了接口 Shape 和 Object 定义的方法，则说类型也实现了接口 Math，例如我们创建的结构体 Circle。
主函数里面，定义了接口类型的变量 m，动态类型是结构体 Circle，注意下方法 Area 和  Perimeter 的调用方式，类似与访问嵌套结构体的成员。

---

# 使用指针接收者和值接收者实现接口
```go
type Shape interface {
	Area() float32
}
type Circle struct {
	radius float32
}
type Square struct {
	side float32
}
func (c Circle) Area() float32 {
	return math.Pi * (c.radius * c.radius)
}

func (s *Square) Area() float32 {
	return s.side*s.side
}
func main() {
    var s Shape
    c1 := Circle{3}
    s = c1
    fmt.Printf("%v\n",s.Area())

    c2 := Circle{4}
    s = &c2
    fmt.Printf("%v\n",s.Area())

    c3 := Square{3}
    //s = c3
    s = &c3
    fmt.Printf("%v\n",s.Area())
}
```
上面的代码，结构体 Circle 通过值接收者实现了接口 Shape。值接收者的方法可以使用值或者指针调用，所以上面的 c1 和 c2 的调用方式是合法的。

结构体 Square 通过指针接收者实现了接口 Shape。如果将上方注释部分打开的话，编译就会出错：
```go
cannot use c3 (type Square) as type Shape in assignment:
Square does not implement Shape (Area method has pointer receiver)
```
