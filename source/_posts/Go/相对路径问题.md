---
title: Go相对路径问题
categories:
  - 后端
  - Golang
comments: true
toc: true
abbrlink: e9f5e83
date: 2019-05-10 10:44:58
---

## 问题
1、 go run 我们上移目录层级，到 $GOPATH/src 下，执行 go run gin-blog/main.go
```
[$]# go run gin-blog/main.go
Fail to parse 'conf/app.yam': open conf/app.ini: no such file or directory
exit status 1
```
2、 go build，执行 ./gin-blog/main
```
[$]# ./gin-blog/main
 Fail to parse 'conf/app.ini': open conf/app.ini: no such file or directory
```

## 测试
编写获取当前路径的方法
```
import (
	"path/filepath"
	"os"
	"os/exec"
	"string"
)

func GetAppPath() string {
    file, _ := exec.LookPath(os.Args[0])
    path, _ := filepath.Abs(file)
    index := strings.LastIndex(path, string(os.PathSeparator))

    return path[:index]
}
```
执行`go run` 得到
```
$ go run main.go
C:\Users\abner（~1\AppData\Local\Temp\go-build536365654\b001\exe
```

## 剖析
我们聚焦在 `go run` 的输出结果上，发现它是一个临时文件的地址，这是为什么呢？

在go help run中，我们可以看到

```
A Go source file is defined to be a file ending in a literal ".go" suffix.
也就是 go run 执行时会将文件放到 /tmp/go-build... 目录下，编译并运行
```

因此`go run main.go`出现/tmp/go-build536365654/b001/exe结果也不奇怪了，因为它已经跑到临时目录下去执行可执行文件了

这就已经很清楚了，那么我们想想，会出现哪些问题呢

- 依赖相对路径的文件，出现路径出错的问题
- `go run` 和 `go build` 不一样，一个到临时目录下执行，一个可手动在编译后的目录下执行，路径的处理方式会不同
- 不断go run，不断产生新的临时文件
这其实就是根本原因了，因为 go run 和 go build 的编译文件执行路径并不同，执行的层级也有可能不一样，自然而然就出现各种读取不到的奇怪问题了

## 解决方案
一、获取编译后可执行文件路径
	1.	将配置文件的相对路径与GetAppPath()的结果相拼接，可解决go build main.go的可执行文件跨目录执行的问题（如：./src/gin-blog/main）
	2.	通过传递参数指定绝对路径，可解决go run的问题
二、增加os.Getwd()进行多层判断
参见 [beego](https://github.com/astaxie/beego/blob/develop/config/config.go) 读取 app.conf 的代码

该写法可兼容 go build 和在项目根目录执行 `go run` ，但是若跨目录执行 `go run` 就不行
三、配置全局系统变量
我们可以通过os.Getenv来获取系统全局变量，然后与相对路径进行拼接

1、 设置项目工作区

简单来说，就是设置项目（应用）的工作路径，然后与配置文件、日志文件等相对路径进行拼接，达到相对的绝对路径来保证路径一致

参见 gogs 读取GOGS_WORK_DIR进行拼接的代码

2、 利用系统自带变量

简单来说就是通过系统自带的全局变量，例如$HOME等，将配置文件存放在$HOME/conf或/etc/conf下

这样子就能更加固定的存放配置文件，不需要额外去设置一个环境变量

## 拓展
`go test` 在一些场景下也会遇到路径问题，因为`go test`只能够在当前目录执行，所以在执行测试用例的时候，你的执行目录已经是测试目录了

需要注意的是，如果采用获取外部参数的办法，用 os.args 时，go test -args 和 go run、go build 会有命令行参数位置的不一致问题