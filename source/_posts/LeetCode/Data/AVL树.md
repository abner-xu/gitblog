---
title: AVL树
categories:
  - 后端
  - 数据结构
tags:
  - 树
comments: true
toc: true
abbrlink: 973716ad
date: 2020-01-06 13:51:24
---
# AVL树介绍
AVL树是高度平衡的而二叉树。它的特点是：AVL树中任何节点的两个子树的高度最大差别为1。 
![1.jpg](http://ww1.sinaimg.cn/large/007lnJOlgy1gamthpcg65j30y50aj0uz.jpg)
上面的两张图片，左边的是AVL树，它的任何节点的两个子树的高度差别都<=1；而右边的不是AVL树，因为7的两颗子树的高度相差为2(以2为根节点的树的高度是3，而以8为根节点的树的高度是1)。

关于高度，有的地方将"空二叉树的高度是-1"，而本文采用维基百科上的定义：树的高度为最大层次。即空的二叉树的高度是0，非空树的高度等于它的最大层次(根的层次为1，根的子节点为第2层，依次类推)。

# 旋转
如果在AVL树中进行插入或删除节点后，可能导致AVL树失去平衡。这种失去平衡的可以概括为4种姿态：LL(左左)，LR(左右)，RR(右右)和RL(右左)。下面给出它们的示意图：
![2.jpg](http://ww1.sinaimg.cn/large/007lnJOlgy1gamtpa42nbj31wt0b9n1v.jpg)
上图中的4棵树都是"失去平衡的AVL树"，从左往右的情况依次是：LL、LR、RL、RR。除了上面的情况之外，还有其它的失去平衡的AVL树，如下图：
![3.jpg](http://ww1.sinaimg.cn/large/007lnJOlgy1gamtpa4gi9j31wt0b9q7t.jpg)
上面的两张图都是为了便于理解，而列举的关于"失去平衡的AVL树"的例子。总的来说，AVL树失去平衡时的情况一定是LL、LR、RL、RR这4种之一，它们都由各自的定义：

- LL：LeftLeft，也称为"左左"。插入或删除一个节点后，根节点的左子树的左子树还有非空子节点，导致"根的左子树的高度"比"根的右子树的高度"大2，导致AVL树失去了平衡。
> 例如，在上面LL情况中，由于"根节点(8)的左子树(4)的左子树(2)还有非空子节点"，而"根节点(8)的右子树(12)没有子节点"；导致"根节点(8)的左子树(4)高度"比"根节点(8)的右子树(12)"高2。

- LR：LeftRight，也称为"左右"。插入或删除一个节点后，根节点的左子树的右子树还有非空子节点，导致"根的左子树的高度"比"根的右子树的高度"大2，导致AVL树失去了平衡。
> 例如，在上面LR情况中，由于"根节点(8)的左子树(4)的左子树(6)还有非空子节点"，而"根节点(8)的右子树(12)没有子节点"；导致"根节点(8)的左子树(4)高度"比"根节点(8)的右子树(12)"高2。

- RL：RightLeft，称为"右左"。插入或删除一个节点后，根节点的右子树的左子树还有非空子节点，导致"根的右子树的高度"比"根的左子树的高度"大2，导致AVL树失去了平衡。
> 例如，在上面RL情况中，由于"根节点(8)的右子树(12)的左子树(10)还有非空子节点"，而"根节点(8)的左子树(4)没有子节点"；导致"根节点(8)的右子树(12)高度"比"根节点(8)的左子树(4)"高2。

- RR：RightRight，称为"右右"。插入或删除一个节点后，根节点的右子树的右子树还有非空子节点，导致"根的右子树的高度"比"根的左子树的高度"大2，导致AVL树失去了平衡。
> 例如，在上面RR情况中，由于"根节点(8)的右子树(12)的右子树(14)还有非空子节点"，而"根节点(8)的左子树(4)没有子节点"；导致"根节点(8)的右子树(12)高度"比"根节点(8)的左子树(4)"高2。

## LL的旋转
LL失去平衡的情况，可以通过一次旋转让AVL树恢复平衡。如下图：
![4.jpg](http://ww1.sinaimg.cn/large/007lnJOlgy1gamuu1fn4xj30wl0aj0v2.jpg)
图中左边是旋转之前的树，右边是旋转之后的树。从中可以发现，旋转之后的树又变成了AVL树，而且该旋转只需要一次即可完成。
对于LL旋转，你可以这样理解为：LL旋转是围绕"失去平衡的AVL根节点"进行的，也就是节点k2；而且由于是LL情况，即左左情况，就用手抓着"左孩子，即k1"使劲摇。将k1变成根节点，k2变成k1的右子树，"k1的右子树"变成"k2的左子树"。

## RR的旋转
理解了LL之后，RR就相当容易理解了。RR是与LL对称的情况！RR恢复平衡的旋转方法如下：
![5.jpg](http://ww1.sinaimg.cn/large/007lnJOlgy1gamuwqz4qbj30wl0ajdi7.jpg)
图中左边是旋转之前的树，右边是旋转之后的树。RR旋转也只需要一次即可完成。

##  LR的旋转
LR失去平衡的情况，需要经过两次旋转才能让AVL树恢复平衡。如下图：
![6.jpg](http://ww1.sinaimg.cn/large/007lnJOlgy1gamvfijojfj31im0ajaei.jpg)
第一次旋转是围绕"k1"进行的"RR旋转"，第二次是围绕"k3"进行的"LL旋转"。

## RL的旋转
RL是与LR的对称情况！RL恢复平衡的旋转方法如下：
![7.jpg](http://ww1.sinaimg.cn/large/007lnJOlgy1gamviaka3mj31im0ajgq0.jpg)
第一次旋转是围绕"k3"进行的"LL旋转"，第二次是围绕"k1"进行的"RR旋转"。

# 完整代码
```go
package tree

import (
	"fmt"
)

type AVLTreeNode struct {
	Value       int
	Height      int
	Left, Right *AVLTreeNode
}

type AVLTree struct {
	Root *AVLTreeNode
}

/**
数据大小比较工具
*/
func (this *AVLTree) max(x, y int) int {
	if x > y {
		return x
	} else {
		return y
	}
}

/**
数据大小比较工具
*/
func (this *AVLTree) min(x, y int) int {
	if x > y {
		return y
	} else {
		return x
	}
}

/**
数据大小比较工具
*/
func (this *AVLTree) height(tree *AVLTreeNode) int {
	if tree != nil {
		return tree.Height
	}
	return 0
}

/**
中序遍历
*/
func (this *AVLTree) InOrder(current *AVLTreeNode) {
	if current != nil {
		this.InOrder(current.Left)
		fmt.Printf("%d,", current.Value)
		this.InOrder(current.Right)
	}
}

/**
前序遍历
*/
func (this *AVLTree) PreOrder(current *AVLTreeNode) {
	if current != nil {
		fmt.Printf("%d,", current.Value)
		this.PreOrder(current.Left)
		this.PreOrder(current.Right)
	}
}

/**
后序遍历
*/
func (this *AVLTree) PostOrder(current *AVLTreeNode) {
	if current != nil {
		this.PostOrder(current.Left)
		this.PostOrder(current.Right)
		fmt.Printf("%d,", current.Value)
	}
}

/**
递归搜索
*/
func (this *AVLTree) Search(current *AVLTreeNode, Value int) *AVLTreeNode {
	if current == nil {
		return current
	}
	if Value < current.Value {
		return this.Search(current.Left, Value)
	} else if Value > current.Value {
		return this.Search(current.Right, Value)
	} else {
		return current
	}
}

/**
非递归查找
*/
func (this *AVLTree) Find(data int) *AVLTreeNode {
	if this.Root == nil {
		return nil
	}
	current := this.Root
	for current != nil {
		if data > current.Value {
			current = current.Right
		} else if data < current.Value {
			current = current.Left
		} else {
			return current
		}
	}
	return current
}

/**
查找最小节点
*/
func (this *AVLTree) FindMin(current *AVLTreeNode) *AVLTreeNode {
	if current == nil {
		return nil
	}
	for current.Left != nil {
		current = current.Left
	}
	return current
}

/**
查找最小节点
*/
func (this *AVLTree) FindMax(current *AVLTreeNode) *AVLTreeNode {
	if current == nil {
		return nil
	}
	for current.Right != nil {
		current = current.Right
	}
	return current
}

/**
LL：左左对应的情况(左单旋转)。
返回值：旋转后的根节点
*/
func (this *AVLTree) LeftLeftRotation(k2 *AVLTreeNode) *AVLTreeNode {
	k1 := k2.Left
	k2.Left = k1.Right
	k1.Right = k2
	k2.Height = this.max(this.height(k2.Left), this.height(k2.Right)) + 1
	k1.Height = this.max(this.height(k1.Left), k2.Height) + 1
	return k1
}

/**
LL：左左对应的情况(右单旋转)。
返回值：旋转后的根节点
*/
func (this *AVLTree) RightRightRotation(k1 *AVLTreeNode) *AVLTreeNode {
	k2 := k1.Right
	k1.Right = k2.Left
	k2.Left = k1
	k1.Height = this.max(this.height(k1.Left), this.height(k1.Right)) + 1
	k2.Height = this.max(this.height(k2.Right), k1.Height) + 1
	return k2
}

/**
LR的旋转
第一次旋转是围绕"k1"进行的"RR旋转"，第二次是围绕"k3"进行的"LL旋转"。
*/
func (this *AVLTree) LeftRightRotation(k3 *AVLTreeNode) *AVLTreeNode {
	k3.Left = this.RightRightRotation(k3.Left)
	return this.LeftLeftRotation(k3)
}

/**
RF的旋转
第一次旋转是围绕"k3"进行的"LL旋转"，第二次是围绕"k1"进行的"RR旋转"。
*/
func (this *AVLTree) RightLeftRotation(k1 *AVLTreeNode) *AVLTreeNode {
	k1.Right = this.LeftLeftRotation(k1.Right)
	return this.RightRightRotation(k1)
}

/**
插入数据
*/
func (this *AVLTree) insert(tree *AVLTreeNode, data int) *AVLTreeNode {

	if tree == nil {
		tree = &AVLTreeNode{Value: data}
		if tree == nil {
			fmt.Errorf("ERROR: create avltree node failed!\n")
			return nil
		}
	} else if data < tree.Value { // 应该将key插入到"tree的左子树"的情况
		tree.Left = this.insert(tree.Left, data)
		// 插入节点后，若AVL树失去平衡，则进行相应的调节。
		if this.height(tree.Left)-this.height(tree.Right) == 2 {
			if data < tree.Left.Value {
				tree = this.LeftLeftRotation(tree)
			} else {
				tree = this.LeftRightRotation(tree)
			}
		}
	} else if data > tree.Value { // 应该将key插入到"tree的右子树"的情况
		tree.Right = this.insert(tree.Right, data)
		if this.height(tree.Right)-this.height(tree.Left) == 2 {
			if data > tree.Right.Value {
				tree = this.RightRightRotation(tree)
			} else {
				tree = this.RightLeftRotation(tree)
			}
		}
	} else {
		fmt.Errorf("添加失败：不允许添加相同的节点！\n")
	}

	tree.Height = this.max(this.height(tree.Left), this.height(tree.Right)) + 1
	return tree
}

func (this *AVLTree) Add(data int) {
	this.Root = this.insert(this.Root, data)
}

func (this *AVLTree) Del(data int) bool {
	if z := this.Search(this.Root, data); z == nil {
		return false
	} else {
		this.remove(this.Root, z)
		return true
	}

}

/**
删除树
*/
func (this *AVLTree) remove(tree *AVLTreeNode, delNode *AVLTreeNode) *AVLTreeNode {

	if tree == nil || delNode == nil {
		return nil
	}
	if delNode.Value < tree.Value { // 待删除的节点在"tree的左子树"中
		tree.Left = this.remove(tree.Left, delNode)
		// 删除节点后，若AVL树失去平衡，则进行相应的调节。
		if this.height(tree.Right)-this.height(tree.Left) == 2 {
			rTree := tree.Right
			if this.height(rTree.Left) > this.height(rTree.Right) {
				tree = this.RightLeftRotation(tree)
			} else {
				tree = this.RightRightRotation(tree)
			}
		}
	} else if delNode.Value > tree.Value { // 待删除的节点在"tree的右子树"中
		tree.Right = this.remove(tree.Right, delNode)
		// 删除节点后，若AVL树失去平衡，则进行相应的调节。
		if this.height(tree.Left)-this.height(tree.Right) == 2 {
			lTree := tree.Right
			if this.height(lTree.Right) > this.height(lTree.Left) {
				tree = this.LeftRightRotation(tree)
			} else {
				tree = this.LeftLeftRotation(tree)
			}
		}
	} else { //相等的节点
		if tree.Left != nil && tree.Right != nil {
			if this.height(tree.Left) > this.height(tree.Right) {
				// 如果tree的左子树比右子树高；
				// 则(01)找出tree的左子树中的最大节点
				//   (02)将该最大节点的值赋值给tree。
				//   (03)删除该最大节点。
				// 这类似于用"tree的左子树中最大节点"做"tree"的替身；
				// 采用这种方式的好处是：删除"tree的左子树中最大节点"之后，AVL树仍然是平衡的。
				maxNode := this.FindMax(tree.Left)
				tree.Value = maxNode.Value
				tree.Left = this.remove(tree.Left, maxNode)
			} else {
				// 如果tree的左子树不比右子树高(即它们相等，或右子树比左子树高1)
				// 则(01)找出tree的右子树中的最小节点
				//   (02)将该最小节点的值赋值给tree。
				//   (03)删除该最小节点。
				// 这类似于用"tree的右子树中最小节点"做"tree"的替身；
				// 采用这种方式的好处是：删除"tree的右子树中最小节点"之后，AVL树仍然是平衡的。
				minNode := this.FindMin(tree.Right)
				tree.Value = minNode.Value
				tree.Right = this.remove(tree.Right, minNode)
			}
		} else {
			if tree.Left != nil {
				tree = tree.Left
			} else {
				tree = tree.Right
			}
		}
	}
	return tree
}

func (this *AVLTree) Display() {
	if this.Root != nil {
		this.print(this.Root, this.Root.Value, 0)
	}
}

/**
递归打印
key -- 节点的值
direction -- 0,根节点
			-1,父节点的坐孩子
			1,父节点的右孩子
*/
func (this *AVLTree) print(tree *AVLTreeNode, key int, direction int) {
	if tree != nil {
		if direction == 0 {
			fmt.Printf("%2d is root\n", tree.Value)
		} else {
			var post string
			if direction == 1 {
				post = "right"
			} else {
				post = "left"
			}
			fmt.Printf("%2d is %2d's %6s child\n", tree.Value, key, post)
		}
		this.print(tree.Left, tree.Value, -1)
		this.print(tree.Right, tree.Value, 1)
	}
}


```