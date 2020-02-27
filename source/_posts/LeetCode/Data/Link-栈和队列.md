---
title: 栈和队列
categories:
  - 后端
  - 数据结构
tags:
  - 栈和队列
comments: true
toc: true
abbrlink: 8d66b5f2
date: 2018-11-23 19:45:14
---
# 栈概念
　栈（英语：stack）又称为堆栈或堆叠，栈作为一种数据结构，是一种只能在一端进行插入和删除操作的特殊线性表。它按照先进后出的原则存储数据，先进入的数据被压入栈底，最后的数据在栈顶，需要读数据的时候从栈顶开始弹出数据（最后一个数据被第一个读出来）。栈具有记忆作用，对栈的插入与删除操作中，不需要改变栈底指针。

　栈是允许在同一端进行插入和删除操作的特殊线性表。允许进行插入和删除操作的一端称为栈顶(top)，另一端为栈底(bottom)；栈底固定，而栈顶浮动；栈中元素个数为零时称为空栈。插入一般称为进栈（PUSH），删除则称为退栈（POP）。

　由于堆叠数据结构只允许在一端进行操作，因而按照后进先出（LIFO, Last In First Out）的原理运作。栈也称为后进先出表。

　这里以羽毛球筒为例，羽毛球筒就是一个栈，刚开始羽毛球筒是空的，也就是空栈，然后我们一个一个放入羽毛球，也就是一个一个push进栈，当我们需要使用羽毛球的时候，从筒里面拿，也就是pop出栈，但是第一个拿到的羽毛球是我们最后放进去的。
# 操作流程示意图
![1120165-20171129201940386-674535319.png](http://ww1.sinaimg.cn/large/007lnJOlgy1g9epdmrj20j30b70bigll.jpg)
# 完整代码
```go
type Stack struct {
	Array []interface{} //栈切片存储
}

func (stack *Stack) Push(value ...interface{}) {
	stack.Array = append(stack.Array, value...)
}

//返回下一个元素
func (stack *Stack) Top() (value interface{}) {
	if stack.Size() > 0 {
		return stack.Array[stack.Size()-1]
	}
	return nil //read empty stack
}

//返回下一个元素,并从Stack移除元素
func (stack *Stack) Pop() interface{} {
	if stack.Size() > 0 {
		value := stack.Array[stack.Size()-1]
		stack.Array = stack.Array[:stack.Size()-1]
		return value
	}
	panic("Stack为空.") //read empty stack
}

//交换值
func (stack *Stack) Swap(other *Stack) {
	switch {
	case stack.Size() == 0 && other.Size() == 0:
		return
	case other.Size() == 0:
		other.Array = stack.Array[:stack.Size()]
		stack.Array = nil
	case stack.Size() == 0:
		stack.Array = other.Array
		other.Array = nil
	default:
		stack.Array, other.Array = other.Array, stack.Array
	}
	return
}

//返回指定索引的元素
func (stack *Stack) Get(idx int) (value interface{}) {
	if idx >= 0 && stack.Size() > 0 && stack.Size() > idx {
		return stack.Array[idx]
	}
	return nil
}

//Stack的size
func (stack *Stack) Size() int {
	return len(stack.Array)
}

```
# 栈-反转字符串
```go
str := "hello,word"
ss := &stack.Stack{}
for _, v := range str {
	ss.Push(string(v))
}
for ss.Size() > 0 {
	fmt.Print(ss.Pop())
}
```

# 共享栈
```
package stack

import "fmt"

//共享栈
const MaxDoubleSize = 20 //存储空间初始分配量
type DoubleStack struct {
	data [MaxDoubleSize]int //数组最大值
	top1 int                //栈1栈顶指针
	top2 int                //栈2栈顶指针
}

// 初始化一个空栈
func (d *DoubleStack) InitStack() {
	d.top1 = -1
	d.top2 = MaxDoubleSize
}

// 把d置为空栈
func (d *DoubleStack) ClearStack() {
	d.top1 = -1
	d.top2 = MaxDoubleSize
}

// 若栈l为空栈，则返回true 否则返回false
func (d *DoubleStack) IsEmpty() bool {
	if d.top1 == -1 && d.top2 == MaxDoubleSize {
		return true
	} else {
		return false
	}
}

// 返回s的元素个数，即栈的长度
func (d *DoubleStack) Length() int {
	return (d.top1 + 1) + (MaxDoubleSize - 1 - d.top2)
}

/**
value 插入元素e为新的栈顶元素
stackNum 选择插入的栈
*/
func (d *DoubleStack) Push(value int, stackNum int) error {
	if d.top1+1 == d.top2 {
		panic("stack is full")
	}

	// 栈1有元素进栈
	if stackNum == 1 {
		d.top1++
		d.data[d.top1] = value
	} else if stackNum == 2 { // 栈2有元素进栈
		d.top2--
		d.data[d.top2] = value
	}

	return nil
}

// 若栈不空，则删除d的栈顶元素  用e返回其值,否则返回error
func (d *DoubleStack) Pop(stackNum int) (value int) {
	if stackNum == 1 {
		if d.top1 == -1 {
			fmt.Errorf("stack is empty") //栈1为空，已溢出
		}
		value = d.data[d.top1]
		d.top1--
	} else if stackNum == 2 {
		if d.top2 == MaxDoubleSize {
			fmt.Errorf("stack is empty") //栈2为空，已溢出
		}
		value = d.data[d.top2]
		d.top2++
	}
	return value
}

//遍历栈
func (d *DoubleStack) Traverse() {
	for i := 0; i <= d.top1; i++ {
		fmt.Println(d.data[i])
	}
	for i := d.top2; i < MaxDoubleSize; i++ {
		fmt.Println(d.data[i])
	}
}

```

# 队列实现
队列其实和栈一样，只是队列是先进先出，那么只需要每次弹出第一个元素即可
```go
//返回下一个元素,并从Stack移除元素
func (stack *Stack) Pop() interface{} {
	if stack.Size() > 0 {
		value := stack.Array[0]
		stack.Array = stack.Array[1:]
		return value
	}
	panic("Stack为空.") //read empty stack
}
```

# 总结
1.	栈、队列（单向队列）、优先级队列通常是用来简化某些程序操作的数据结构，而不是主要作为存储数据的。
2.	在这些数据结构中，只有一个数据项可以被访问。
3.	栈允许在栈顶压入（插入）数据，在栈顶弹出（移除）数据，但是只能访问最后一个插入的数据项，也就是栈顶元素。
4.	队列（单向队列）只能在队尾插入数据，对头删除数据，并且只能访问对头的数据。而且队列还可以实现循环队列，它基于数组，数组下标可以从数组末端绕回到数组的开始位置。
5.	优先级队列是有序的插入数据，并且只能访问当前元素中优先级别最大（或最小）的元素。
6.	这些数据结构都能由数组实现，但是可以用别的机制（链表、堆等数据结构）实现。