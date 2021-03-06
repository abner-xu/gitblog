---
title: 双向链表
categories:
  - 后端
  - 数据结构
tags:
  - 链表
comments: true
toc: true
abbrlink: 37fd9ed5
date: 2018-11-21 17:45:14
---
# 示意图

- 双向链表：只有一个指针指向最开始的结点。
![1](http://ww2.sinaimg.cn/large/aaba1596gy1g963ldolkbj20rg05p74h.jpg)

- 双端(双向)链表：有两个指针分别指向两端的节点。
![1](http://ww2.sinaimg.cn/large/aaba1596gy1g963ldnn1kj20rg05pjro.jpg)

- 循环(双向)链表：指向形成一个闭环。：有两个指针分别指向两端的节点。
![1](http://ww2.sinaimg.cn/large/aaba1596gy1g963ldlx5cj20tg05pwer.jpg)

# 完整代码
```go
type DobuleNode struct {
	Prev *DobuleNode
	Data int
	Next *DobuleNode
}

type DoubleLinkList struct {
	first *DobuleNode
	last  *DobuleNode
}

func (this *DoubleLinkList) DoubleLinkList() {
	this.first = nil
	this.last = nil
}

func (this *DoubleLinkList) IsEmpty() bool {
	return this.first == nil
}

func (this *DoubleLinkList) GetHead() *DobuleNode {
	return this.first
}
func (this *DoubleLinkList) SetHead(head *DobuleNode) {
	this.first = head
}

/**
头部添加
*/
func (this *DoubleLinkList) AddHead(data int) {
	node := &DobuleNode{Data: data}
	if this.IsEmpty() {
		this.last = node
	} else {
		this.first.Prev = node
		node.Next = this.first
	}
	this.first = node
}

/**
头部删除
*/
func (this *DoubleLinkList) DelHead() *DobuleNode {
	if this.IsEmpty() {
		return nil
	}
	tmp := this.first
	if this.first.Next == nil {
		this.first.Next.Prev = nil
	}
	this.first = this.first.Next
	return tmp
}

/**
尾部添加
*/
func (this *DoubleLinkList) Append(data int) {
	node := &DobuleNode{Data: data}
	if this.IsEmpty() {
		this.first = node
	} else {
		this.last.Next = node
		node.Prev = this.last
	}
	this.last = node
}

/**
获取数据
*/
func (this *DoubleLinkList) Get(i int) int {
	currentNode := this.first //当前节点指向首节点
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

func (this *DoubleLinkList) Length() int {
	cur := this.first
	length := 0
	for cur != nil {
		length++
		cur = cur.Next
	}
	return length
}

func (this *DoubleLinkList) Insert(i int, data int) {
	node := &DobuleNode{Data: data}
	if i <= 0 {
		this.AddHead(data)
	} else if i > this.Length() {
		this.Append(data)
	} else {
		cur := this.first
		j := 0
		for j < i-1 {
			j++
			cur = cur.Next
		}
		next := cur.Next
		cur.Next = node
		node.Prev = cur
		node.Next = next
		next.Prev = node
	}
}

func (this *DoubleLinkList) Remove(data int) bool {
	if this.IsEmpty() {
		panic("链表数据为空")
		return false
	}
	cur := this.first
	for cur != nil {
		if cur.Data == data {
			pre := cur.Prev
			next := cur.Next
			pre.Next = next
			next.Prev = pre
			return true
		}
		cur = cur.Next
	}
	return false
}

/**
链表翻转
倒置链表的方法reversed()：把每个节点的左右节点交换，并且把链表的首尾节点也交换，就可以了。这里需要考虑的是循环的终止条件。
*/
func (this *DoubleLinkList) reverse() {
	head := this.first
	if head == nil {
		panic("链表数据为空")
	}

	for {
		//左右节点指针交互即可
		tmp := head.Prev
		head.Prev = head.Next
		head.Next = tmp
		if head.Prev == nil {
			break
		} else {
			head = head.Prev
		}

	}
	this.first = head
}

/**
打印数据
*/
func (this *DoubleLinkList) Display() {
	head := this.first
	sb := &strings.Builder{}
	sb.WriteString("[")
	for head != nil {
		sb.WriteString(strconv.Itoa(head.Data) + "->")
		head = head.Next
	}
	sb.WriteString("]")
	fmt.Println(sb.String())
}
```


# 遍历法-反转
倒置链表的方法reversed()：把每个节点的左右节点交换，并且把链表的首尾节点也交换，就可以了。这里需要考虑的是循环的终止条件。
```go
func (this *DoubleLinkList) reverse() {
	head := this.first
	if head == nil {
		panic("链表数据为空")
	}

	for {
		//左右节点指针交互即可
		tmp := head.Prev
		head.Prev = head.Next
		head.Next = tmp
		if head.Prev == nil {
			break
		} else {
			head = head.Prev
		}

	}
	this.first = head
}
```