---
title: go语言圣经读书笔记
categories:
  - 后端
  - Golang
tags:
  - book
comments: true
toc: true
date: 2019-04-12 13:18:41
---

# 1 基本数据类型

## 1.1 整型
1.  int8、int16、inte32、int64,分别对应了8,16,32,64bit大小的有符号整型，无符号unit即可
2.  unicode字符`rune`类型等价于int32,通常用于表示一个Unicode码点，这2个名称可以互换使用。  
3.  **rune特别的用法**
```go
func main() {
    var str = "hello 你好"
    //golang中string底层是通过byte数组实现的，所以直接求len 实际是在按字节长度计算  所以一个汉字占3个字节算了3个长度
    fmt.Println("len(str):", len(str))
    //以下两种都可以得到str的字符串长度
    //golang中的unicode/utf8包提供了用utf-8获取长度的方法
    fmt.Println("RuneCountInString:", utf8.RuneCountInString(str))
    //通过rune类型处理unicode字符
    fmt.Println("rune:", len([]rune(str)))
}
len(str):12
RuneCountInString:8
rune:8
```
- byte 等同于int8，常用来处理ascii字符
- rune 等同于int32,常用来处理unicode或utf-8字符

4. 无符号uintptr类型，一般用于底层和C语言函数交互，unsafe包相关
5. int,uint,uintprt是不同的兄弟类型，**int和int32是不同的类型，即使int也是32bit**

6. 整型之间相互转换-> T(x)

---

## 1.2 浮点数
float32，float64
### 1.2.1 浮点数的一些坑

1.  相减
```
x := 74.96
y := 20.48
b := x - y
fmt.Println(b) //output: 54.47999999999999
```
2.  相加
```
var a = 0.6
fmt.Println(a + 0.7) //output: 1.2999999999999998
```
3. 浮点数互转精度丢失，四舍五入错误
```
var a float32=80.45
var b float64
b=float64(a)
fmt.Println(a) //output: 80.45
fmt.Println(b) //output:80.44999694824219
```
4. int64转float64在数值很大的时候出现偏差
```
var c int64 = 987654321098765432
fmt.Printf("%.f\n", float64(c)) //output:987654321098765440
```
5. 两位小数乘100强转int, 比期望值少了1
```
var d float64 = 1129.6
var e int64 = int64(d * 100)
fmt.Println(e) //output:112959
```
### 1.2.3 浮点数坑的解决办法
- 利用fmt.Sprintf() 转字符串解决
- math数据函数解决

## 1.3 复数
- complex64 => float32  对应关系
- complex128 => float64 对应关系

---

## 1.4 字符串
字符串底层是用的字节数组存储，且字符串是不可以修改，所以相同的2个字符串拥有相同的内存地址存储和地址
```
s := "hello,	world"
fmt.Println(len(s))     //	"12"
fmt.Println(s[0], s[7]) //	"104	119"	('h'	and	'w')
```
### 1.4.1 字符串和Byte切片
主要使用的一些字符串处理包：bytes、strings、strconv和unicode包
- bytes：
- strings：字符串的查询、替换、比较、截断、拆分和合并，大小写转换等功能。
- strconv：包提供了布尔型、整型数、浮点数和对应字符串的相互转换，还提供了双引号转义相 关的转换。
- unicode：IsDigit、IsLetter、IsUpper和IsLower等类似功能，它们用于给字符分类

### 1.4.2 字符串和类型转换
- 转byte：[]byte("hello word")
- 转int：strconv.Atoi("123"),ParseInt

---
## 1.5 常量

### 1.5.1 iota常量生成器
```go
type	Weekday	int
const	(				
    Sunday	Weekday	=	iota				
    Monday				
    Tuesday				
    Wednesday				
    Thursday				
    Friday				
    Saturday 
)
```
周日=0，周一=1，以此类推

---

