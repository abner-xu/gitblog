---
title: Go-字符串高效拼接
categories:
  - 后端
  - Golang
comments: true
toc: true
date: 2019-08-27 22:19:39
---

# +号拼接
这种拼接最简单，也最容易被我们使用，因为它是不限编程语言的，比如Go语言有，Java也有，它们是+号运算符，在运行时计算的。现在演示下这种拼接的代码，虽然比较简单。
```
func StringPlus() string{
	var s string
	s+="昵称"+":"+"飞雪无情"+"\n"
	s+="博客"+":"+"http://www.flysnow.org/"+"\n"
	s+="微信公众号"+":"+"flysnow_org"
	return s
}
```
我们可以自己写个用例测试下，可以打印出和我们例子中一样的内容。那么这种最常见的字符串拼接的方式性能怎么样的呢，我们测试下：
```
func BenchmarkStringPlus(b *testing.B) {
	for i:=0;i<b.N;i++{
		StringPlus()
	}
}
```
运行`go test -bench=. -benchmem` 查看性能输出如下：
```
BenchmarkStringPlus-8   20000000    108 ns/op   144 B/op    2 allocs/op
```
每次操作需要108ns,进行2次内存分配，分配114字节的内存。

# fmt 拼接
这种拼接，借助于`fmt.Sprint`系列函数进行拼接，然后返回拼接的字符串。
```
func StringFmt() string{
	return fmt.Sprint("昵称",":","飞雪无情","\n","博客",":","http://www.flysnow.org/","\n","微信公众号",":","flysnow_org")
}

func BenchmarkStringFmt(b *testing.B) {
	for i:=0;i<b.N;i++{
		StringFmt()
	}
}
```
运行查看测试结果：
```
BenchmarkStringFmt-8    5000000     385 ns/op   80 B/op     1 allocs/op
```
<font color=red>虽然每次操作内存分配只有1次，分配80字节也不多，但是每次操作耗时太长，性能远没有`+`号操作快。</font>


# Join 拼接
这个是利用`strings.Join`函数进行拼接，接受一个字符串数组，转换为一个拼接好的字符串。
```
func StringJoin() string{
	s:=[]string{"昵称",":","飞雪无情","\n","博客",":","http://www.flysnow.org/","\n","微信公众号",":","flysnow_org"}
	return strings.Join(s,"")
}

func BenchmarkStringJoin(b *testing.B) {
	for i:=0;i<b.N;i++{
		StringJoin()
	}
}
```
为了方便，把性能测试的代码放一起了，现在看看性能测试的效果。
```
BenchmarkStringJoin-8   10000000    177 ns/op   160 B/op    2 allocs/op
```
<font color=red>整体和`+`操作相差不了太多，大概低0.5倍的样子。</font>

# buffer 拼接
这种被用的也很多，使用的是`bytes.Buffer`进行的字符串拼接，它是非常灵活的一个结构体，不止可以拼接字符串，还是可以`byte,rune`等，并且实现了`io.Writer`接口，写入也非常方便。
```
func StringBuffer() string {
	var b bytes.Buffer
	b.WriteString("昵称")
	b.WriteString(":")
	b.WriteString("飞雪无情")
	b.WriteString("\n")
	b.WriteString("博客")
	b.WriteString(":")
	b.WriteString("http://www.flysnow.org/")
	b.WriteString("\n")
	b.WriteString("微信公众号")
	b.WriteString(":")
	b.WriteString("flysnow_org")
	return b.String()
}

func BenchmarkStringBuffer(b *testing.B) {
	for i:=0;i<b.N;i++{
		StringBuffer()
	}
}
```
看看他的性能，运行输出即可：
```
BenchmarkStringBuffer-8     5000000     291 ns/op   336 B/op    3 allocs/op
```
好像并不是太好,和最差的fmt拼接差不多，和`+`号，Join拼接差好远，内存分配也比较多。每次操作耗时也很长。

