---
title: go mod 技巧
categories:
  - 后端
  - golang
tags:
  - book
comments: true
toc: true
date: 2019-05-21 23:53:20
---
# gomod初尝试
GO111MODULE可以设置为三个字符串值之一：off，on或auto（默认值）。
- off : go命令从不使用新模块支持。它查找vendor 目录和GOPATH以查找依赖关系;也就是继续使用“GOPATH模式”。
- on : go命令需要使用模块，go 会忽略 $GOPATH 和 vendor 文件夹，只根据go.mod下载依赖。
- auto 或未设置: go命令根据当前目录启用或禁用模块支持。仅当当前目录位于$GOPATH/src之外并且其本身包含go.mod文件或位于包含go.mod文件的目录下时，才启用模块支持。

# go mod命令
```code 
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

# goland使用go mod
![](http://ww1.sinaimg.cn/large/aaba1596ly1g39dvp55v3j20li09f0tq.jpg)

# go翻墙
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