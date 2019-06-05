---
title: Docker-Compose详解
categories:
  - 工具
  - Docker
tags:
  - Docker
comments: true
toc: true
abbrlink: 26a6dcd3
date: 2019-06-05 14:23:51
---

Compose中有两个重要的概念：
-   服务(service)：一个应用的容器，实际上可以包括若干个运行相同镜像的容器实例。
-   项目(project)：由一组关联的应用容器组成的一个完整的业务单元，在docker-compose.yml文件中定义。


# 安装和卸载
```
pip install -U docker-compose

二进制包安装方法
curl -L https://github.com/docker/compose/releases/download/1.23.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

官方安装方法
curl -L https://github.com/docker/compose/releases/download/1.23.0/run.sh > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

```

---

# 命令说明
```html
$ docker-compose
Define and run multi-container applications with Docker.

Usage:
  docker-compose [-f <arg>...] [options] [COMMAND] [ARGS...]
  docker-compose -h|--help

Options:
  -f, --file FILE             Specify an alternate compose file (default: docker-compose.yml)
  -p, --project-name NAME     Specify an alternate project name (default: directory name)
  --verbose                   Show more output
  -v, --version               Print version and exit
  -H, --host HOST             Daemon socket to connect to

  --tls                       Use TLS; implied by --tlsverify
  --tlscacert CA_PATH         Trust certs signed only by this CA
  --tlscert CLIENT_CERT_PATH  Path to TLS certificate file
  --tlskey TLS_KEY_PATH       Path to TLS key file
  --tlsverify                 Use TLS and verify the remote
  --skip-hostname-check       Don't check the daemon's hostname against the name specified
                              in the client certificate (for example if your docker host
                              is an IP address)

Commands:
  build              Build or rebuild services
  bundle             Generate a Docker bundle from the Compose file
  config             Validate and view the compose file
  create             Create services
  down               Stop and remove containers, networks, images, and volumes
  events             Receive real time events from containers
  exec               Execute a command in a running container
  help               Get help on a command
  kill               Kill containers
  logs               View output from containers
  pause              Pause services
  port               Print the public port for a port binding
  ps                 List containers
  pull               Pulls service images
  push               Push service images
  restart            Restart services
  rm                 Remove stopped containers
  run                Run a one-off command
  scale              Set number of containers for a service
  start              Start services
  stop               Stop services
  unpause            Unpause services
  up                 Create and start containers
  version            Show the Docker-Compose version information


```

--- 

# docker-compose.yml参考
每个docker-compose.yml必须定义image或者build中的一个，其它的是可选的。

## image
指定镜像tag或者ID。示例：
```
image: redis
image: ubuntu:14.04
image: tutum/influxdb
image: example-registry.com:4000/postgresql
image: a4bc65fd
```
> 注意，在version 1里同时使用image和build是不允许的，version 2则可以，如果同时指定了两者，会将build出来的镜像打上名为image标签。

## build

用来指定一个包含Dockerfile文件的路径。一般是当前目录.。Fig将build并生成一个随机命名的镜像。

> 注意，在version 1里`bulid`仅支持值为字符串。version 2里支持对象格式。

```
build: ./dir

build:
  context: ./dir
  dockerfile: Dockerfile-alternate
  args:
    buildno: 1
```
`context`为路径，dockerfile为需要替换默认docker-compose的文件名，args为构建(build)过程中的环境变量，用于替换Dockerfile里定义的ARG参数，容器中不可用。示例：
Dockerfile:

```
ARG buildno
ARG password

RUN echo "Build number: $buildno"
RUN script-requiring-password.sh "$password"
```
docker-compose.yml:

```
build:
  context: .
  args:
    buildno: 1
    password: secret

build:
  context: .
  args:
    - buildno=1
    - password=secret
```

--- 
## command
用来覆盖缺省命令。示例：

```
command: bundle exec thin -p 3000
```
`command`也支持数组形式：

```
command: [bundle, exec, thin, -p, 3000]
```

--- 

## links
用于链接另一容器服务，如需要使用到另一容器的mysql服务。可以给出服务名和别名；也可以仅给出服务名，这样别名将和服务名相同。同docker run --link。示例：

```
links:
 - db
 - db:mysql
 - redis
 ```
使用了别名将自动会在容器的/etc/hosts文件里创建相应记录：

```
172.17.2.186  db
172.17.2.186  mysql
172.17.2.187  redis
```
所以我们在容器里就可以直接使用别名作为服务的主机名。

---

## ports
用于暴露端口。同docker run -p。示例：

```
ports:
 - "3000"
 - "8000:8000"
 - "49100:22"
 - "127.0.0.1:8001:8001"
 ```

---

## expose
expose提供container之间的端口访问，不会暴露给主机使用。同docker run --expose。

```
expose:
 - "3000"
 - "8000"
```

---

## volumes
挂载数据卷。同docker run -v。示例：

```
volumes:
 - /var/lib/mysql
 - cache/:/tmp/cache
 - ~/configs:/etc/configs/:ro
```

---

## volumes_from
挂载数据卷容器，挂载是容器。同docker run --volumes-from。示例：

```
volumes_from:
 - service_name
 - service_name:ro
 - container:container_name
 - container:container_name:rw
```
> container:container_name格式仅支持version 2。

---

## environment
添加环境变量。同docker run -e。可以是数组或者字典格式：

```
environment:
  RACK_ENV: development
  SESSION_SECRET:

environment:
  - RACK_ENV=development
  - SESSION_SECRET
```

---

## depends_on
用于指定服务依赖，一般是mysql、redis等。
指定了依赖，将会优先于服务创建并启动依赖。

> links也可以指定依赖。

---

## external_links
链接搭配docker-compose.yml文件或者Compose之外定义的服务，通常是提供共享或公共服务。格式与links相似：

```
external_links:
 - redis_1
 - project_db_1:mysql
 - project_db_1:postgresql
```
> 注意，external_links链接的服务与当前服务必须是同一个网络环境。

--- 

## extra_hosts
添加主机名映射。

```
extra_hosts:
 - "somehost:162.242.195.82"
 - "otherhost:50.31.209.229"
```
将会在/etc/hosts创建记录：

```
162.242.195.82  somehost
50.31.209.229   otherhost
```
--- 

## extends
继承自当前yml文件或者其它文件中定义的服务，可以选择性的覆盖原有配置。

```
extends:
  file: common.yml
  service: webapp
```
> service必须有，file可选。service是需要继承的服务，例如web、database。

---

## net
设置网络模式。同docker的--net参数。

```
net: "bridge"
net: "none"
net: "container:[name or id]"
net: "host"
```

---

## dns
自定义dns服务器。

```
dns: 8.8.8.8
dns:
  - 8.8.8.8
  - 9.9.9.9
```

---

## 其他
```
cpu_shares, 
cpu_quota,
cpuset, 
domainname,
hostname, ipc, mac_address, mem_limit, 
memswap_limit, privileged, read_only, restart, shm_size, 
stdin_open, tty, user, working_dir
```
这些命令都是单个值，含义请参考docker run
```
cpu_shares: 73
cpu_quota: 50000
cpuset: 0,1

user: postgresql
working_dir: /code

domainname: foo.com
hostname: foo
ipc: host
mac_address: 02:42:ac:11:65:43

mem_limit: 1000000000
mem_limit: 128M
memswap_limit: 2000000000
privileged: true

restart: always

read_only: true
shm_size: 64M
stdin_open: true
tty: true
```