# builder 拼接
为了改进buffer拼接的性能，从go 1.10 版本开始，增加了一个builder类型，用于提升字符串拼接的性能。它的使用和buffer几乎一样。
```
func StringBuilder() string {
	var b strings.Builder
	b.WriteString("昵称")
	b.WriteString(":")
	b.WriteString("飞雪无情")
	b.WriteString("\n")
	b.WriteString("博客")
	b.WriteString(":")
	b.WriteString("http://www.flysnow.org/")
	b.WriteString("\n")
	b.WriteString("微信公众号")
	b.WriteString(":")
	b.WriteString("flysnow_org")
	return b.String()
}

func BenchmarkStringBuilder(b *testing.B) {
	for i:=0;i<b.N;i++{
		StringBuilder()
	}
}
```
官方都说比buffer性能好了，我们看看性能测试的结果。
```
BenchmarkStringBuilder-8    10000000    170 ns/op   232 B/op    4 allocs/op
```
的确提升了，提升了一倍，虽然每次分配的内存次数有点多，但是每次分配的内存大小比buffer要少。

# 性能对比
以上就是常用的字符串拼接的方式，现在我们把这些测试结果，汇总到一起，对比下看看,因为Benchmark的测试，对于性能只显示，我把测试的时间设置为3s（秒），把时间拉长便于对比测试，同时生成了cpu profile文件，用于性能分析。

运行`go test xx.go -bench=. -benchmem -benchtime=3s -cpuprofile=profile.out`得到如下测试结果：
```
StringPlus-8    50000000    112 ns/op   144 B/op    2 allocs/op
StringFmt-8     20000000    344 ns/op   80 B/op     1 allocs/op
StringJoin-8    30000000    171 ns/op   160 B/op    2 allocs/op
StringBuffer-8  20000000    302 ns/op   336 B/op    3 allocs/op
StringBuilder-8 30000000    171 ns/op   232 B/op    4 allocs/op
```
我们通过`go tool pprof profile.out` 看下我们输出的cpu profile信息。这里主要使用top命令。
```
Showing top 15 nodes out of 89
      flat  flat%   sum%        cum   cum%
    11.99s 42.55% 42.55%     11.99s 42.55%  runtime.kevent
     6.30s 22.36% 64.90%      6.30s 22.36%  runtime.pthread_cond_wait
     1.65s  5.86% 70.76%      1.65s  5.86%  runtime.pthread_cond_signal
     1.11s  3.94% 74.70%      1.11s  3.94%  runtime.usleep
     1.10s  3.90% 78.60%      1.10s  3.90%  runtime.pthread_cond_timedwait_relative_np
     0.58s  2.06% 80.66%      0.62s  2.20%  runtime.wbBufFlush1
     0.51s  1.81% 82.47%      0.51s  1.81%  runtime.memmove
     0.44s  1.56% 84.03%      1.81s  6.42%  fmt.(*pp).printArg
     0.39s  1.38% 85.42%      2.36s  8.37%  fmt.(*pp).doPrint
     0.36s  1.28% 86.69%      0.70s  2.48%  fmt.(*buffer).WriteString (inline)
     0.34s  1.21% 87.90%      0.93s  3.30%  runtime.mallocgc
     0.20s  0.71% 88.61%      1.20s  4.26%  fmt.(*fmt).fmtS
     0.18s  0.64% 89.25%      0.18s  0.64%  fmt.(*fmt).truncate
     0.16s  0.57% 89.82%      0.16s  0.57%  runtime.memclrNoHeapPointers
     0.15s  0.53% 90.35%      1.35s  4.79%  fmt.(*pp).fmtString
```
前15个，可以看到fmt拼接的方式是最差的，因为fmt里很多方法耗时排在了最前面。buffer的WriteString方法也比较耗时。

以上的TOP可能还不是太直观，如果大家看火焰图的话，就会更清晰。性能最好的是`+`号拼接、Join拼接，最慢的是fmt拼接，这里的builder和buffer拼接差不多，并没有发挥出其能力。

# 疑问
从整个性能的测试和分析来看，我们期待的builder并没有发挥出来，这是不是意味着builder不实用了呢？还不如+号和Join拼接呢？继续接着分析，
https://www.flysnow.org/2018/11/05/golang-concat-strings-performance-analysis.html#%E6%8B%BC%E6%8E%A5%E5%87%BD%E6%95%B0%E6%94%B9%E9%80%A0