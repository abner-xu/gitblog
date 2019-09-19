---
title: Docker搭建可一键部署的多域名LNMP环境
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
# Docker搭建可一键部署的多域名LNMP环境

#### 特点
1. 完全开源
1. 支持多版本PHP切换（PHP5.4、PHP5.6、PHP7.2...)
1. 支持绑定任意多个域名
1. 支持HTTPS和HTTP/2
1. PHP源代码位于host中
1. MySQL data位于host中
1. 所有配置文件可在host中直接修改
1. 所有日志文件可在host中直接查看
1. 内置完整PHP扩展安装命令
1. 实际使用，确保100%可行
1. 实现一次配置，可在任何支持Docker系统使用

---

#### 1.安装步骤


##### 1.1 docker(https://docs.docker.com/engine/installation/)
1.  Centos7安装
    ```shell
    sudo yum install -y yum-utils device-mapper-persistent-data lvm2
    sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    sudo yum makecache fast
    sudo yum -y install docker-ce
    sudo service docker start
    ```
2.  Ubuntu安装
    ```shell
    sudo apt-get update
    sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get -y update
    sudo apt-get -y install docker-ce
    ```
##### 1.2 docker-compose(https://docs.docker.com/compose/install/)
    ```shell
    sudo curl -L https://get.daocloud.io/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    ```
##### 1.3查看版本，加入到docker组
```shell
$ docker -v
$ docker-compose -v
$ sudo gpasswd -a ${USER} docker     
```
就不用每次启动Docker都得加sudo了，注意，执行gpasswd命令之后要重新登陆才有效。

