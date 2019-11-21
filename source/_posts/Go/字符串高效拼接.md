---
title: Go-字符串高效拼
categories:
  - 后端
  - Golang
comments: true
toc: true
abbrlink: 339e38c1
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
从整个性能的测试和分析来看，我们期待的builder并没有发挥出来，这是不是意味着builder不实用了呢？还不如+号和Join拼接呢？继续接着分析,猜测可能原因如下：
- 拼接的字符串大小
- 拼接的字符串数量

# 拼接函数改造
前面提到了2种可能的猜测，拼接字符串的数量和拼接字符串的大小，现在我们就开始证明这两种情况，为了演示方便，我们把原来的拼接函数修改一下，可以接受一个[]string类型的参数，这样我们就可以对切片数组进行字符串拼接，这里直接给出所有的拼接方法的改造后实现。
```
func StringPlus(p []string) string{
	var s string
	l:=len(p)
	for i:=0;i<l;i++{
		s+=p[i]
	}
	return s
}

func StringFmt(p []interface{}) string{
	return fmt.Sprint(p...)
}

func StringJoin(p []string) string{
	return strings.Join(p,"")
}

func StringBuffer(p []string) string {
	var b bytes.Buffer
	l:=len(p)
	for i:=0;i<l;i++{
		b.WriteString(p[i])
	}
	return b.String()
}

func StringBuilder(p []string) string {
	var b strings.Builder
	l:=len(p)
	for i:=0;i<l;i++{
		b.WriteString(p[i])
	}
	return b.String()
}
```

# 测试用例
以上的字符串拼接函数修改后，我们就可以构造不同大小的切片进行字符串拼接测试了。为了模拟上次的效果，我们先用10个切片大小的字符串进行拼接测试。
```
const BLOG  = "http://www.flysnow.org/"

func initStrings(N int) []string{
	s:=make([]string,N)
	for i:=0;i<N;i++{
		s[i]=BLOG
	}
	return s;
}

func initStringi(N int) []interface{}{
	s:=make([]interface{},N)
	for i:=0;i<N;i++{
		s[i]=BLOG
	}
	return s;
}
```
这是两个构建测试用例切片数组的函数，可以生成N个大小的切片。第二个initStringi函数返回的是[]interface{}，这是专门为StringFmt(p []interface{})拼接函数准备的，减少类型之间的转换。

有了这两个生成测试用例的函数，我们就可以构建我们的Go语言性能测试了，我们先测试10个大小的切片。
```
func BenchmarkStringPlus10(b *testing.B) {
	p:= initStrings(10)
	b.ResetTimer()
	for i:=0;i<b.N;i++{
		StringPlus(p)
	}
}

func BenchmarkStringFmt10(b *testing.B) {
	p:= initStringi(10)
	b.ResetTimer()
	for i:=0;i<b.N;i++{
		StringFmt(p)
	}
}

func BenchmarkStringJoin10(b *testing.B) {
	p:= initStrings(10)
	b.ResetTimer()
	for i:=0;i<b.N;i++{
		StringJoin(p)
	}
}

func BenchmarkStringBuffer10(b *testing.B) {
	p:= initStrings(10)
	b.ResetTimer()
	for i:=0;i<b.N;i++{
		StringBuffer(p)
	}
}

func BenchmarkStringBuilder10(b *testing.B) {
	p:= initStrings(10)
	b.ResetTimer()
	for i:=0;i<b.N;i++{
		StringBuilder(p)
	}
}
```
在每个性能测试函数中，我们都会调用b.ResetTimer()，这是为了避免测试用例准备时间不同，带来的性能测试效果偏差问题
我们运行`go test -bench=. -run=NONE -benchmem` 查看结果。
```
BenchmarkStringPlus10-8     3000000     593 ns/op   1312 B/op   9 allocs/op
BenchmarkStringFmt10-8      5000000     335 ns/op   240 B/op    1 allocs/op
BenchmarkStringJoin10-8     10000000    200 ns/op   480 B/op    2 allocs/op
BenchmarkStringBuffer10-8   3000000     452 ns/op   864 B/op    4 allocs/op
BenchmarkStringBuilder10-8  10000000    231 ns/op   480 B/op    4 allocs/op
```
通过这次我们可以看到，`+`号拼接不再具有优势，因为string是不可变的，每次拼接都会生成一个新的`string`,也就是会进行一次内存分配，我们现在是10个大小的切片，每次操作要进行9次进行分配，占用内存，所以每次操作时间都比较长，自然性能就低下。

