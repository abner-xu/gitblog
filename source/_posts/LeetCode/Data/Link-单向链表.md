---
title: 单向链表
categories:
  - 后端
  - 数据结构
tags:
  - 链表
comments: true
toc: true
abbrlink: b42a8d36
date: 2018-11-21 17:45:14
---
# 操作流程示意图
![1183379-529d87f81914f457.jpg](http://ww2.sinaimg.cn/large/aaba1596gy1g95t1z9d7yj20se0jm0tv.jpg)
# 完整代码
```go

type Node struct {
	Data int
	Next *Node
}

type SingleLinkedList struct {
	head *Node
}

func (this *SingleLinkedList) SingleLinkedList() {
	this.head = nil
}

func (this *SingleLinkedList) SetHead(head *Node) {
	this.head = head
}
func (this *SingleLinkedList) GetHead() *Node {
	return this.head
}

func (this *SingleLinkedList) IsEmpty() bool {
	return this.head == nil
}

/**
获取链表长度
*/
func (this *SingleLinkedList) Length() int {
	currentNode := this.head
	length := 0
	for currentNode != nil {
		length++
		currentNode = currentNode.Next

	}
	return length
}

/**
清空链表
*/
func (this *SingleLinkedList) Clean() {
	this.head = nil
}

/**
获取数据
*/
func (this *SingleLinkedList) Get(i int) int {
	currentNode := this.head //当前节点指向首节点
	j := 0
	for currentNode != nil && j < i {
		j++
		currentNode = currentNode.Next

	}
	if i < 0 || currentNode == nil {
		panic(fmt.Sprintf("第%d个元素不存在", i))
	}
	return currentNode.Data
}

/**
头部插入
*/
func (this *SingleLinkedList) AddHead(data int) {
	node := &Node{Data: data, Next: nil}
	node.Next = this.head
	this.head = node
}

/**
头部删除
*/
func (this *SingleLinkedList) DelHead() {
	this.head = this.head.Next
}

/**
从尾部追加
*/
func (this *SingleLinkedList) Append(data int) {
	node := &Node{Data: data, Next: nil}
	currentNode := this.head //当前节点指向首节点
	for currentNode.Next != nil {
		currentNode = currentNode.Next
	}
	currentNode.Next = node
}

/**
打印数据
*/
func (this *SingleLinkedList) Display() {
	head := this.head
	sb := &strings.Builder{}
	sb.WriteString("[")
	for head != nil {
		sb.WriteString(strconv.Itoa(head.Data) + "->")
		head = head.Next
	}
	sb.WriteString("]")
	fmt.Println(sb.String())
}

func (this *SingleLinkedList) insert(i int, data int) {
	if i < 0 {
		this.AddHead(data)
	} else if i > this.Length() {
		this.Append(data)
	} else {
		pre := this.head
		count := 0
		for count < i {
			pre = pre.Next
			count++
		}
		node := &Node{Data: data}
		node.Next = pre.Next
		pre.Next = node

	}
}

/**
移除数据
*/
func (this *SingleLinkedList) remove(data int) {
	curr := this.head
	if curr.Data == data {
		this.head = curr.Next
	} else {
		for curr.Next != nil {
			if curr.Next.Data == data {
				curr.Next = curr.Next.Next
			} else {
				curr = curr.Next
			}
		}
	}
```
# 递归法-反转
递归反转法：在反转当前节点之前先反转后续节点。这样从头结点开始，层层深入直到尾结点才开始反转指针域的指向。简单的说就是从尾结点开始，逆向反转各个结点的指针域指向，其过程图如下所示：
- head：是前一结点的指针域（PS：前一结点的指针域指向当前结点）
- head.getNext()：是当前结点的指针域（PS：当前结点的指针域指向下一结点）
- reHead：是反转后新链表的头结点（即原来单链表的尾结点）

![2.jpg](http://ww2.sinaimg.cn/large/aaba1596gy1g95t43dr22j20b50byjrp.jpg)

```go
func (this *SingleLinkedList) reverse(head *Node) *Node {
	if head == nil || head.Next == nil {
		return head
	}
	next := head.Next
	new_head := this.reverse(next)
	next.Next = head
	head.Next = nil
	return new_head
}
```
结果
```go
newHead := l.reverse(l.GetHead())
l.SetHead(newHead)
l.Display()
//output
[69->3->97->171->118->122->]
[122->118->171->97->3->69->]
```





# 遍历法-反转
```go
func (this *SingleLinkedList) reverse2(head *Node) *Node {
	if head == nil || head.Next == nil {
		return head
	}
	var pre *Node  //前一节点
	cur := head    //当前节点
	var next *Node // 下一结点

	for cur != nil { // 当前结点为null，说明位于尾结点
		next = cur.Next //nextNode 指向下一个节点
		cur.Next = pre  //将当前节点next域指向前一个节点
		pre = cur       //preNode 指针向后移动
		cur = next      //curNode指针向后移动

	}
	return pre
}
```