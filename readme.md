# xDM

code：Experiment code, including the workload code and log process code. 

document：Include documents about how to confige our system.

scripts：backend switch scripts

## 1. Multi-backend System configuration

### a. Requirements

1）xDM rdma server：a server with at lease 64G memory, a MT27800 Family [ConnectX-5] NIC(recommend), MLNX_OFED_LINUX-5.8-4.1.5.0 installed (available at [Linux InfiniBand Drivers (nvidia.com)](https://network.nvidia.com/products/infiniband-drivers/linux/mlnx_ofed/), should match the linux distribution and rdma NIC version.), 

2）xDM client：a server with at lease 64G memory, a MT27800 Family [ConnectX-5] NIC(recommend), MLNX_OFED_LINUX-5.8-4.1.5.0 installed (available at [Linux InfiniBand Drivers (nvidia.com)](https://network.nvidia.com/products/infiniband-drivers/linux/mlnx_ofed/), should match the linux distribution and rdma NIC version.), qemu-kvm installed

### b. Install xDM in xDM client

#### 1) Compiling and installing fastswap kernel (vm in xDM client node) , only DRAM and RDMA kernel need this step

git clone the repo

```shell
cd ~
git clone https://github.com/linqinluli/Multi-backend-DM.git
```

First you need a copy of the source for kernel 4.11 with SHA a351e9b9fc24e982ec2f0e76379a49826036da12. We outline the high level steps here.

```shell
cd ~
wget https://github.com/torvalds/linux/archive/a351e9b9fc24e982ec2f0e76379a49826036da12.zip
mv a351e9b9fc24e982ec2f0e76379a49826036da12.zip linux-4.11.zip
unzip linux-4.11.zip
cd linux-4.11
git init .
git add .
git commit -m "first commit"
```

Now use the provided patch and apply it against your copy of linux-4.11, and use the generic Ubuntu config file for kernel 4.11. You can get the config file from internet, or you can use the one we provide.

```shell
git apply ~/Multi-backend-DM/code/kernel/kernel.patch
cp ~/fastswap/kernel/config-4.11.0-041100-generic ~/linux-4.11/.config
```

Make sure you have necessary prerequisites to compile the kernel, and compile it:

```shell
sudo apt-get install git build-essential kernel-package fakeroot libncurses5-dev libssl-dev ccache bison flex
make -j `getconf _NPROCESSORS_ONLN` deb-pkg LOCALVERSION=-fastswap
```

Once it's done, your deb packages should be one directory above, you can simply install them all:

```shell
cd ..
sudo dpkg -i *.deb
```

#### 2) Configure rdma in kvm virtual machine

    Refer to document [configure rdma in kvm VM](document/KVM_RDMA_Configuration.md), in this step, make sure the ofed driver you installed in VM is 4.3 version. The official version 4.3 driver is no longer available, we provide a Google Cloud Drive download [link](https://drive.google.com/file/d/1-kEu_ks2syC62Fg1YYLBFcR3ugT_h3ZD/view?usp=drive_linkhttps://drive.google.com/file/d/1-kEu_ks2syC62Fg1YYLBFcR3ugT_h3ZD/view?usp=drive_link).

#### 3) Compile backend drivers

**DRAM backend:**

in vm will use DRAM backend in xDM client

```shell
cd ~/Multi-backend-DM/code/drivers
make BACKEND=DRAM
```

**RDMA backend:**

in vm will use RDMA backend in xDM client

```shell
cd ~/Multi-backend-DM/code/drivers
make BACKEND=RDMA
```

in xDM server

```shell
cd ~
git clone https://github.com/linqinluli/Multi-backend-DM.git
cd ~/Multi-backend-DM/code/farmemserver
make
```

### c. Backend configuration

xDM support 3 types swap backend SSD(disk), DRAM, RDMA. You can configure it after above steps. We offer script for configuration

**SSD(only support Linux simple kernel):**

```shell
cd ~/Multi-backend-DM/code/scripts/
sudo chmod +x backendswitch.sh
./backendswitch.sh ssd $swap_space_size $path_mount_on_ssd
```

**DRAM(only support modified Linux kernel)**

```shell
cd ~/Multi-backend-DM/code/scripts/
sudo chmod +x backendswitch.sh
./backendswitch.sh dram $swap_space_size
```

**RDMA(only support modified Linux kernel)**

To build and run the far memory server do(xDM RDMA server):

```shell
./rmserver $port $far_memory_size
```

Configure rdma backend in xDM client

```shell
cd ~/Multi-backend-DM/code/scripts/
sudo chmod +x backendswitch.sh

./backendswitch.sh rdma $rdma_server_ip $rdma_server_port $rdma_client_ip
```

## 2. System parameters modification

### a. Backend switch

Using `code/scripts/backendswitch.sh`, we strongly suggest to use SSD backend without modified kernel for it may cause the system crush. We will solve the problem in the next version.

Configure a new backend or switch to another backend can be finished to use the script. Just follow steps in **Backend configuration**.

### b. Swap Granularity( by turn on/off THP)

turn on THP

```shell
sudo sh -c "echo always > /sys/kernel/mm/transparent_hugepage/enabled"
```

turn off THP

```shell
sudo sh -c "echo never> /sys/kernel/mm/transparent_hugepage/enabled"
```

### c. Number of CPUs

The number of CPUs can be only configured by kvm. You should shut down the VM server and start it.

```shell
# modify VM configuration
sudo virsh edit CacheExp
# query the number of CPUs
cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l
```

Here are other vm opertions the may be used:

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

## 3. Evaluate workloads

Here are workloads we supported now.

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

### a. Workloads configuration

Some workloads' configuration can refer to [CFM](https://github.com/clusterfarmem/cfm): quicksort, linpack, stream, pagerank, kmeans, inception, resnet

**GridGraph**: refer to [thu-pacman/GridGraph: Out-of-core graph processing on a single machine](https://github.com/thu-pacman/GridGraph)

**Ligra**: refer to [jshun/ligra: Ligra: A Lightweight Graph Processing Framework for Shared Memory](https://github.com/jshun/ligra)

**chatglm**:

model:refer to [THUDM/chatglm2-6b · Hugging Face](https://huggingface.co/THUDM/chatglm2-6b)

**chatglm-int4**:

model:refer to [THUDM/chatglm2-6b-int4 · Hugging Face](https://huggingface.co/THUDM/chatglm2-6b-int4)

**clip**:

model:refer to [openai/clip-vit-large-patch14 · Hugging Face](https://huggingface.co/openai/clip-vit-large-patch14)

data:refer to [CIFAR-10 and CIFAR-100 datasets](https://www.cs.toronto.edu/~kriz/cifar.html)

**text-classofy**:

model:refer to [GitHub - gaussic/text-classification-cnn-rnn: CNN-RNN中文文本分类，基于TensorFlow](https://github.com/gaussic/text-classification-cnn-rnn)

data:refer to [http://thuctc.thunlp.org/](http://thuctc.thunlp.org/)

**bet-uncased**:

model:refer to https://huggingface.co/bert-base-uncasedSome workloads' configuration can refer to [CFM](https://github.com/clusterfarmem/cfm): quicksort, linpack, stream, pagerank, kmeans, inception, resnet

**GridGraph**: refer to [thu-pacman/GridGraph: Out-of-core graph processing on a single machine](https://github.com/thu-pacman/GridGraph)

**Ligra**: refer to [jshun/ligra: Ligra: A Lightweight Graph Processing Framework for Shared Memory](https://github.com/jshun/ligra)

**chatglm**:

model:refer to [THUDM/chatglm2-6b · Hugging Face](https://huggingface.co/THUDM/chatglm2-6b)

**chatglm-int4**:

model:refer to [THUDM/chatglm2-6b-int4 · Hugging Face](https://huggingface.co/THUDM/chatglm2-6b-int4)

**clip**:

model:refer to [openai/clip-vit-large-patch14 · Hugging Face](https://huggingface.co/openai/clip-vit-large-patch14)

data:refer to [CIFAR-10 and CIFAR-100 datasets](https://www.cs.toronto.edu/~kriz/cifar.html)

**text-classofy**:

model:refer to [GitHub - gaussic/text-classification-cnn-rnn: CNN-RNN中文文本分类，基于TensorFlow](https://github.com/gaussic/text-classification-cnn-rnn)

data:refer to [http://thuctc.thunlp.org/](http://thuctc.thunlp.org/)

**bet-uncased**:

model:refer to [google-bert/bert-base-uncased · Hugging Face](https://huggingface.co/bert-base-uncased)

### b. Evaluate a single workload

#### 1) Disable cgroup V1

It's different in different kernels and lsb versions. We show the steps we used in our system.

- Open /boot/grub/grub.cfg in your editor of choice
- Find the `menuentry` for the fastswap kernel
- Add `cgroup_no_v1=memory` to the end of the line beginning in `linux /boot/vmlinuz-4.11.0-sswap`
- Save and exit the file
- Run: sudo update-grub
- Reboot

#### 2) Mount cgroupV2

The framework and scripts rely on the cgroup system to be mounted at /cgroup2. Perform the following actions:

- Run `sudo mkdir /cgroup2` to create root mount point
- Execute `code/scripts/init_bench_cgroups.sh`

Here is a example of how to evaluate **chatglm** with 0.5 local memory ratio.

```shell
cd ~/Multi-backend-DM/code/eval
python3 benchmark chatglm 0.5
```

### c. Evaluate multi workloads

Make sure you have installed the workloads install in the `code\eval` path. Here is a script to quickly install workloads we provide in the repo.

```shell
chmod +x ~/Multi-backend-DM/scripts/install_workloads.sh
sh ~/Multi-backend-DM/scripts/install_workloads.sh
```

Then evaluate mutil workloads:

```shell
chmod +x ~/Multi-backend-DM/scripts/install_workloads.sh
sh ~/Multi-backend-DM/scripts/install_workloads.sh $log_file_name
```

### d. Process logs

Use script in **code/log_process** to process log file.

```shell
python ~/Multi-backend-DM/code/log_process
```
