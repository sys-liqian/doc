# VGPU

## 技术点

TensorFlow - Cuda
Pytorch - NewWare
PaddlePaddle - CANN
MXNet - DTK

## 常见GPU
Nvida TESLA、Quadro、GeForce | Cuda OpenGL
Cambricon(寒武纪) MLU-370、MLU-270-X5K | Neuware
木樨
HYGON（中科海光）DCU Z100、DCU Z100L | DTK
HISILICON (华为海思) Ascend310 | CANN
瀚博（深圳瀚博半导体）VA16 | vacc 目前支持单机多卡，不支持基于ray的多机多卡，sv系列显卡不支持VGPU


## 虚拟化方案

* PCIE直通

    依赖IOMMU（Input-Output Memory Management Unit），IOMMU作用：
    1. 地址映射与隔离，解决安全与寻址问题，物理GPU通过DMA（直接内存访问）直接读写系统内存。若无IOMMU，GPU可直接访问宿主机物理内存地址（HPA），可能导致虚拟机越权访问其他虚拟机或宿主机的内存（如恶意虚拟机通过DMA攻击宿主机）
    2. IOMMU可以将连续的虚拟地址映射到不连续的多个物理内存片段，对于没有IOMMU的情况，设备访问的物理空间必须是连续的，IOMMU可有效的解决这个问题.
* GPU SR-IOV

    * 摩尔线程MTT S3000
    * AMD 

        在GPUSR-IOV方案中，把一个物理GPU（Physical Function、PF）拆分成多个（Virtual Function、VF），这些VF依然是符合PCI规范的PCIe设备，可以将VF直通到虚机。
        GPU SR-IOV 使用分时复用的策略，显存根据设定的虚拟比由GPU SR-IOV驱动静态划分


* 硬件虚拟化，物理GPU拆分（MIG）

    NVIDIA Multi-Instance GPU,Ampere架构开始支持，
    A100,A800,H100,H800,H20最多可切分7个MIG,A30最多可以切分4个MIG，每个MIG实例拥有独立的SMS流处理器和显存

* VGPU内核态虚拟化
* VGPU软件模拟（cuda拦截）
* GPU over IP/IB,基于VGPU软件模拟，实现AI与GPU物理服务器分离
* GPU池化，增加统一调度，监控，动态伸缩，算力超分
* 多芯池化（多卡异构算力支持）

