# linux中page size修改

由于实验中为了体现不同系统配置对应用的影响，需要探究系统和内存后端有关的参数的调整对应用的影响。其中page size是预想情况中对应用运行影响较大的参数之一，因此需要探究page size对应用造成的影响。

## 1. Huge page

现有linux系统支持非4kb的页面大小，一般是通过huge page来实现的，该功能已经整合到linux内核代码中，并且可以进行调整（无需编译，但需要重启），但huge page在进行页面交换的时候仍然是将huge page划分成小page（4kB）来进行交换，无法体现系统在swap上的性能。

但是是否可以考虑为huge page进行页面交换的时候是一次性发生大量page swap，和原有方式仍然不同，可以探讨一下这部分带来的性能差异

目前linux系统中huge page主要有两种存在形式：

**transparent huge page:**

动态分配，不需要用户进行显示地控制或者分配

关闭方式，修改grub文件，增加`transparent_hugepage=never`

或者短暂修改

```shell
sudo sh -c "echo never > /sys/kernel/mm/transparent_hugepage/enabled""
```

在尝试关闭之后与关闭之前进行对比，发现运行时间有着较为明显的差异，开启thp的运行时间明显小于关闭thp的运行时间。在quicksort，tf-inception, tf-resnet等应用上差异明显，在linpack上差异较小。目前不能排除是应用本身内存大小带来的差异还是应用本身特征带来的差异。

| backend | thp on/off | workload  | local size | page fault | sys time |
| ------- | ---------- | --------- | ---------- | ---------- | -------- |
| kvm io  | on         | tf-resnet | 0.1        | 4109194    | 289      |
| kvm io  | on         | tf-resnet | 0.2        | 1434886    | 117.74   |
| kvm io  | on         | tf-resnet | 0.3        | 610848     | 59.47    |
| kvm io  | on         | tf-resnet | 0.4        | 157911     | 21.63    |
| kvm io  | on         | tf-resnet | 0.5        | 53325      | 16.93    |
| kvm io  | on         | tf-resnet | 0.6        | 12663      | 14.58    |
| kvm io  | on         | tf-resnet | 0.7        | 0          | 14.17    |
| kvm io  | on         | tf-resnet | 0.8        | 0          | 13.36    |
| kvm io  | on         | tf-resnet | 0.9        | 0          | 14.15    |
| kvm io  | on         | tf-resnet | 1          | 0          | 13.83    |
| kvm io  | off        | tf-resnet | 0.1        | 4281018    | 361.33   |
| kvm io  | off        | tf-resnet | 0.2        | 1524094    | 155.53   |
| kvm io  | off        | tf-resnet | 0.3        | 674781     | 81.22    |
| kvm io  | off        | tf-resnet | 0.4        | 178925     | 33.44    |
| kvm io  | off        | tf-resnet | 0.5        | 54147      | 26.58    |
| kvm io  | off        | tf-resnet | 0.6        | 11297      | 23.56    |
| kvm io  | off        | tf-resnet | 0.7        | 0          | 22.68    |
| kvm io  | off        | tf-resnet | 0.8        | 0          | 22.65    |
| kvm io  | off        | tf-resnet | 0.9        | 0          | 22.87    |
| kvm io  | off        | tf-resnet | 1          | 0          | 22.48    |

**huge page:**

预分配

而且使用的话一般是需要应用自己进行显示地去映射huge page，对于用户空间，则可以利用 “hugetlbfs” 创建和使用 huge page 作为匿名（anonymous）页

## 2. 修改Page size

1. 直接修改page size或者page shift的宏定义；目前没有找到系统的教程，但有地方说不支持直接改动

2. make menuconfig修改，尝试了一下arm64上找到了可以改的地方，x86没找到在哪改，目前搜索的结果也是x86_64不支持page size的修改

![19.png](D:\study\yjs\SAIL\huawei\DM%20prj\document\figure\19.png)

1. The PAGESIZE is set at kernel compile time. That selection is only valid for i386 hardware. If you run a 64-bit system or any other architecture, the page size is 4K and cannot be changed.
