---
title: Centos7开机优化
categories:
  - 工具
  - Linux
tags:
  - Centos
comments: false
date: 2017-2-13 22:01:12
toc: true
---
## 1.替换源
```
yum install -y wget
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
```


## 2.安装增强
```shell
yum install -y gcc gcc-devel gcc-c++ gcc-c++-devel make kernel kernel-devel bzip2 vim wget  #需要的安装包
shutdown -r now  #重启电脑
ln -s /usr/src/kernels/3.10.0(内核版本号/ /usr/src/linux　   ## 增加软连接
#点击虚拟机设备->安装增强
mount /dev/cdrom /mnt  #挂载增强光盘到系统，提示只读不用管
cd /mnt &&  ./VBoxLinuxAdditions.run  
```
## 3.挂载
```shell
mkdir /root/www && chmod -R 777 /root/www
mount -t vboxsf docker /root/www   #手动挂载
### 此时如果提示/sbin/mount.vboxsf: mounting failed with the error: No such device，说明内核模块vboxsf未加载，可通过lsmod | grep vboxsf查看（无结果说明未加载）。
modprobe vboxsf #加载vboxsf模块
#自动挂载
/etc/fstab
docker /root/www   vboxsf rw,gid=100,uid=1000,auto /0 0
```

## 4.修改主机名
```shell
vim /etc/sysconfig/network
vim ~/.bash_profile
export PS1='[\u@\H \W]$'
source ~/.bash_profile
```
## 5.永久关闭防火墙
```shell
chkconfig iptables off 关闭
chkconfig iptables on 开启
service iptables status
```
## 7.selinux关闭
```shell
修改/etc/selinux/config
将SELINUX=enforcing改为SELINUX=disabled,
状态 /usr/sbin/sestatus -v
```
## 8.SSH客户端超时
```shell
cd /etc/ssh
cp sshd_config sshd_config.bak
sed -i "s/#ClientAliveInterval 0/ClientAliveInterval 60/g" sshd_config
sed -i "s/#ClientAliveCountMax 3/ClientAliveCountMax 3/g" sshd_config
grep ClientAlive sshd_config
diff sshd_config sshd_config.bak
```
## 9.yum install 不可用情况
```shell
- rpm -q epel-release
- rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm  报错[--force --nodeps]
- rpm -q epel-release
- rpm -qR epel-release  
- rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
- yum install yum-priorities
- ls /etc/yum.repos.d/ | grep epel
```
## 10. FTP安装
    - 安装
    ```shell
    yum -y install vsftpd
    useradd ftpuser
    passwd ftpuser (RwxM7yCV)
    ```
    - 无法访问问题
     ```shell
    [root@bogon ~]## getsebool -a | grep ftp  
    allow_ftpd_anon_write --> off
    <!--这里无法访问-->
    allow_ftpd_full_access --> off
    allow_ftpd_use_cifs --> off
    allow_ftpd_use_nfs --> off
    <!--这里无法访问-->
    ftp_home_dir --> off
    ftpd_connect_db --> off
    ftpd_use_passive_mode --> off
    httpd_enable_ftp_server --> off
    tftp_anon_write --> off
    ```
    - 开启外网访问
    ```shell
    setsebool -P allow_ftpd_full_access on
    setsebool -P ftp_home_dir on
    ```
    - 关闭匿名和开启被动模式
    ```shell
    修改/etc/vsftpd/vsftpd.conf 中的改成 anonymous_enable=NO
    pasv_min_port=30000
    pasv_max_port=30999
    service vsftpd stop
    ```


## 11.mysql5.7安装
```
cd /usr/local/src/
wget http://repo.mysql.com/mysql57-community-release-el7-8.noarch.rpm 
rpm -ivh mysql57-community-release-el7-8.noarch.rpm 
yum -y install mysql-server 

#设置密码和远程访问
grep "password" /var/log/mysqld.log      //查看默认密码
set password=password("xxxx");
FLUSH PRIVILEGES;


use mysql;
set global validate_password_policy=0;
update user set authentication_string = password('xxxx'), password_expired = 'N', password_last_changed = now() where user = 'root';
GRANT ALL ON *.* TO root@'localhost'  IDENTIFIED BY 'xxxx' WITH GRANT OPTION; 
update user set host = '%' where user ='root';
FLUSH PRIVILEGES;
```
> 如果容器需要访问物理机ip，先查看容器的ip地址，直接配置host为物理机mysql,ip即可