# 2 复合数据类型
## 2.1 数组
- 数组初始化
```
var q[3]int=[3]int{1,2,3}
var r[3]int=[3]int{1,2}// 默认最后一个为0
q := [...]int{1,	2,	3}  //这种默认根据数据初始化长度计算
r := [...]int{99:	-1} //定义100各元素，99元素为-1
```
- 数组比较   
**只有当2个数组的所有元素相等的时候数组才相等**
```
a := [2]int{1,	2} 
b := [...]int{1,	2}
c := [2]int{1,	3}
fmt.Println(a==b,a==c,b==c)	//	"true	false	false"
```
- 数组作为参数
传递数组参数时候会复制数组，所以为了效率提升，必要时可以传递数组指针

## 2.2 slice
Slice(切片)代表了变长的序列，序列中每个元素都有相同的类型。  

Slice底层存储使用的是数组。一个slice由3部分组成：指针、长度和容量
- 指针：指针指向第一个slice元素对应的底层数组元素地址，**注意，slice的第一个元素并不一定就是数组的第一个元素**
- 长度：slice中元素的数据，**长度不能超过容量**
- 容量：一般是从slice的开始位置到底层数据的结尾位置
- **注意，底层数组是可以被多个 slice 同时指向的，因此对一个 slice 的元素进行操作是有可能影响到其他 slice 的。**

<div align="center">
    <img src="http://ww1.sinaimg.cn/thumbnail/007lnJOlgy1g1yp6exn31j30hk0dqmxc.jpg"> 
</div> 


Slice创建
```
1	直接声明	var slice []int
2	new	slice := *new([]int)
3	字面量	slice := []int{1,2,3,4,5}
4	make	slice := make([]int, 5, 10)
5	从切片或数组“截取”	slice := array[1:5] 或 slice := sourceSlice[1:5]
```

Slice读取
```
s[i:j]  ,其中0 ≤ i ≤ j ≤ cap(s)
s[:j]   ,如果i位省略则使用0
s[i:]   ,如果j位省略则使用len(s)长度
```

### 2.2.1 append追加元素到Slice   
`runner=append(runner,'hello')`   
append底层追加数据的理解，模拟系统append函数原理
```
func appendInt(x []int,y int) []int {
	var z []int
	zlen:=len(x)+1
	if zlen<=cap(x){ //容量空间还够
		z=x[:zlen]
	}else{ //容量空间不够了
		zcap:=zlen
		if zcap<2*len(x){
			zcap=2*len(x)
		}
		z=make([]int,zlen,zcap)
		copy(z,x)

	}
	z[len(x)]=y
	return z
}
```
- 如果空间足够：直接在后面追加
- 如果空间不足够：先判断容量是否小于2倍的数据长度，如果小于则空间扩大2倍数据长度，然后进行数据拷贝，**简单说:长度超过容器，就进行2倍容器扩容**

### 2.2.2 为什么 nil slice 可以直接 append

其实 `nil slice` 或者 `empty slice` 都是可以通过调用 append 函数来获得底层数组的扩容。最终都是调用 `mallocgc` 来向 Go 的内存管理器申请到一块内存，然后再赋给原来的`nil slice` 或 `empty slice`，然后摇身一变，成为“真正”的 slice 了。

### 2.2.3 传 slice 和 slice 指针有什么区别

---

## 2.3 Map
map初始化
```
ages:=make(map[K]V)   或者  map[string]int{}
如下
ages:=map[string]int{
    "zzz":11
    "xxx":22
}
```
 map不能对元素取地址操作：因为map可能随着数据的元素增长重新分配内存
 
 map遍历的顺序不固定
 
 Map实现Set `map[string]bool`


## 2.4 Struct结构体
结构体的定义
```
type Employee struct	{				
ID	int				
Name,	Address	string				
DoB	time.Time				
Position string			
Salary int			
ManagerID int 
Boss *Employee
}
```

结构体的初始化

- 方法一：` ep:=&Employee{1,"张三","2012","devp",....}`不能省略，通常用于较小的结构体
- 方法二：` ep:=&Employee{Id:1,Name:"张三",....}`可以包含全部或者部分，未填写部分默认值为nil

 结构体比较：结构体的成员可以进行比较，结构体也可以直接进行比较。**==符号将比较结构体的每个成员**，因此下面的表达式是等效的
