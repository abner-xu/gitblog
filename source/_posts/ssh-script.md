---
title: ssh-script《ssh连接脚本》
categories:
  - 工具
  - shell
comments: true
toc: true
date: 2019-05-28 22:15:11
---
# main.sh
```shell
#!/bin/bash


direc=`dirname $0`
function color(){
    blue="\033[0;36m"
    red="\033[0;31m"
    green="\033[0;32m"
    close="\033[m"
    case $1 in
        blue)
            echo -e "$blue $2 $close"
        ;;
        red)AA
            echo -e "$red $2 $close"
        ;;
        green)
            echo -e "$green $2 $close"
        ;;
        *)
            echo "Input color error!!"
        ;;
    esac
}

function copyright(){
    echo "#####################"
    color blue "   SSH Login Platform   "
    echo "#####################"
    echo
}

function underline(){
    echo "-----------------------------------------"
}

function main(){

while [ True ];do


    echo "序号 |       主机      | 说明"
    underline
    awk 'BEGIN {FS=":"} {printf("\033[0;31m% 3s \033[m | %15s | %s\n",$1,$2,$6)}' $direc/config.lst
    underline
    read -p '[*] 选择主机: ' number
    pw="$direc/config.lst"
    ipaddr=$(awk -v num=$number 'BEGIN {FS=":"} {if($1 == num) {print $2}}' $pw)
    port=$(awk -v num=$number 'BEGIN {FS=":"} {if($1 == num) {print $3}}' $pw)
    username=$(awk -v num=$number 'BEGIN {FS=":"} {if($1 == num) {print $4}}' $pw)
    passwd=$(awk -v num=$number 'BEGIN {FS=":"} {if($1 == num) {print $5}}' $pw)

    case $number in
        [0-9]|[0-9][0-9]|[0-9][0-9][0-9])
            echo $passwd | grep -q ".pem$"
            RETURN=$?
            if [[ $RETURN == 0 ]];then
                ssh -i $direc/keys/$passwd $username@$ipaddr -p $port
                echo "ssh -i $direc/$passwd $username@$ipaddr -p $port"
            else
                expect -f $direc/login.exp $ipaddr $username $passwd $port
            fi
        ;;
        "q"|"quit")
            exit
        ;;

        *)
            echo "Input error!!"
        ;;
    esac
done
}

copyright
main
```

# login.exp
```shell
#!/usr/bin/expect -f
set TARGET [lindex $argv 0]
set USER [lindex $argv 1]
set PASSWD [lindex $argv 2]
set PORT [lindex $argv 3]
set timeout 10

spawn ssh $USER@$TARGET -p $PORT
expect {
    "*yes/no" {send "yes\r"; exp_continue}
    "*password:" {send "$PASSWD\r"}
}
interact
```

# config.lst
```shell
{1序号}:{2服务器ip}:{3端口号}:{4用户名}:{5密码}：{6标签}
1:ip_address:port:username:password:tag_name
```