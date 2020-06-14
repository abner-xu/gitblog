---
title: Go 中 defer 与 return 之间的迷之执行顺序
categories:
  - 后端
  - Golang
comments: true
toc: true
abbrlink: 8ec4b9d8
date: 2019-08-28 17:02:04
---

# 执行顺序 

偶然间发现了一个有意思的地方：在使用`defer`时，匿名返回值的函数和命名返回值的函数的返回结果是不一样的。具体见如下代码:
```go
func f1() (r int) {
	defer func() {
		r++
	}()
	return r
}

func f2() (r int) {
	t := 5
	defer func() {
		t = t + 5
	}()
	return t
}

func f3() (r int) {
	defer func(r int) {
		r = r + 5
	}(r)
	return r
}

func f4(a int) int {
	defer func(r int) {
		a = a + 5
	}(a)
	return a
}
func main() {
 	fmt.Println(f1())
 	fmt.Println(f2())
 	fmt.Println(f3())
 	fmt.Println(f4(1))
}
//output 
1
5
0
1
```
- f1()拆解
```go
func f1() (r int) {

    // 1.赋值
    r = 0

    // 2.闭包引用，返回值被修改
    defer func() {
        r++
    }()

    // 3.空的 return
    return
}
```
defer 是闭包引用，返回值被修改，所以 f() 返回 1。

- f2()拆解
```go
func f2() (r int) {
    t := 5
    // 1.赋值
    r = t

    // 2.闭包引用，但是没有修改返回值 r
    defer func() {
        t = t + 5
    }()

    // 3.空的 return
    return
}
```
第二步没涉及返回值 r 的操作，所以返回 5。

- f3()拆解（f4同理）
```go
func f3() (r int) {

    // 1.赋值
    r = 1

    // 2.r 作为函数参数，不会修改要返回的那个 r 值
    defer func(r int) {
        r = r + 5
    }(r)

    // 3.空的 return
    return
}
```
第二步，r 是作为函数参数使用，是一份复制，defer 语句里面的 r 和 外面的 r 其实是两个变量，里面变量的改变不会影响外层变量 r，所以不是返回 6 ，而是返回 1。


总结一下就是，函数的整个返回过程应该是：
- return对返回变量赋值，如果是匿名返回值就先声明再赋值；
- 执行defer函数；
- return携带返回值返回。

# return 之后的 defer
```go
var a bool = true
func main() {
    defer func(){
        fmt.Println("1")
    }()
    if a == true {
        fmt.Println("2")
        return
    }
    defer func(){
        fmt.Println("3")
    }()
}
```
*defer 关键字后面的函数或者方法想要执行必须先注册，return 之后的 defer 是不能注册的， 也就不能执行后面的函数或方法。*
