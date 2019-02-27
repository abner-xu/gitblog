---
title: githubPages+hexo搭建个人博客
categories:
  - 前端
  - Hexo
tags:
  - Hexo
comments: true
toc: true
date: 2017-01-25 22:07:58
---

# githubPages+hexo搭建个人博客
0. 安装git和nodejs	
1. npm安装慢
```
sudo npm config set registry http://registry.npm.taobao.org
npm install -g cnpm --registry=https://registry.npm.taobao.org
```
2. Permission denied
```
sudo chown -R $(whoami):admin /usr/local/lib/node_modules/
```
3. 由于npm安装失败，使用cnpm
```
cnpm install -g hexo-cli
```
4. ~work/nodepro/ 新建日志博客,并给项目起名称
```
hexo init abner-xu.github.io
```
5. 进入目录安装依赖
```
cnpm install #安装依赖
hexo generate #形成部署文件
hexo server 启动服务
```
6. 编辑_config.yml 修改deploy
```
deploy:
  type: git
  repository: git@github.com:abner-xu/abner-xu.github.io.git
  branch: master
```
7. 部署到gitpage上
首先配置github ssh信息
```
  cnpm install hexo-deployer-git –save
  hexo clean hexo generator #格式化文件
  hexo d #部署到git
```

# hexo关键配置
```
# Site 
title: Dududzai’s Blog 
#网站的标题 subtitle: life is struggle 
#副标题 description: life is struggle 
#描述 author: examble 
#作者信息 avatar: /images/avatar.png #头像，图片位置在相应主题目录下的images 
language: zh-Hans #中文简体 
email: 85268837@qq.com 
timezone:  
# Extensions 
theme: next #配置主题，这里使用next主题 stylus:   
compress: true #自适应布局  
# Deployment 
deploy:   
type: git #部署环境，基于hexo+githubpage,所以这里使用git。注意：不同版本的hexo，type有可能不同，3.x以后应使用git,具体参看官方文档   
repository: git@github.com:username/username.github.io.git #git仓库地址，替换成你的username即可，其他保持不变，后面会提到如何创建git仓库   
branch: master
```
## 添加关于页面
使用：hexo new page "about" 新建一个 关于我 页面。 
主题的 _config.yml 文件中的 menu 中进行匹配
```
menu:
  home: /      //主页
  categories: /categories //分类
  archives: /archives   //归档
  tags: /tags   //标签
  about: /about   //关于                  （添加此行即可
```
## 添加标签页面
使用： hexo new page tags 新建一个 标签 页面。 
```
title: tags
date: 2017-12-02 21:01:24
type: "tags"
```
主题的 _config.yml 文件中的 menu 中进行匹配
```
menu:
  home: /      //主页
  categories: /categories //分类
  archives: /archives   //归档
  tags: /tags   //标签
  about: /about   //关于                  （添加此行即可
```
## 添加分类页面
使用： hexo new page categories 新建一个 分类 页面。 
```
title: categories
date: 2017-12-02 21:01:24
type: "categories"
```
主题的 _config.yml 文件中的 menu 中进行匹配
```
menu:
  home: /      //主页
  categories: /categories //分类
  archives: /archives   //归档
  tags: /tags   //标签
  about: /about   //关于                  （添加此行即可
```
底下代码是一篇包含 分类 文章的例子：
```
title: 分类测试
categories:
- hexo                       （这个就是文章的分类了）
---
```
## 添加归档页面 或者自定义页面
主题的 _config.yml 文件中的 menu 中进行匹配

使用： hexo new page "guestbook" 新建一个 自定义 页面。 
主题的 _config.yml 文件中的 menu 中进行匹配
```
menu:
  home: /      //主页
  categories: /categories //分类        
  archives: /archives   //归档   
  tags: /tags   //标签                  
  about: /about   //关于
  guestbook: /guestbook    //自定义             （添加此行即可）
```
## 添加文章
```
hexo new "文章名称"
```
---
title: CentOS7下Tomcat启动慢的原因及解决方案
date: 2017-12-02 21:01:24
comments: true #是否可评论
toc: true #是否显示文章目录
categories: "云服务器" #分类
tags:   #标签
	- centOS
	- tomcat
---