文章上面关于`+`拼接还有印象，`+`加号拼接的性能测试中显示的只有2次内存分配，但是我们用了好多个`+`的。
```
func StringPlus() string{
	var s string
	s+="昵称"+":"+"飞雪无情"+"\n"
	s+="博客"+":"+"http://www.flysnow.org/"+"\n"
	s+="微信公众号"+":"+"flysnow_org"
	return s
}
```
再来回顾下这段代码，的确是有很多+的，但是只有2次内存分配，我们可以大胆猜测,是3次s+=导致的，正常和我们今天测试的10个长度的切片，只有9次内存分配一样。下面我们通过运行如下命令看下Go编译器对这段代码的优化：`go build -gcflags="-m -m" main.go`,输出中有如下内容：
```
can inline StringPlus as: func() string { var s string; s = <N>; s += "昵称:飞雪无情\n"; s += "博客:http://www.flysnow.org/\n"; s += "微信公众号:flysnow_org"; return s }
```
现在一目了然了，其实是编译器帮我们把字符串做了优化，只剩下3个`s+=`

这次，采用长度为10个切片进行测试，也很明显测试出了Builder要比Buffer性能好很多，这个问题原因主要还是`[]byte`和`string`之间的转换，`Builder`恰恰解决了这个问题。
```
func (b *Builder) String() string {
	return *(*string)(unsafe.Pointer(&b.buf))
}
```
很高效的解决方案。

# 100个字符串
现在我们测试下100个字符串拼接的情况，对于我们上面的代码，要改造非常容易，这里直接给出测试代码。
```
func BenchmarkStringPlus100(b *testing.B) {
	p:= initStrings(100)
	b.ResetTimer()
	for i:=0;i<b.N;i++{
		StringPlus(p)
	}
}

func BenchmarkStringFmt100(b *testing.B) {
	p:= initStringi(100)
	b.ResetTimer()
	for i:=0;i<b.N;i++{
		StringFmt(p)
	}
}

func BenchmarkStringJoin100(b *testing.B) {
	p:= initStrings(100)
	b.ResetTimer()
	for i:=0;i<b.N;i++{
		StringJoin(p)
	}
}

func BenchmarkStringBuffer100(b *testing.B) {
	p:= initStrings(100)
	b.ResetTimer()
	for i:=0;i<b.N;i++{
		StringBuffer(p)
	}
}

func BenchmarkStringBuilder100(b *testing.B) {
	p:= initStrings(100)
	b.ResetTimer()
	for i:=0;i<b.N;i++{
		StringBuilder(p)
	}
}
```
现在运行性能测试，看看100个字符串连接的性能怎么样，哪个函数最高效。
```
BenchmarkStringPlus100-8    100000  19711 ns/op     123168 B/op     99 allocs/op
BenchmarkStringFmt100-8     500000  2615 ns/op      2304 B/op       1 allocs/op
BenchmarkStringJoin100-8    1000000 1516 ns/op      4608 B/op       2 allocs/op
BenchmarkStringBuffer100-8  500000  2333 ns/op      8112 B/op       7 allocs/op
BenchmarkStringBuilder100-8 1000000 1714 ns/op      6752 B/op       8 allocs/op
```
`+`号和我们上面分析得一样，这次是99次内存分配，性能体验越来越差，在后面的测试中，会排除掉。

`fmt`和`bufrer`已经的性能也没有提升，继续走低。剩下比较坚挺的是`Join`和`Builder`。

# 1000 个字符串。
测试用力和上面章节的大同小异，所以我们直接看测试结果。
```
BenchmarkStringPlus1000-8       1000    1611985 ns/op   12136228 B/op   999 allocs/op
BenchmarkStringFmt1000-8        50000   28510 ns/op     24590 B/op      1 allocs/op
BenchmarkStringJoin1000-8       100000  15050 ns/op     49152 B/op      2 allocs/op
BenchmarkStringBuffer1000-8     100000  23534 ns/op     122544 B/op     11 allocs/op
BenchmarkStringBuilder1000-8    100000  17996 ns/op     96224 B/op      16 allocs/op
```
整体和100个字符串的时候差不多，表现好的还是`Join`和`Builder`。这两个方法的使用侧重点有些不一样， 如果有现成的数组、切片那么可以直接使用`Join`,但是如果没有，并且追求灵活性拼接，还是选择`Builder`。 `Join`还是定位于有现成切片、数组的（毕竟拼接成数组也要时间），并且使用固定方式进行分解的，比如逗号、空格等，局限比较大。

