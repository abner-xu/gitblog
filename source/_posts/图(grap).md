---
title: 图(grap)
comments: true
toc: true
categories:
  - 后端
  - 数据结构
tags:
  - 数据结构算法
abbrlink: b14b48cc
date: 2019-02-20 20:51:25
---
# 图结构
图(Graph)结构也是一种非线性数据结构，并且每个数据元素之间可以任意关联
## 图包含两个部分
1.	顶点（Vertex）:图中的数据元素
2.	边（Edge）:图中连接这些顶点的线
## 无向图
如果一个图结构中所有的边都没有方向性，这称为无向图。
![image](http://ws4.sinaimg.cn/large/0078bOVFgy1g09pwiwsnsj30aj059gls.jpg)
## 有向图
如果一个图结构，边是有方向性的，这称为有向图
![image](http://ws1.sinaimg.cn/large/0078bOVFgy1g09px7nkq0j30aj05hglt.jpg)
## 权
在实际应用中图的边往往需要表示成为某种数值，这个数值便是该边的权。无向图中加权值，则称为无向带权图。有向图中加权值，则称为有向带权图。 

![image](http://ws1.sinaimg.cn/large/0078bOVFgy1g09qdd0weej308106s757.jpg)
![image](http://ws4.sinaimg.cn/large/0078bOVFgy1g09qdur88pj308k06oab2.jpg)
## 邻接矩阵表示
![image](http://ws3.sinaimg.cn/large/0078bOVFgy1g09qevjil0j308105rt9g.jpg)
## 代码实现
```
package graph;

/**
 * 顶点类
 */
class Vertex {
    private char label;

    public Vertex(char label) {
        this.label = label;
    }
}



/**
 * 图
 */
public class Graph {
    //顶点数组
    private Vertex[] vertexList;
    //邻接矩阵
    private int[][] adjMat;
    //顶点最大数目
    private int maxSize;
    //已添加顶点
    private int nVertex;

    public Graph() {
        vertexList = new Vertex[maxSize];
        adjMat = new int[maxSize][maxSize];
        for (int i = 0; i < maxSize; i++) {
            for (int j = 0; j < maxSize; j++) {
                adjMat[i][j] = 0;
            }
        }
        nVertex = 0;
    }

    /**
     * 添加顶点
     */
    public void addVertex(char label){
        vertexList[nVertex++]=new Vertex(label);
    }

    /**
     * 添加边
     */
    public void addEdge(int start,int end){
        adjMat[start][end]=1; 
        adjMat[end][start]=1;
    }
    
}

```
# 图的搜索
## 深度优先搜索（DFS）
### 深度优先规则
	1.	如果可能，访问一个邻接的未访问过的顶点，标记他，并把它放入栈中
	2.	当不能执行规则1时，如果栈不为空，就从栈中弹出一个顶点
	3.	当不蹦执行规则1和2时，就完成了整个搜索过程
### 深度优先代码实现
```
package graph;


import stack.MyStack;

/**
 * 图
 */
public class Graph {
    //顶点数组
    private Vertex[] vertexList;
    //邻接矩阵
    private int[][] adjMat;
    //顶点最大数目
    private int maxSize=20;
    //已添加顶点个数
    private int nVertex;
    //栈
    private MyStack stack;


    public Graph() {
        vertexList = new Vertex[maxSize];
        adjMat = new int[maxSize][maxSize];
        for (int i = 0; i < maxSize; i++) {
            for (int j = 0; j < maxSize; j++) {
                adjMat[i][j] = 0;
            }
        }
        nVertex = 0;
        stack = new MyStack(maxSize);
    }

    /**
     * 添加顶点
     */
    public void addVertex(char label) {
        vertexList[nVertex++] = new Vertex(label);
    }

    /**
     * 添加边
     */
    public void addEdge(int start, int end) {
        adjMat[start][end] = 1;
        adjMat[end][start] = 1;
    }

    /**
     * 获取未访问过的邻接节点
     *
     * @return
     */
    public int getadjUnvistedVertex(int v) {
        for (int i = 0; i < nVertex; i++) {
            if (adjMat[v][i] == 1 && vertexList[i].wasVisited == false) {
                return i;
            }
        }
        return -1;
    }

    /**
     * 深度优先搜索
     */
    public void dfs() {
        //首先访问0号节点,并标记已访问
        vertexList[0].wasVisited = true;
        //显示该顶点
        disPlayVertex(0);
        //压入栈中
        stack.push(0);
        //规则2
        while (!stack.isEmpty()) {
            //获取一个未访问的邻接点
            int v = getadjUnvistedVertex((int) stack.peek());
            if (v == -1) {
                //弹出一个顶点
                stack.pop();
            } else {
                //标记为未访问的
                vertexList[v].wasVisited = true;
                disPlayVertex(v);
                stack.push(v);
            }
        }
        //搜索完成以后，要将访问信息修改复原
        for (int i = 0; i < nVertex; i++) {
            vertexList[i].wasVisited = false;
        }
    }

    public void disPlayVertex(int v) {
        System.out.println(vertexList[v].label);
    }

}

```
## 广度优先搜索（BFS）
### 广度优先规则
	1.	访问下一个邻接的未访问过的顶点，这个顶点必须是当前节点的邻接点，标记他，并把他插入到队列中
	2.	如果无法执行规则1，那么就从队列头取出一个顶点，并使其当做当前顶点。
	3.	当前队列为空不能执行规则2时，就完成整个搜索过程
### 广度优先代码实现
```



```