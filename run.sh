#!/bin/bash
echo "请输入参数:"
echo "The #1 param is clean&start up"
echo "The #2 param is clean&deploy git"
read -t 30 -p "please input NO:" no
option=$no
case $option in
1) echo "start up" && hexo clean && hexo g && hexo s ;;
2) echo "deploy git" && hexo clean && hexo g && hexo d ;;
esac