# 小结
至于10000个字符串拼接我这里就不做测试了，大家可以自己试试，看看是不是大同小异的。

从最近的这两篇文章的分析来看，我们大概可以总结出。

- + 连接适用于短小的、常量字符串（明确的，非变量），因为编译器会给我们优化。
- Join是比较统一的拼接，不太灵活
- fmt和buffer基本上不推荐
- builder从性能和灵活性上，都是上佳的选择。

# Builder 慢在哪
在前面可以看出来少量拼接，`builder`并不明显，那么到底慢在哪里呢？既然要优化Builder拼接，那么我们起码知道他慢在哪，我们继续使用我们上篇文章的测试用例，运行看下性能。
```
Builder10-8     5000000     258 ns/op       480 B/op        4 allocs/op
Builder100-8    1000000     2012 ns/op      6752 B/op       8 allocs/op
Builder1000-8   100000      21016 ns/op     96224 B/op      16 allocs/op
Builder10000-8  10000       195098 ns/op    1120226 B/op    25 allocs/op
```
针对既然要优化`Builder`拼接,采取了10、100、1000、10000四种不同数量的字符串进行拼接测试。我们发现每次操作都有不同次数的内存分配，内存分配越多，越慢，如果引起GC，就更慢了，首先我们先优化这个，减少内存分配的次数。

# 内存分配优化
通过cpuprofile，查看生成的火焰图可以得知，`runtime.growslice`函数会被频繁的调用，并且时间占比也比较长。我们查看`Builder.WriteString`的源代码：
```
func (b *Builder) WriteString(s string) (int, error) {
	b.copyCheck()
	b.buf = append(b.buf, s...)
	return len(s), nil
}
```
可以肯定是`append`方法触发了`runtime.growslice`，因为`b.buf`的容量`cap`不足，所以需要调用`runtime.growslice`扩充`b.buf`的容量，然后才可以追加新的元素`s...`。扩容容量自然会涉及到内存的分配，而且追加的内容越多，内存分配的次数越多，这和我们上面性能测试的数据是一样的。

既然问题的原因找到了，那么我们就可以优化了，核心手段就是减少`runtime.growslice`调用，甚至不调用。照着这个思路的话，我们就要提前为`b.buf`分配好容量`cap`。幸好`Builder`为我们提供了扩充容量的方法`Grow`，我们在进行`WriteString`之前，先通过`Grow`方法，扩充好容量即可。

现在开始改造我们的StringBuilder函数。
```
func StringBuilder(p []string,cap int) string {
	var b strings.Builder
	l:=len(p)
	b.Grow(cap)
	for i:=0;i<l;i++{
		b.WriteString(p[i])
	}
	return b.String()
}
```
增加一个参数`cap`，让使用者告诉我们需要的容量大小。`Grow`方法的实现非常简单，就是一个通过`make`函数，扩充`b.buf`大小，然后再拷贝`b.buf`的过程。
```
func (b *Builder) grow(n int) {
	buf := make([]byte, len(b.buf), 2*cap(b.buf)+n)
	copy(buf, b.buf)
	b.buf = buf
}
```
那么现在我们的性能测试用例变成如下：
```
func BenchmarkStringBuilder10(b *testing.B) {
	p:= initStrings(10)
	cap:=10*len(BLOG)
	b.ResetTimer()
	for i:=0;i<b.N;i++{
		StringBuilder(p,cap)
	}
}

func BenchmarkStringBuilder1000(b *testing.B) {
	p:= initStrings(1000)
	cap:=1000*len(BLOG)
	b.ResetTimer()
	for i:=0;i<b.N;i++{
		StringBuilder(p,cap)
	}
}
```
为了说明情况和简短代码，这里只有10和1000个元素的用例，其他类似。为了把性能优化到极致，我一次性把需要的容量分配足够。现在我们再运行性能（Benchmark）测试代码。
```
Builder10-8     10000000    123 ns/op       352 B/op    1 allocs/op
Builder100-8    2000000     898 ns/op       2688 B/op   1 allocs/op
Builder1000-8   200000      7729 ns/op      24576 B/op  1 allocs/op
Builder10000-8  20000       78678 ns/op     237568 B/op 1 allocs/op
```
性能足足翻了1倍多，只有1次内存分配，每次操作占用的内存也减少了一半多，降低了GC。

# 总结
背后的原理也非常清楚，就是预先分配内存，减少append过程中的内存重新分配和数据拷贝，这样我们就可以提升很多的性能。所以对于可以预见的长度的切，都可以提前申请申请好内存。

> 本文收集来源：https://www.flysnow.org