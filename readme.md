# DMSwitcher

code：存放实验代码，包括log处理，更新workload之后的eval文件

document：配置并行远内存系统的文件和部分学习笔记

log：实验结果的log

res：处理过后的数据，包含部分实验图

## 实验进度

### 1. workload进度

其中部分workload可以参考[CFM](https://github.com/clusterfarmem/cfm)进行配置，具体配置后续会单独补上

| type           | name            | state |                                            |
|:--------------:|:---------------:|:-----:| ------------------------------------------ |
| C/C++          | quicksort       | √     |                                            |
|                | linpack         | √     |                                            |
|                | stream          | √     |                                            |
| Spark          | PageRank        | √     |                                            |
| GridGraph      | PreProcess      | √     |                                            |
|                | BFS             | √     |                                            |
| Ligra          | BFS             | √     |                                            |
|                | BC              | √     |                                            |
|                | CF              | √     |                                            |
|                | PageRank        | √     |                                            |
| Python         | kmeans          | √     | local memory较小时程序崩溃                        |
| tensorflow     | inception       | √     |                                            |
|                | resnet          | √     |                                            |
| File operation | file read/write |       | 未设置单独程序（没必要），GridGraph中PreProcess代替了读写性能测量 |
| PostgreSQL     | TPCH            |       |                                            |
|                | TPCDS           |       |                                            |
|                | TPCC            |       |                                            |
|                | Sysbench        |       |                                            |

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

### 3. 一些常见的指令

#### 脚本运行

程序运行脚本test.sh，用于运行一轮程序，在里面配置好直接运行即可，注意关掉ssh连接的session之后程序会断掉，所以采用以下指令：

```shell
nohup source test.sh >> logs/xxx.log &
```

### transparent huge page相关

```shell
# 查看是否打开THP
cat /sys/kernel/mm/transparent_hugepage/enabled
# 修改THP状态
sudo sh -c "echo always > /sys/kernel/mm/transparent_hugepage/enabled"
```

#### 修改CPU个数

直接在virt-manager中修改

```shell
# 查看CPU个数
cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l
```

#### 激活RDMA VF网卡并设置IP

每次重启系统，并且需要使用RDMA backend的时候需要设置RDMA VF网卡对应的IP

```shell
sudo ifconfig ens9 20.20.20.143 up
```

#### Fastswap安装

```shell
# driver安装-dram backend
sudo insmod fastswap_dram.ko
sudo insmod fastswap.ko

# driver安装-rdma backend
# 首先在server端运行fastswap服务，参数50000表示开启端口，8表示通信channel个数（和client端CPU数对应）
nohup ./fastswap/farmemserver/rmserver 50000 8 &

# 然后再client端安装fastswap kernel
sudo insmod fastswap_rdma.ko sport=50000 sip="20.20.20.110" cip="20.20.20.143" nq=8
sudo insmod fastswap.ko


# ssd backend直接使用4.11.0-genertic版本的内核，不需要额外操作
```

#### 清除系统page buffer/cache的缓存

```shell
sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
```
