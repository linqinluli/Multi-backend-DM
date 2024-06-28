# xDM

Our paper **Boosting Data Center Performance via Intelligently Managed Multi-backend Disaggregated Memory** has been accepted in SC'24.

This paper proposes xDM, a multi-backend disaggregated memory system that can manage multiple far memory paths with high performance.

## File description

`code`: Source code

        `code/drivers`: Source code of RDMA and DRAM backend drivers.

        `code/eval`: Source code of different workloads.

        `code/farmemserver`: Source code of RDMA server.

        `code/kernel`: Source code of fastswap kernel.

        `code/log_process`: Source code of log process.

        `code/scripts`: Source code of scripts used in installation.

`document`：Include documents about how to confige our system.

## 1. xDM path configuration

### a. Requirements

1）xDM rdma server：a server with at least 64G memory, a MT27800 Family [ConnectX-5] NIC(recommend), MLNX_OFED_LINUX-5.8-4.1.5.0 installed (available at [Linux InfiniBand Drivers (nvidia.com)](https://network.nvidia.com/products/infiniband-drivers/linux/mlnx_ofed/), should match the Linux distribution and rdma NIC version.), 

2）xDM client：a server with at least 64G memory, a MT27800 Family [ConnectX-5] NIC(recommend), MLNX_OFED_LINUX-5.8-4.1.5.0 installed (available at [Linux InfiniBand Drivers (nvidia.com)](https://network.nvidia.com/products/infiniband-drivers/linux/mlnx_ofed/), should match the Linux distribution and rdma NIC version.), require qemu-kvm installed

### b. Install xDM in xDM client

#### 1）Install VM in xDM client

Install qemu-kvm, we recommend to install virt-manager to manage VMs

```shell
sudo apt install qemu-system qemu-utils virt-manager libvirt-clients libvirt-daemon-system -y
```

Install VM with virt-manager. We recommand to use ubuntu 16.04. The next steps are finished in the VMs.

#### 2) Compiling and installing data swap kernel in each vm on the client node, only DRAM and RDMA kernel need this step

We use modified kernel in  [clusterfarmem/fastswap](https://github.com/clusterfarmem/fastswap) and based on the drivers to implement xDM. We also use part of workloads in [clusterfarmem/cfm](https://github.com/clusterfarmem/cfm) .

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

Now you can use the provided patch and apply it against your copy of linux-4.11, and use the generic Ubuntu config file for kernel 4.11. You can get the config file from internet, or you can use the one we provide.

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

The fastswap kernel has been installed in the VM. If you want to use RDMA or DRAM backend, you should boot system with the modified 4.11 fastswap kernel.

#### 3) Configure rdma in kvm virtual machine

    Refer to document [configure rdma in kvm VM](document/KVM_RDMA_Configuration.md), in this step, make sure the ofed driver you installed in VM is 4.3 version. If the official version 4.3 driver is not available, we provide a Google Cloud Drive download [link](https://drive.google.com/file/d/1-kEu_ks2syC62Fg1YYLBFcR3ugT_h3ZD/view?usp=drive_linkhttps://drive.google.com/file/d/1-kEu_ks2syC62Fg1YYLBFcR3ugT_h3ZD/view?usp=drive_link).

#### 4) Compile backend drivers

**DRAM backend:**

Use DRAM backend in xDM client (in VM)

```shell
cd ~/Multi-backend-DM/code/drivers
make BACKEND=DRAM
```

**RDMA backend:**

Use RDMA backend in xDM client (in VM)

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

xDM supports three types of swap backend SSD (or disk), DRAM, and RDMA. After following the above steps, you can configure it. We offer scripts for configuration. Before you use configure backend, you should have 32G swap space set.

```shell
free -g | grep swap
# Swap:             32           0           32
```

**SSD backend (supporting Linux simple kernel):**

```shell
cd ~/Multi-backend-DM/code/scripts/
sudo chmod +x backendswitch.sh
./backendswitch.sh ssd $path_mount_on_ssd
```

**DRAM backend (supporting modified Linux kernel)**

```shell
cd ~/Multi-backend-DM/code/scripts/
sudo chmod +x backendswitch.sh
./backendswitch.sh dram
```

**RDMA backend (supporting modified Linux kernel)**

To build and run the far memory server do(xDM RDMA server):

```shell
./rmserver $port $far_memory_size $cpu_num_in_rdma_client
```

Configure rdma backend in xDM client

```shell
cd ~/Multi-backend-DM/code/scripts/
sudo chmod +x backendswitch.sh

./backendswitch.sh rdma $rdma_server_ip $rdma_server_port $rdma_client_ip
```

## 2. xDM parameter modification

### a. Backend switch

Using `code/scripts/backendswitch.sh`, we strongly suggest to use SSD backend without the modified kernel for it may cause the system crush. We will solve the problem in the next version.

Configure a new backend or switch to another backend can be finished to use the script. Just follow the steps in **Backend configuration**.

### b. Configuring data granularity (by turning on/off THP)

turn on THP

```shell
sudo sh -c "echo always > /sys/kernel/mm/transparent_hugepage/enabled"
```

turn off THP

```shell
sudo sh -c "echo never> /sys/kernel/mm/transparent_hugepage/enabled"
```

### c. Configuring  I/O bandwidth (by assigning CPU core numbers)

The number of CPUs can be only configured by kvm. You should shut down the VM server and start it.

```shell
# modify VM configuration
sudo virsh edit CacheExp
# query the number of CPUs
cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l
```

### d. Configuring data distribution (by assigning local memory ratio)

Here is a example of how to evaluate **chatglm** with 0.5 local memory ratio.

```shell
cd ~/Multi-backend-DM/code/eval
python3 benchmark chatglm 0.5
```

Here is an example of hot to configure NUMA node assignment.

```shell
numactl --cpunodebind=0 --membind=0 ./test
numactl -C 0-1 ./test
```

### Here are other operations in VM that may be used:

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

## 3. System evaluation

Here are the workloads we support now.

| type           | name            | state | Notes                                               |
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

### a. Workload preparation

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

**text-classify**:

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

**text-classify**:

model:refer to [GitHub - gaussic/text-classification-cnn-rnn: CNN-RNN中文文本分类，基于TensorFlow](https://github.com/gaussic/text-classification-cnn-rnn)

data:refer to [http://thuctc.thunlp.org/](http://thuctc.thunlp.org/)

**bet-uncased**:

model:refer to [google-bert/bert-base-uncased · Hugging Face](https://huggingface.co/bert-base-uncased)

### b. Evaluate individual workloads

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

Here is an example of how to evaluate **chatglm** with a 0.5 local memory ratio.

```shell
cd ~/Multi-backend-DM/code/eval
python3 benchmark chatglm 0.5
```

### c. Evaluate multi workloads

Make sure you have installed the workloads install in the `code\eval` path. Here is a script to quickly install workloads we provide in the repo.

```shell
chmod +x ~/Multi-backend-DM/code/scripts/install_workloads.sh
sh ~/Multi-backend-DM/code/scripts/install_workloads.sh
```

Then evaluate mutil workloads:

```shell
chmod +x ~/Multi-backend-DM/code/scripts/install_workloads.sh
sh ~/Multi-backend-DM/code/scripts/eval_workloads.sh $log_file_name
```

### d. Generate results (processing logs)

Use script in **code/log_process** to process log file.

```shell
python ~/Multi-backend-DM/code/log_process/log_process.py $log_file_path
```
