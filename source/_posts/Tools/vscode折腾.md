---
title: vscode折腾
comments: true
toc: true
categories:
  - 工具
  - vscode
tags:
  - Docker
abbrlink: 6d2400f6
date: 2017-12-25 21:49:58
---
# 基本设置
0.使用快捷键组合【Ctrl+Shift+p】，在搜索框中输入“configure display language”，选择`install` 安装简体中文
1. Auto Close Tag ，自动添加 HTML/XML 的闭合标签，像 Visual Studio IDE 或 Sublime Text 一样。
2. Beautify，在 Visual Studio Code 中格式化 javascript 、JSON 、 CSS 、Sass，以及 HTML。
3. GitLens 可以增强 VSCode 内置 Git 的功能。例如 commits 搜索，历史记录和显示的代码作者身份具体功能可以查看Feature list
4. Git History  - 显示提交历史记录的美丽图表等等 

# PHP环境
1.  php intelephense，PHP 的代码提示、补全、跳转定义、格式化插件，功能强大，无需配置；优秀，必装。 `setting.json` 添加如下配置
```
"php.suggest.basic": false, //禁用基本建议
    "editor.quickSuggestions": {  //在评论/注释中启用自动完成功能
        "comments": true 
    },
```
2.  PHP DocBlocker，注释插件
3.  PHP Snippets from PHPStrom,使用和 PHPStrom 一样的快捷代码片段，pubf + tab？
4.  PHP Namespace Resolver,PHP 命名空间解析器；可以导入和扩展类；还可以排序。优秀，必装。
5.  Better Align,可以实现变量和数组的等号对齐。优秀，必装。
6.  PHP Getters & Setters，目前没使用。
7.  PHP CS Fixer，代码格式化工具。
8.  php.validate.executablepath,配置成docker 容器中的php路径，办法
    1. 新建文件 Create a file named php in `你自己的路径`
    2. 写入内容`#!/bin/bash docker exec -i --user=1000:1000 php7-vscode php "$@"`
    3. 修改可执行`sudo chmod +x php`
    4. php.validate.executablepath=`你自己的路径`/php



# go环境
1. 设置代理  set GOPROXY="https://goproxy.cn"
2. vscode添加go插件
3. 安装go-tools，command+shift+p，输入 go:install 选择 install/update tools
4. 设置常用代码片段，command+shift+p，选择go语言
```json
    "print":{
            "prefix": "pln",
            "body": "fmt.Println($0)"
        }
```
4. 用Delve调试Go项目 
    1.  go get -u go-delve/delve/delve
    2.  launch.json 
    ```json
    "configurations": [
            {
                "name": "Golang",
                "type": "go",
                "request": "launch",
                "remotePath": "",
                "port": 5546,
                "host": "127.0.0.1",
                "program": "${fileDirname}",
                "env": {
                    "GOPATH":"/User/abner/go",
                    "GOROOT":"/usr/local/go",
                },
                "args": []
            }
        ]
    ```
    