```
type Point struct{X,Y int}
p := Point{1,2} 
q := Point{2,1} 
fmt.Println(p.X	== q.X && p.Y == q.Y)	//	"false" 
fmt.Println(p == q)	//	"false"
```

 **结构体可用作map的key**

结构体嵌套和匿名结构体
```
type Circle struct{
    Point
    Redius int
}
type Wheel struct{
    Circle
    Spokes int
}
```
Point和Circle 都是属于匿名结构体

---

# 3 函数部分
## 3.1 函数
函数声明

```
func hybody(x,y float64) float64{
    return math.Sqrt(x*x+y*y)
}
```

函数递归

多返回值
```
func hybody(x,y float64) (float64,error){
    return math.Sqrt(x*x+y*y),err
}
```

匿名函数
```
f := fun(x)int{
    return x+1
}
```

可变参数
```
func hybody(vals ...int) int{
   total:=0
   for _,val=range vals{
       total+=val
   }
   return total
}
```

## 3.2 Defer延迟

defer dofun() 加上关键字以后就是，defer语句会一直等到函数执行完成以后才执行。无论包含defer的函数是否return、pannic都会被执行。**defer语句通常被用于资源释放**

- 规则一：当defer被申明时，其参数会被实时解析
```
func a() {
	i := 0
	defer fmt.Println(i)
	i++
	return
}
//out： 0 
```
- 规则二：defer执行顺序为先进后出
```
func b() {
	for i := 0; i < 4; i++ {
		defer fmt.Println(i)
	}
}
//out: 3 2 1 0 
```
- 规则三：defer可以读取有名返回值
```
func c() (i int) {
	defer func() { i++ }()
	return 1
}
//out:2
```
defer是在return调用之后才执行的。 这里需要明确的是defer代码块的作用域仍然在函数之内，结合上面的函数也就是说，defer的作用域仍然在c函数之内。因此defer仍然可以读取c函数内的变量(如果无法读取函数内变量，那又如何进行变量清除呢....)。

当执行return 1 之后，i的值就是1. 此时此刻，defer代码块开始执行，对i进行自增操作。 因此输出2.

## 3.3 Panic异常
Golang里比较常见的错误处理方法是返回error给调用者，但如果是无法恢复的错误，返回error也没有意义，此时可以选择go die：主动触发panic。

panic会停掉当前正在执行的程序（注意，不只是协程），但是与`os.Exit(-1)`这种直愣愣的退出不同，panic的撤退比较有秩序，他会先处理完当前goroutine已经defer挂上去的任务，执行完毕后再退出整个程序。

而defer的存在，让我们有更多的选择，比如在defer中通过recover截取panic，从而达到try..catch的效果。
例子：
```
package main

import (
	"os"
	"fmt"
	"time"
)

func main() {
	var user = os.Getenv("USER_")
	go func() {
		defer func() {
			fmt.Println("defer here")
		}()
		if user == "" {
			panic("should set user env.")
		}
	}()
	time.Sleep(1 * time.Second)
	fmt.Printf("get result %d\r\n", result)
}
```
如上例，go run这段代码，会发现defer中的字符串”defer here”打印出来了，而main流程中的”ger result”没有打印，说明panic坚守了自己的原则：

**执行，且只执行，当前goroutine的defer。**

如果当前函数中有多个defer呢？

panic仅保证当前goroutine下的defer都会被调到，但不保证其他协程的defer也会调到。如果是在同一goroutine下的调用者的defer，那么可以一路回溯回去执行；但如果是不同goroutine，那就不做保证了。

总结：
- 遇到处理不了的错误，找panic
- panic有操守，退出前会执行本goroutine的defer，方式是原路返回(reverse order)
- panic不多管，不是本goroutine的defer，不执行

