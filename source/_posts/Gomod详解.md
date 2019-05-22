---
title: go modules 详解
categories:
  - 后端
  - Golang
tags:
  - go mod
comments: true
toc: true
abbrlink: 4a3656eb
date: 2019-05-22 10:05:09
---
# go mod的介绍

我们以前用 go get 获取依赖其实是有潜在危险的，因为我们不确定最新版依赖是否会破坏掉我们项目对依赖包的使用方式，即当前项目可能会出现不兼容最新依赖包的问题。随着 go1.11 的发布，go 给我们带来了 module 新特性，这是 Go 语言新的一套依赖管理系统。

在默认情况下，$GOPATH 默认情况下是不支持 go mudules 的，我们需要在项目目录下手动执行以下命令：`$ export GO111MODULE=on`,这也表明了 go 要利用 modules 机制消灭 $GOPATH 的决心啊！

GO111MODULE可以设置为三个字符串值之一：off，on或auto（默认值）
- off : go命令从不使用新模块支持。它查找vendor 目录和GOPATH以查找依赖关系;也就是继续使用“GOPATH模式”。
- on : go命令需要使用模块，go 会忽略 $GOPATH 和 vendor 文件夹，只根据go.mod下载依赖。
- auto 或未设置: go命令根据当前目录启用或禁用模块支持。仅当当前目录位于$GOPATH/src之外并且其本身包含go.mod文件或位于包含go.mod文件的目录下时，才启用模块支持。

演示使用教程
- 创建项目,为了配合 go modules 机制，我们 $GOPATH 以外的目录创建一个 testmod 的包：
```code
$ mkdir testmod
$ cd testmod

$ echo 'package testmod
		import "fmt"
	func Hi(name string) string {
        return fmt.Sprintf("Hi, %s", name)
}' >> testmod.go
```
- 初始化module
```code
$ go mod init github.com/objcoding/testmod
#这里如果是从git下来的，可以直接进入项目里面执行go init
go: creating new go.mod: module github.com/objcoding/testmod
```
- 推送到 github 仓库
```code
$ git init
$ git add *
$ git commit -am "First commit"
$ git push -u origin master
```

--

# go mudules 版本规则
go modules 是一个版本化依赖管理系统，版本需要遵循一些规则，比如版本号需要遵循以下格式：
```code
vX.Y.Z-pre.0.yyyymmddhhmmss-abcdefabcdef
vX.0.0-yyyymmddhhmmss-abcdefabcdef
vX.Y.(Z+1)-0.yyyymmddhhmmss-abcdefabcdef
vX.Y.Z
```
vX.Y.Z 是我们仓库打的标签版本，也就是 go modules 是根据仓库标签来确定版本号的，因此我们发布版本时，需要给我们的仓库打上一个标签版本号。

也就是版本号 + 时间戳 +hash，我们自己指定版本时只需要指定版本号即可，没有版本 tag 的则需要找到对应 commit 的时间和 hash 值。

还有一个重要的规则是，版本 0 和 1，最好需要有不同的依赖路径，如：v1.0.0 和 v2.0.0 是有不同的依赖路径，下面会详细介绍一下这个版本规则。
--
# 发布版本
了解了 go modules 的版本规则后，现在我们发布一下该项目的版本：
```code
$ git tag v1.0.0
$ git push --tags
```
这时我们最好还需要创建一条 v1 分支，以便我们在其它分支写代码不会影响到 v1.0.0 版本：
```code
$ git checkout -b v1
$ git push -u origin v1
```

--

# 升级版本
```code
$ git commit -m "update testmod" testmod.go
$ git tag v1.0.1
$ git push --tags origin v1
```

现在我们的 项目已经升级到 v1.0.1 版本了，我们可以有多种方式获取这个版本依赖，go1.11 中，go get 拥有了很多新特性，我们可以直接通过以下命令获取 v1.01 版本依赖：
```code
$ go get github.com/objcoding/testmod@v1.0.1
或者
$ go mod edit -require="github.com/objcoding/testmod@v1.0.1"
$ go mod tidy
```
go mod edit -require 可以主动修改 go.md 文件中依赖的版本号，然后通过 go mod tidy 对版本进行更新，它会自动清理掉不需要的依赖项，同时可以将依赖项更新到当前版本。

# 主要版本升级
上面版本规则说了，版本 0 和 1，即大版本更新，最好需要有不同的依赖路径，如：v1.0.0 和 v2.0.0 是有不同的依赖路径，那么用 go modules 怎么实现呢，我们可以通过修改 go.mod 文件第一行添加新路径：
```code
$ cd testmod
$ echo 'module github.com/objcoding/testmod/v2' >> go.mod
```
然后我们修改 testmod 函数 Hi()：
```code
$ cd testmod

$ echo 'package testmod
import (
	"fmt"
	"errors"
)
func Hi(name, lang string) (string, error) {
	switch lang {
	case "en":
		return fmt.Sprintf("Hi, %s!", name), nil
	default:
		return "", errors.New("unknown language")
	}
}' >> testmod.go
```
这时，Hi() 方法将不兼容 v1 版本，我们需要新建一个 v2.0.0 版本，还是老样子，我们最好在 v2.0.0 版本新建一条 v2 分分支，将 v2.0.0 版本的代码写到这条分支中（这只是一个规范，实际上你将代码也写到任何分支中都行，go并没有这个规范）：
```code
$ git add *
$ git checkout -b v2
$ git commit testmod.go -m "v2.0.0"
$ git tag v2.0.0
$ git push --tags origin v2
```
然后我们修改代码中的版本import,为v2
```code
package main
import (
    "fmt"
  	"github.com/objcoding/testmod/v2"
)
func main() {
    fmt.Println(testmod.Hi("zch", "en"))
}
```
然后执行`go mod tidy`，go mod 会自动更新到v2.0.0版本

--

# go modules 命令大全
```shell 
go help modules

go mod命令

download    download modules to local cache (下载依赖的module到本地cache))
edit        edit go.mod from tools or scripts (编辑go.mod文件)
graph       print module requirement graph (打印模块依赖图))
init        initialize new module in current directory (再当前文件夹下初始化一个新的module, 创建go.mod文件))
tidy        add missing and remove unused modules (增加丢失的module，去掉未用的module)
vendor      make vendored copy of dependencies (将依赖复制到vendor下)
verify      verify dependencies have expected content (校验依赖)
why         explain why packages or modules are needed (解释为什么需要依赖)

初始化mod

go mod init [module]可以创建一个go.mod，只有一行信息module。
```
--
# goland支持go mod
![go mode](http://ww1.sinaimg.cn/large/aaba1596ly1g39dvp55v3j20li09f0tq.jpg)
--
# go 翻墙

swag安装为例

mac/linux swag 安装
```code
## 127.0.0.1:1087 是 ssr的hhtp代理
$ git config --global http.proxy "127.0.0.1:1087"
$ http_proxy=127.0.0.1:1087 go get -u -v github.com/swaggo/swag/cmd/swag
$ git config --global --unset-all http.proxy
$ git config --global --unset-all https.proxy
$ cd $GOPATH/src/github.com/swaggo/swag/cmd/swag
$ go install
$ swag -v #验证是否安装成功
```
window goget.bat文件
```code
@echo off

set http_proxy=socks5://127.0.0.1:1080
set https_proxy=socks5://127.0.0.1:1080

go get -u -v %*

echo ...

pause
```
git bash上用goget.bat url就行了~
--
# 自建GOPROXY server
项目地址 https://github.com/gomods/athens
Athens可以用来在公司内部建立自己的私有go mod服务器，或者在公网建立一个对外公开的GOPROXY server。