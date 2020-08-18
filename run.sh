#!/bin/bash
echo "请输入参数:"
echo "The #1 param is >> init object"
echo "The #2 param is >> clean&start up"
echo "The #3 param is >> clean&deploy git"
read -t 30 -p "please input NO:" no
option=$no
case $option in

1) echo "init object" && npm install && npm i hexo-renderer-ejs hexo-renderer-less && npm i --save hexo-deployer-git && npm i hexo-abbrlink --save && npm i hexo-generator-sitemap --save && npm i hexo-generator-baidu-sitemap --save ;;

2) echo "start up" && hexo clean && hexo g && hexo s ;;

3) echo "deploy git" && hexo clean && hexo g && hexo d ;;
esac