## 3.4 Recover异常捕获
golang在这种情况下可以在panic的当前goroutine的defer中使用recover来捕捉panic。
注意recover只在defer的函数中有效，如果不是在defer上下文中调用，recover会直接返回nil。
```
func main() {
	defer fmt.Println("defer main") // will this be called when panic?
	var user = os.Getenv("USER_")
	go func() {
        defer func() {
            fmt.Println("defer caller")
            if err := recover(); err != nil {
                fmt.Println("recover success.")
            }
        }()
        func() {
            defer func() {
                fmt.Println("defer here")
            }()

            if user == "" {
                panic("should set user env.")
            }
            fmt.Println("after panic")
        }()
	}()

	time.Sleep(1 * time.Second)
	fmt.Printf("get result %d\r\n", result)
}
//out:
defer here
defer caller
recover success.
get result 1
defer main
```

---
# 4 方法
在函数声明时，在其名字之前放上一个变量，即是一个方法。这个附加的参数会将该函数附 加到这种类型上，即相当于为这种类型定义了一个独占的方法。

## 4.1 方法声明
```
type Employee struct{
    Id int
}

func (e Employee) doSome(){
    
}
```
上述的代码中 doSome附加的参数e,叫做方法的接收器。在go语言中没有this,self这种关键字作为接收器，所以建议使用类型的第一个字母作为接收器名称
## 4.2 基于指针方法
`func (e *Employee) doSome(){}` 当调用一个函数时，会对其每一个参数值进行拷贝，如果一个函数需要更新一个变量，或者 函数的其中一个参数实在太大我们希望能够避免进行这种默认的拷贝，这种情况下我们就需 要用到指针了。**对应到我们这里用来更新接收器的对象的方法，当这个接受者变量本身比较 大时，我们就可以用其指针而不是对象来声明方法**，一般情况下都使用指针即可

例子一：
```go
func main() {
	p:=person{name:"张三"}
	p.modify() //值接收者，修改无效
	fmt.Println(p.String())
}

type person struct {
	name string
}
func (p person) String() string{
	return "the person name is "+p.name
}
func (p person) modify(){
	p.name = "李四"
}
```
使用值类型接收者定义的方法，在调用的时候，使用的其实是值接收者的一个副本，所以对该值的任何操作，不会影响原来的类型变量。

例子二：
```go
func main() {
	p:=person{name:"张三"}
	p.modify() //值接收者，修改无效
	fmt.Println(p.String())
}

type person struct {
	name string
}
func (p *person) String() string{
	return "the person name is "+p.name
}
func (p *person) modify(){
	p.name = "李四"
}
```
使用一个指针作为接收者，那么就会其作用了，因为指针接收者传递的是一个指向原值指针的副本，指针的副本，指向的还是原来类型的值，所以修改时，同时也会影响原来类型变量的值。


## 4.3 方法值和方法表达式
```
p.funName => 方法值
p.funName() => 方法表达式
```

---
# 5 接口
## 5.1 接口方法集
```go
type ReadWriter interface{
    Read(p	[]byte)	(n	int,	err	error) 
    Writer(p	[]byte)	(n	int,	err	error) 
}
```
## 5.2 多态的实现
```go
func main() {
	var a animal
	var c cat
	a=c
	a.printInfo() //使用另外一个类型赋值
	var d dog
	a=d
	a.printInfo()
}

type animal interface {
	printInfo()
}

type cat int
type dog int

func (c cat) printInfo(){
	fmt.Println("a cat")
}

func (d dog) printInfo(){
	fmt.Println("a dog")
}
//out
a cat
a dog
```
以上例子演示了一个多态。我们定义了一个接口animal,然后定义了两种类型cat和dog实现了接口animal。在使用的时候，分别把类型cat的值c、类型dog的值d赋值给接口animal的值a,然后分别执行a的printInfo方法，可以看到不同的输出。

## 5.3 接口做为参数值，可以表示泛型

---
# 6 Goroutines和Channels

---
# 7 包和工具
## 包初始化顺序
![包加载顺序](http://ww1.sinaimg.cn/large/007lnJOlgy1g27rnzthjhj31ma0pc4jp.jpg)
---
# 8 测试


---
# 9 反射

---
# 10 底层