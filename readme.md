# xDM

code：Experiment code, including the workload code and log process code. 

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

### Workload configuration

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

2. Configure rdma in kvm virtual machine, refer to document `document/kvm-rdma configuration.md`

3. Configure fastswap in kvm virtual maching. As we have configured VF in VM, you can directly install FASTSWAP in VM. Just refer to [clusterfarmem/fastswap: Fastswap, a fast swap system for far memory through RDMA ](https://github.com/clusterfarmem/fastswap)

4. Basic configuration of our system has been set up, and you can begin to evaluate different workloads with different system configuration.

### System parameters modification

#### a. Backend

**Rdma backend**: 

**In far memory server**

```shell
git clone https://github.com/clusterfarmem/fastswap.git
cd farmemserver
make
# start fastswap service in far memory server，
# 50000: port number
# 8: #channels（the same as #CPUs in far memory client）
nohup ./fastswap/farmemserver/rmserver 50000 32 &
```

**In far memory client**

```shell
# driver installation-dram backend
git clone https://github.com/clusterfarmem/fastswap.git
cd fastswap/drivers/
make BACKEND=RDMA

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

#### e. Other operations

clear system page buffer/cache

```shell
sync
sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
```

### Evaluate workload

After setting up workload, using the following command to execute `chatglm `with 0.5 local memory ratio.

```shell
python3 benchmark chatglm 0.5
```
