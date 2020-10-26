---
title: window下基于virtual-box的 docker LNMP环境搭建
comments: true
toc: true
categories:
  - 工具
  - Docker
tags:
  - Docker
abbrlink: fe0f28d
date: 2017-12-25 21:49:58
---
## windows下工具安装
1.  centos下载：[下载](https://mirrors.aliyun.com/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-2003.iso)
2.  virtual-box下载: [下载](https://dl.softmgr.qq.com/original/System/VirtualBox-6.1.16-140961-Win.exe)
3.  git下载:[下载](https://dl.softmgr.qq.com/original/Development/Git-2.29.0-64-bit.exe)

## 拉取安装目录
- 地址1：http://gitlab.kerlala.com:8888/xuchen/docker

或者

- 地址2：git@gitlab.kerlala.com:xuchen/docker.git

例如拉取到E盘work目录
![0.png](http://ww1.sinaimg.cn/large/007lnJOlgy1gk2xepcx5xj30gt0h5753.jpg)
```shell
 git clone git@gitlab.kerlala.com:xuchen/docker.git
```

## 虚拟机安装操作系统
1.  新建虚拟机
    ![1.png](http://ww1.sinaimg.cn/large/007lnJOlgy1gk2xfxuv69j30so0hrgmc.jpg)
2.  新建注意事项
这里建议选80G动态空间，因为一旦虚拟机磁盘满了，迁移非常容易崩
    ![2.png](http://ww1.sinaimg.cn/large/007lnJOlgy1gk2xh29b57j30d40cqt8v.jpg)
3.  操作系统安装，选择安装磁盘，安装过程（略）
    ![3.png](http://ww1.sinaimg.cn/large/007lnJOlgy1gk2xjisinzj30i80fot94.jpg)
4.  进入系统，开启centos网卡
    1.  root用户进入虚拟机开启网卡，`vi /etc/sysconfig/network-scripts/ifcfg-enp0s3` ,部分网卡可能不是`enp0s3`，使用table键补全，查看即可
    2.  进入后，修改`ONBOOT=no`为yes,保存退出,重启虚拟机
      

## 配置端口    
![4.png](http://ww1.sinaimg.cn/large/007lnJOlgy1gk2y762t2uj31il0mxwg9.jpg)

## 安装docker

1.  使用git bash上传本地`docker`文件夹中的shell脚本。`scp install.sh root@127.0.0.1:/root`
2.  登录虚拟机`ssh root@127.0.0.1`
3.  安装
    1.  `vi install`
    2.  `:set ff=unix` 保存退出
    3.  `./install` 根据提示 输入 1，完成后`关闭虚拟机软件`
4.  重新打开虚拟机软件，进行如下图操作设置
    ![5.png](http://ww1.sinaimg.cn/large/007lnJOlgy1gk3025p1z6j30wv0r840b.jpg)
启动虚拟机，选择如下配置
    ![6.png](http://ww1.sinaimg.cn/large/007lnJOlgy1gk306sxhsyj30jg0csabw.jpg)
5.  登录虚拟机， `./install` 根据提示 输入 2，完成步骤2安装,重启虚拟机    
    
    

