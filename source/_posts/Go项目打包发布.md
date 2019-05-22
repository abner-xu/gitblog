---
title: 基于Scratch创建最小且安全的golang docker镜像
categories:
  - 后端
  - Golang
comments: true
toc: true
date: 2019-05-18 10:40:58
---
# golang打包镜像对比
从docker官方下载了镜像以后，发现一个运行go的环境需要779M,我得项目才3~4M，这是不可以接受的
```
$ docker image list
golang    latest       1c1309ff8e0d        10 days ago         779MB
```
就算使用alpine镜像也有269M
```
$ docker image list
golang     alpine      bbab7aea1231        7 weeks ago         269MB
```
于是打算自己构建golang运行的最小镜像.   

# docker的Multi-stage builds
多阶段构建是需要Docker 17.05或更高版本的新功能。在此之前，我们将看到docker scratch image，Zero Bytes Image。非常适合嵌入我们的静态二进制文件。 

先上代码,例子说明
```docker
FROM        golang:alpine AS builder
MAINTAINER  Chen Xu <abner510@126.com>
RUN         apk update && apk add --no-cache git ca-certificates tzdata && update-ca-certificates && adduser -D -g '' appuser
ENV         GOPROXY https://goproxy.io
ENV         GO111MODULE on
WORKDIR     /go/cache
ADD         go.mod .
ADD         go.sum .
RUN         go mod download
WORKDIR     /go/src/ginx
ADD        . /go/src/ginx
RUN         CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -ldflags="-w -s" -o server

#容器构建
FROM        scratch AS prod
COPY        --from=builder /etc/passwd /etc/passwd
COPY        --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY        --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY        --from=builder /go/src/ginx/config /app/config
COPY        --from=builder /go/src/ginx/server /app
USER        appuser
EXPOSE      9000
CMD         ["/app/server", "-e=prod"]
```
## 代码示例说明
###  添加SSL证书支持HTTPS和时区
```
apk add --no-cache git ca-certificates tzdata && update-ca-certificates
```
###   添加运行golang的用户
```
adduser -D -g '' appuser
```
###  go mod模式项目包管理，加快构建速度
```
ENV         GOPROXY https://goproxy.io   #设置代理，国内的墙你懂的
ENV         GO111MODULE on  #开启go mod 模式  ，老版本GO111MODULE=auto 默认是自动
WORKDIR     /go/cache  # 设置包的下载目录
ADD         go.mod .
ADD         go.sum .
RUN         go mod download
```
![](http://ww1.sinaimg.cn/large/aaba1596ly1g35sornlfqj20j70fl0ub.jpg)

###   CGO编译使用
由于scratch是空镜像，
```
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -ldflags="-w -s" -o server
```
- `CGO_ENABLED=0` ，CGO_ENABLED 是因为 交叉编译不支持 CGO，我们这里禁用它
- `-a -installsuffix cgo` , `-a`:强制重新编译，简单来说，就是不利用缓存或已编译好的部分文件，直接所有包都是最新的代码重新编译和关联; `installsuffix`:在软件包安装的目录中增加后缀标识，以保持输出与默认版本分开

###   制作golang运行的容器
```
FROM        scratch AS prod #镜像版本
COPY        --from=builder /etc/passwd /etc/passwd  #这里需要使用appuer账号信息
COPY        --from=builder /usr/share/zoneinfo /usr/share/zoneinfo #时区
COPY        --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ #SSL证书文件
COPY        --from=builder /go/src/ginx/config /app/config #应用配置文件
COPY        --from=builder /go/src/ginx/server /app #应用二进制文件
USER        appuser #运行用户
EXPOSE      9000 #暴露端口
CMD         ["/app/server", "-e=prod"] #运行应用，传入运行参数
```

### 阿里云加速翻墙速度
1、创建镜像仓库
![](http://ww1.sinaimg.cn/large/aaba1596ly1g35tf5x503j20t10rb770.jpg)
2、填写仓库信息
![](http://ww1.sinaimg.cn/large/aaba1596ly1g35tf5x503j20t10rb770.jpg)
3、选择仓库`管理`，进行配置仓库
4、选择git仓库版本，这里本人是放在github上，所以选择github，进行授权，选择自己的仓库和项目，配置如下具体dockerfile文件根据自己仓库路径配置
![](http://ww1.sinaimg.cn/large/aaba1596ly1g35tiibz9wj20zb0l90uz.jpg)
5、选择构建即可
