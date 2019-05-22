---
title: golang的pprof使用技巧
categories:
  - 后端
  - Golang
comments: true
toc: true
abbrlink: 874ecf74
date: 2019-02-26 23:12:01
---
# 1.安装易用的pprof
golang自带的prof包是runtime/pprof，这个是低级别的，需要你手动做一些设置等等周边工作，不利于我们快速上手，利用pprof帮助我们解决实际的问题。这里推荐davecheney封装的pprof，它可以1行代码，让你用上pprof，专心解决自己的代码问题，下载：
```shell
go get github.com/pkg/profile
```
# 2.安装graphviz
pprof生成的prof文件时二进制的，需要把这个二进制的文件转换为我们人类可读的，graphviz可以帮助我们把二进制的prof文件转换为图像。Mac安装：
```shell
brew install graphviz
```
# 3.修改main函数
只需要为hi.go增加这一行，defer profile.Start().Stop()，程序运行时，默认就会记录cpu数据
# 4.编译运行你的函数
```go
package main

import (
	"fmt"
	"github.com/pkg/profile"
)

func main() {
	defer profile.Start().Stop()
	sl:=makeSlice()
	fmt.Printf("sum=%d\n",sumSlice(sl))
}

func makeSlice() []int {
	sl := make([]int, 10000000)
	for idx := range sl {
		sl[idx] = idx
	}
	return sl
}

func sumSlice(sl []int) int {
	sum := 0
	for _, x := range sl {
		sum += x
	}
	return sum
}

```
运行代码
```
go build hi.go
./hi
```
应当看到类似的结果，它输出了生成的cpu.pprof的路径：
```
2019/02/26 23:24:22 profile: cpu profiling enabled, /var/folders/zy/d8yskqjj09q21y7jnc0vbsqh0000gn/T/profile152894194/cpu.pprof  
sum=49999995000000  
2019/02/26 23:24:22 profile: cpu profiling disabled, /var/folders/zy/d8yskqjj09q21y7jnc0vbsqh0000gn/T/profile152894194/cpu.pprof  
```
# 5.可视化prof
可视化有多种方式，可以转换为text、pdf、svg等等。text命令是
```shell
go tool pprof --text /path/to/yourbinary /var/path/to/cpu.pprof
```
```go
go tool pprof --text ./hi /var/folders/zy/d8yskqjj09q21y7jnc0vbsqh0000gn/T/profile626723859/cpu.pprof
File: hi
Type: cpu
Time: Feb 26, 2019 at 11:29pm (CST)
Duration: 203.53ms, Total samples = 100ms (49.13%)
Showing nodes accounting for 100ms, 100% of 100ms total
      flat  flat%   sum%        cum   cum%
      60ms 60.00% 60.00%       60ms 60.00%  runtime.usleep
      30ms 30.00% 90.00%       30ms 30.00%  main.makeSlice
      10ms 10.00%   100%       10ms 10.00%  runtime.nanotime
         0     0%   100%       30ms 30.00%  main.main
         0     0%   100%       10ms 10.00%  runtime.gcBgMarkWorker
         0     0%   100%       70ms 70.00%  runtime.gcBgMarkWorker.func2
         0     0%   100%       70ms 70.00%  runtime.gcDrain
         0     0%   100%       30ms 30.00%  runtime.main
         0     0%   100%       70ms 70.00%  runtime.markroot
         0     0%   100%       70ms 70.00%  runtime.markroot.func1
         0     0%   100%       60ms 60.00%  runtime.mstart
         0     0%   100%       60ms 60.00%  runtime.osyield
         0     0%   100%       70ms 70.00%  runtime.scang
         0     0%   100%       70ms 70.00%  runtime.systemstack
```
生成pdf图
```
 go tool pprof --pdf ./hi /var/folders/zy/d8yskqjj09q21y7jnc0vbsqh0000gn/T/profile626723859/cpu.pprof > cpu.pdf

```

# 6.获取内存ppfo
如果你掌握了cpu pprof，mem pprof轻而易举就能拿下，只需要改1行代码：
```go
defer profile.Start(profile.MemProfile).Stop()
```