---
title: Ubuntu开机优化
categories:
  - 工具
  - Linux
tags:
  - Ubuntu
comments: true
toc: true
date: 2017-02-25 22:06:52
---
#### 安装openssh-server
-   sudo apt-get install openssh-server vim git

#### 替换国内源
-   sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup 
-   sudo vim /etc/apt/sources.list
-   
```
deb http://mirrors.aliyun.com/ubuntu/ trusty main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ trusty-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ trusty-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ trusty-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ trusty-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ trusty main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ trusty-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ trusty-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ trusty-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ trusty-backports main restricted universe multiverse
```

#### 删除libreoffice
-   sudo apt-get remove libreoffice

#### 删除Amazon的链接
-   sudo apt-get remove unity-webapps-common
   
#### 删掉基本不用的自带软件（用的时候再装也来得及）
-   sudo apt-get  remove   libreoffice-common   unity-webapps-common thunderbird totem rhythmbox  simple-scan gnome-mahjongg aisleriot gnome-mines cheese transmission-common gnome-orca gnome-sudoku webbrowser-app onboard deja-dup

#### 删除自带的软件中心
-   sudo apt-get remove software-center

#### 删除自带的图片编辑软件
-   sudo apt-get remove imagemagick

#### 关闭dash在线资源搜索
-   gsettings set com.canonical.Unity.Lenses remote-content-search 'none'

---


#### gdebi安装deb包更好的软件
-   sudo apt-get install gdebi

#### rpm安装
- sudo apt-get install alien ##alien默认没有安装，所以首先要安装它
- sudo alien xxxx.rpm ##将rpm转换位deb，完成后会生成一个同名的xxxx.deb
- sudo dpkg -i xxxx.deb ##安装

#### 安装App Grid软件中心
- sudo add-apt-repository ppa:appgrid/stable
- sudo apt-get update && sudo apt-get install appgrid

#### 微信
[微信客户端](https://github.com/geeeeeeeeek/electronic-wechat/releases)

#### 设置时间使用UTC
-   sudo vim /etc/default/rcS  ###将UTC=no改为UTC=yes

#### 安装Chrome
-   sudo add-apt-repository  ppa:chromium-daily/stable
-   sudo apt-get install chromium-browser chromium-browser-l10n

#### 安装搜狗输入法
-   vim /etc/apt/sources.list.d/ubuntukylin.list文件，加入ubuntu kylin的apt源
-   deb http://archive.ubuntukylin.com:10006/ubuntukylin trusty main
-   sudo apt-get update
-   sudo apt-get install sogoupinyin

#### 安装WPS Office
-   sudo apt-get install wps-office

#### Java
```shell
sudo vim ~/.bashrc
export JAVA_HOME=/home/abner/jdk1.8.0
export JRE_HOME=${JAVA_HOME}/jre  
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib  
export PATH=${JAVA_HOME}/bin:$PATH
source ~/.bashrc
```

#### 安装Sublime Text 3
- sudo add-apt-repository ppa:webupd8team/sublime-text-3
- sudo apt-get update
- sudo apt-get install sublime-text

#### 安装经典菜单指示器
- sudo add-apt-repository ppa:diesch/testing
- sudo apt-get update
- sudo apt-get install classicmenu-indicator

#### 安装系统指示器SysPeek
- sudo add-apt-repository ppa:nilarimogard/webupd8
- sudo apt-get update
- sudo apt-get install syspeek

#### 自定义DHCP网络的DNS Server IP地址
- sudo vim /etc/dhcp/dhclient.conf文件，在第21行#prepend domain-name-servers 127.0.0.1;下一行添加如下2行使用aliyun和114的DNS
- prepend domain-name-servers 114.114.114.114;
- prepend domain-name-servers 223.5.5.5;
- 这样可以优先使用aliyun的dns，次要使用114的DNS。

#### 安装axel(多线程下载工具)
- sudo apt-get install axel

```shell
#常见用法
直接下载这个文件
axel http://www.baidu.com/img/bdlogo.gif
多线程下载这个文件（10个线程）：
axel -n 10 http://www.baidu.com/img/bdlogo.gif
指定输出目录：
axel -o ~/Pictures/ http://www.baidu.com/img/bdlogo.gif
```
#### 安装ExFat文件系统驱动
- sudo apt-get install exfat-fuse

#### 安装unrar
- sudo apt-get install unrar
- 使用方法：unrar x test.rar


#### 安装美化主题
- sudo apt-get install unity-tweak-tool
- sudo apt-get install unity-webapps-common
- 下载主题包https://github.com/anmoljagetia/Flatabulous/archive/master.zip 解压到/usr/share/themes目录下。
- sudo add-apt-repository ppa:noobslab/icons && sudo apt-get update && sudo apt-get install ultra-flat-icon
- 安装好之后，打开Ubuntu Tweak 工具，主题选择Flatabulous，icons主题选择ultra-flat-icons

#### ZSH_OHMYZSH
- sudo apt-get install zsh
- wget --no-check-certificate https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | sh
- chsh -s /bin/zsh
- sudo reboot


#### node.js
- curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
- sudo apt-get install -y nodejs

---
#### 双击软件都无法打开
- sudo rm /home/sophie/.gnome2 -rf