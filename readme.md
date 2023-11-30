# DMSwitcher

code：Experiment code, include the workload code and log process code. 

document：Include documents about how to confige our system.

## workload support

### workload list

| type           | name            | state |                                                     |
|:--------------:|:---------------:|:-----:| --------------------------------------------------- |
| C/C++          | quicksort       | √     |                                                     |
|                | linpack         | √     |                                                     |
|                | stream          | √     |                                                     |
| Spark          | PageRank        | √     |                                                     |
| GridGraph      | PreProcess      | √     |                                                     |
|                | BFS             | √     |                                                     |
| Ligra          | BFS             | √     |                                                     |
|                | BC              | √     |                                                     |
|                | CF              | √     |                                                     |
|                | PageRank        | √     |                                                     |
| Python         | kmeans          | √     | when local mremory ratio is low, program will crash |
| tensorflow     | inception       | √     |                                                     |
|                | resnet          | √     |                                                     |
| File operation | file read/write | √     | PreProcess in GridGraph                             |
| PostgreSQL     | TPCH            | √     | Small memory usage with huge page cache             |
|                | TPCDS           | √     | Small memory usage with huge page cache             |
|                | TPCC            | √     | Small memory usage with huge page cache             |
|                | Sysbench        | √     | Small memory usage with huge page cache             |
| AI             | chatglm         | √     |                                                     |
|                | chatglm-int4    | √     |                                                     |
|                | clip            | √     |                                                     |
|                | text-classify   | √     |                                                     |
|                | bert-uncased    | √     |                                                     |

### workload configuration

Some workloads' configuration can refer to [CFM](https://github.com/clusterfarmem/cfm): quicksort, linpack, stream, pagerank, kmeans, inception, resnet

**GridGraph**: refer to [thu-pacman/GridGraph: Out-of-core graph processing on a single machine](https://github.com/thu-pacman/GridGraph)

**Ligra**: refer to [jshun/ligra: Ligra: A Lightweight Graph Processing Framework for Shared Memory](https://github.com/jshun/ligra)

**chatglm**:

model:refer to https://huggingface.co/THUDM/chatglm2-6b

**chatglm-int4**:

model:refer to https://huggingface.co/THUDM/chatglm2-6b-int4

**clip**:

model:refer to https://huggingface.co/openai/clip-vit-large-patch14

data:refer to https://www.cs.toronto.edu/~kriz/cifar.html

**text-classofy**:

model:refer to https://github.com/gaussic/text-classification-cnn-rnn

data:refer to http://thuctc.thunlp.org/ 

**bet-uncased**:

model:refer to https://huggingface.co/bert-base-uncased

## System configuration

### Set up basic configuration

1. Install qemu-kvm

2. Configure rdma in kvm virtual machine, refer to document [kvm-rdma configuration](document/kvm-rdma configuration.md)

3. Configure fastswap in kvm virtual maching, refer to document kvm VM [fastswap configuration](document/kvm VM fastswap configuration.md)

4. Basic configuration of our system has been set up, and you can begin to evaluate different workloads with different system configuration.

### System parameters modification

#### a. Backend

**Rdma backend**: 

```shell
# driver installation-dram backend
cd fastswap/drivers/
make BACKEND=RDMA

# start fastswap service in far memory server，
# 50000: port number
# 8: #channels（the same as #CPUs in far memory client）
nohup ./fastswap/farmemserver/rmserver 50000 32 &

# instal fastswap module in far memory client
sudo insmod fastswap_rdma.ko sport=50000 sip="20.20.20.110" cip="20.20.20.94" nq=32
sudo insmod fastswap.ko


```

**Dram backend**: 

```shell
# driver installation-dram backend
cd fastswap/drivers/
make BACKEND=DRAM
sudo insmod fastswap_dram.ko
sudo insmod fastswap.ko
```

**SSD backend**: Use linux defaut swap system and swapfile should be mounted at SSD.

#### b. THP (Transparent Huge Page) on/off

```shell
# check THP status
cat /sys/kernel/mm/transparent_hugepage/enabled
# modify THP status
sudo sh -c "echo always > /sys/kernel/mm/transparent_hugepage/enabled"
sudo sh -c "echo never> /sys/kernel/mm/transparent_hugepage/enabled"
```

#### c. Number of CPUs

```shell
# modify VM configuration
sudo virsh edit CacheExp
# query the number of CPUs
cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l
```

#### d. VM operations

list running VMs

```shell
sudo virsh list
```

shutdown VM-CacheExp

```shell
sudo virsh shutdown CacheExp
```

force shudown VM-CacheExp

```shell
sudo virsh destory CacheExp
```

start VM-CacheExp

```shell
sudo virsh start CacheExp
```

edit VM-CacheExp's configurations

```shell
sudo virsh edit CacheExp
```

#### 脚本运行

workload的文件在物理机和虚拟机上都放在`~/aitest/cfm_new`文件夹下。

- tt.sh包含新的几个workload的运行代码，直接**在cfm_new工作路径下**运行` ./tt.sh`即可。
- python文件夹包含运行workload的python环境，text-classify使用work1环境，chatglm、chatglm-int4、clip、bert-uncased使用work2环境。
- 运行单个workload可以**在cfm_new工作路径下**使用` ./python/work2/bin/python benchmark.py xxx(workload_name)  xx(ratio)`指令。
- 挂在后台运行模型：**在cfm_new工作路径下**运行` nohup ./tt.sh >> logs/xxx.log &`指令。

- 程序运行脚本test.sh，用于运行一轮程序，在里面配置好直接运行即可，注意关掉ssh连接的session之后程序会断掉，所以采用以下指令：`nohup source test.sh >> logs/xxx.log &`。

#### 清除系统page buffer/cache的缓存

```shell
sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
```
