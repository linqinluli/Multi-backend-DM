# DMSwitcher

code：存放实验代码，包括log处理，更新workload之后的eval文件

document：配置并行远内存系统的文件和部分学习笔记

log：实验结果的log

res：处理过后的数据，包含部分实验图

## 实验进度

### 1. workload进度

其中部分workload可以参考[CFM](https://github.com/clusterfarmem/cfm)进行配置，具体配置后续会单独补上

| type           | name            | state |
|:--------------:|:---------------:|:-----:|
| C++            | quicksort       | √     |
|                | linpack         | √     |
| Spark          | PageRank        | √     |
| GridGraph      | PreProcess      | √     |
|                | BFS             | √     |
| Python         | kmeans          | √     |
| tensorflow     | inception       | √     |
|                | resnet          | √     |
| File operation | file read/write |       |
| PostgreSQL     | TPCH            |       |
|                | TPCDS           |       |
|                | TPCC            |       |
|                | Sysbench        |       |

### 2. 实验数据

实验原始log存储在log文件夹中，处理之后的结果数据存储在[res](/res/res.xlsx)中。

## 实验环境

### 1. 虚拟机分配

由于该项目目前需要分配给多个人同时进行，将任务和虚拟机分配如下(虚拟机运行在实验室服务器SAIL-N2上)：

| 任务描述           | 虚拟机名字       | 负责人  | IP              | 账号           | 密码           |
|:--------------:|:-----------:|:----:|:---------------:|:------------:|:------------:|
| 主要实验           | cgroup2test | 杨涵章  | 192.168.122.143 | yanghanzhang | yanghanzhang |
| Fastswap配置探索   | FastswapExp | 王菎运  | 192.168.122.9   | yanghanzhang | yanghanzhang |
| PostgreSQL配置探索 | PostgreSQL  | 颛孙一鸣 | 192.168.122.94  | yanghanzhang | yanghanzhang |

### 2. 如何开始实验？

a. 首先通过ssh连接n2服务器，虚拟机的管理通过virt-manager完成，有关服务运行在linqinluli这个用户的账号上，有需要找杨涵章要账号密码或者让他帮忙完成；

b. 然后通过ssh连接对应虚拟机；

c. 主要和workload有关的实验在cfm文件夹中，可以参考[CFM](https://github.com/clusterfarmem/cfm)进行运行，目前在cgroup2test文件完成了除PostgreSQL以外所有workload的配置

d. 运行试验记得使用linux中的">> /log/xxx.log"命令将结果存储到log文件中，之后使用code中的log处理文件进行处理