##### 1.4 使用国内镜像仓库
1. 首先注册一个阿里云账号，然后访问阿里云的[Docker镜像仓库](https://cr.console.aliyun.com/)，能找到加速器地址。
2. 对于Docker 1.10+，打开配置文件 /etc/docker/daemon.json（没有时新建该文件）：
```shell
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://l714mp7z.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker

#开机启动centos7
systemctl enable docker
```
Docker 1.10以下请看：https://yq.aliyun.com/articles/29941。

##### 1.5 安装容器和镜像
```shell
docker-compose up -d
```

##### 1.6 如果是windows下基于virtualbox挂载目录到linux
1.  安装增强工具(centos7版本)
![增强工具](http://ww1.sinaimg.cn/large/aaba1596gy1g74n03vgqfj20ma08hdg3.jpg)
```json
yum install -y gcc gcc-devel gcc-c++ gcc-c++-devel make kernel kernel-devel bzip2 vim wget  
sudo reboot  #重启
ln -s /usr/src/kernels/3.10.0（注意内核版本号自动补全） /usr/src/linux　   ## 增加软连接
#点击虚拟机设备->安装增强
mount /dev/cdrom /mnt  #挂载增强光盘到系统，提示只读不用管
cd /mnt &&  ./VBoxLinuxAdditions.run
```



2. 配置共享目录  
![image](http://ww3.sinaimg.cn/large/0060lm7Tly1fnjv29wde7j309a06sa9y.jpg)
3. 手动挂载
3.1 ubuntu
```
sudo mkdir /home/abner/server  && chmod -R 777 /home/abner/server 
sudo mount -t vboxsf docker /home/abner/server   #手动挂载 （这里挂载的目录最好不要和共享文件夹名称一样）
```
3.2 centos7
```
sudo mkdir /root/server  && chmod -R 777 /root/server 
sudo mount -t vboxsf docker /root/server
```

4. 开机自动挂载
4.1 ubuntu
```shell
sudo vim /etc/rc.local
##exit 0 前增加如下命令
sleep 1
sudo mount -t vboxsf docker /home/abner/server
```

4.2 centos7
==[virbox自动挂载不能勾选]==
```shell
mkdir /home/abner/server && chmod -R 777 /home/abner/server
mount -t vboxsf docker /home/abner/server   #手动挂载
## 此时如果提示/sbin/mount.vboxsf: mounting failed with the error: No such device，说明内核模块vboxsf未加载，可通过lsmod | grep vboxsf查看（无结果说明未加载）。
modprobe vboxsf #加载vboxsf模块
#自动挂载
sudo vim /etc/fstab
docker /home/abner/server   vboxsf rw,gid=100,uid=1000,auto 0 0
```

5.若走的端口转发按图如下配置  
![image](http://ww4.sinaimg.cn/large/0060lm7Tly1fnm8mdsa3wj30i8079wej.jpg)
6. 若走的桥接网卡，正常连接即可
---


--- 
# 以下部分属于知识扩展

#### 2.目录说明
#### 2.1 大致框架
![image](http://ww4.sinaimg.cn/large/0060lm7Tly1fnigj751vsj30ku0au74g.jpg)
#### 2.2 目录结构
```doc
├── docker-compose.yml          容器启动配置文件
├── Dockerfile                  PHP-FPM构建配置文件
├── conf                        配置目录
│   ├── mysql                   MySQL配置文件目录
│   │   └── my.cnf              MySQL配置文件
│   ├── nginx                   Nginx配置文件目录
│   │   ├── conf.d              站点配置文件目录
│   │   │   ├── certs           SSL认证文件、密钥和加密文件目录
│   │   │   │   └── site2       站点2的认证文件目录
│   │   │   ├── site1.conf      站点1 Nginx配置文件
│   │   │   └── site2.conf      站点2 Nginx配置文件
│   │   └── nginx.conf          Nginx通用配置文件
│   └── php                     PHP配置目录
│       ├── php-fpm.d           PHP-FPM配置目录
│       │   └── www.conf        PHP-FPM配置文件
│       └── php.ini             PHP配置文件
├── log                         日志目录
│   ├── mysql                   MySQL日志目录
│   ├── nginx                   Nginx日志目录
│   └── php-fpm                 PHP-FPM日志目录
├── mysql                       MySQL数据文件目录
└── www                         站点根目录
    ├── site1                   站点1根目录
    └── site2                   站点2根目录
```

#### 2.2.1 nginx配置
```config
server {
    listen  80;
    server_name www.site1.com;
    root /var/www/html/site1;
    index index.shtml index.php index.html;
    location ~* \.(css|js)$ {
        sendfile  off;
        break;
    }
    expires off;
    client_max_body_size 2M;
    client_body_temp_path /var/www/html;

    location / {
            index index.shtml index.php index.html;
            if (!-e $request_filename){
                 rewrite ^/(.+)$ /index.php?_url=/$1 last;
            }
    }

    location ~ ^/.+\.php(/|$) {
        fastcgi_pass [容器的ip或者名称]:9000;  
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_read_timeout 600; 
    }
}

```

#### 2.3 站点部署
本文有默认加了两个站点：www.site1.com（同localhost）和www.site2.com。  
要在本地访问这两个域名，需要修改你的hosts文件，添加以下两行：  
127.0.0.1 www.site1.com  
127.0.0.1 www.site2.com  
其中，www.site2.com为支持SSL/https和HTTP/2的示例站点。  
因为站点2的SSL采用自签名方式，所以浏览器有安全提示，继续访问就可以了，自己的站点用第三方SSL认证证书替换即可。  
如果只用到站点1，把站点2相关的目录和配置文件删除：  
./conf/nginx/conf.d/certs/site2/  
./conf/nginx/conf.d/site2.conf  
./www/site2/  
重启容器内的Nginx生效：  
docker exec -it dlnmp_nginx_1 nginx -s reload
#### 2.4 HTTPS使用
./conf/nginx/conf.d/site2.conf  
如果是自签名，可以用廖雪峰提供的一个自动生成认证文件、私钥脚本：gencert.sh，
这个脚本已经放在项目中，在这个目录下：  
./conf/nginx/conf.d/certs/site2/  
在Bash中输入：  
$ ./gencert.sh  
输入一次域名，和几次密码（内容随意）后，就会生成几个认证文件。  
其中自签名情况不需要.csr和.origin.key后缀的文件。  
然后修改Nginx配置文件，配置SSL支持就可以了。 
#### 2.5 docker-compose.yml文件
如下是docker容器的运行配置docker-compose.yml的内容：
```yml
nginx:
  image: nginx:alpine
  ports:
    - "80:80"
    - "443:443"
  volumes:
    - ./www/:/var/www/html/:rw
    - ./conf/nginx/conf.d:/etc/nginx/conf.d/:ro
    - ./conf/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    - ./log/nginx/:/var/log/nginx/:rw
  links:
    - php-fpm:fpm

php-fpm:
  build: .
  expose:
    - "9000"
  volumes:
    - ./www/:/var/www/html/:rw
    - ./conf/php/php.ini:/usr/local/etc/php/php.ini:ro
    - ./conf/php/php-fpm.d/www.conf:/usr/local/etc/php-fpm.d/www.conf:rw
    - ./log/php-fpm/:/var/log/php-fpm/:rw
  links:
    - mysql:mysql
    - redis:redis

mysql:
  image: mysql:latest
  ports:
    - "3306:3306"
  volumes:
    - ./conf/mysql/my.cnf:/etc/mysql/my.cnf:ro
    - ./mysql/:/var/lib/mysql/:rw
    - ./log/mysql/:/var/log/mysql/:rw
  environment:
    MYSQL_ROOT_PASSWORD: "123456"

redis:
  image: redis:latest
  ports:
    - "6379:6379"
```

#### 2.6 站点根目录写权限
默认的，容器中的/var/www/html目录属于root，我们需要修改为www-data，PHP才能正常写目录。  
先进入到容器中：  
$ docker exec -it dlnmp_php-fpm_1 /bin/bash  
然后修改目录权限：  
$ chown -R www-data:www-data /var/www/html

#### 2.7 MYSQL连接
1.  $ mysql -h 127.0.0.1 -u root -p 
    -  说明：这里MySQL的连接主机不能用localhost，因为MySQL客户端默认使用unix socket方式连接，应该直接用本地IP。
2.  $pdo = new PDO('mysql:host=mysql;dbname=site1', 'root', '123456');
    -   说明：，host的值就是在指定的MySQL容器的名称。 redis,memcaced等类似


#### 常用操作
批量删除容器
```
docker rm $(docker ps -a -q)
```
批量删除镜像
```
docker rmi $(docker images -q)
```
删除挂载目录 
```
docker volume rm $(docker volume ls -qf dangling=true)
```
删除所有关闭的容器
```
docker ps -a | grep Exit | cut -d ' ' -f 1 | xargs docker rm
```
删除所有dangling镜像（即无tag的镜像）
```
docker rmi $(docker images | grep "^<none>" | awk "{print $3}")
```
查看所有容器IP
```
docker inspect --format='{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aq)    

shell别名用法
alias docker-ips='docker inspect --format='"'"'{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'"'"' $(docker ps -aq)'
```