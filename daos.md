# DAOS

## DAOS In Rocklinux 8.10

```bash
# https://www.intel.cn/content/www/cn/zh/developer/articles/case-study/daos-quickstart-guide-running-daos-in-a-vm.html
wget -O /etc/yum.repos.d/daos-packages.repo https://packages.daos.io/v2.0/EL8/packages/x86_64/daos_packages.repo
# 所有节点安装epel源
yum install -y epel-release
# 在服务节点安装 daos-server
yum install -y daos-server
# 在管理节点和客户端节点安装 daos-client dao-agent 属于daos-client
yum install -y daos-client

systemctl stop firewalld
systemctl disable firewalld

# 启动server
mkdir -p /var/log/daos
mkdir -p /var/lib/daos/daos_scm
mkdir -p /var/lib/daos/daos_server
mkdir -p /var/lib/daos/daos_control

# 扫描网络查看provider,当前选择ofi+sockets
daos_server network scan

# 使用本地文件模拟nvme设备
mkdir -p /var/lib/daos/dev
# 16G
dd if=/dev/zero of=/var/lib/daos/dev/daos-bdev bs=1M count=16384
```
vi /etc/daos/daos_server.yml
```yaml
name: daos_server

access_points: ['localhost']
port: 10001

transport_config:
   allow_insecure: true

provider: ofi+tcp;ofi_rxm
socket_dir: /var/lib/daos/daos_server
nr_hugepages: 1024
control_log_mask: DEBUG
control_log_file: /var/log/daos/daos_server.log

engines:
-
  targets: 1
  nr_xs_helpers: 0
  fabric_iface: ens3
  fabric_iface_port: 31416
  log_mask: INFO
  log_file: /var/log/daos/daos_engine.0.log
  env_vars:
    - FI_SOCKETS_MAX_CONN_RETRY=1
    - FI_SOCKETS_CONN_TIMEOUT=2000
    - DAOS_SCHED_UNIT_RUNTIME_MAX=0

  # Storage definitions
  scm_mount: /var/lib/daos/daos_scm
  scm_class: ram
  scm_size: 4

  bdev_class: file
  bdev_size: 16
  bdev_list: [/var/lib/daos/dev/daos-bdev]
```
vim /etc/daos/daos_control.yml 
```yaml
# 和 daos_server 配置的保持一致
name: daos_server
port: 10001
hostlist: ['localhost']

transport_config:
    allow_insecure: true
```
vim /etc/daos/daos_agent.yml
```yaml
# 和 daos_server保持一致
name: daos_server
access_points: ['localhost']

port: 10001

transport_config:
    allow_insecure: true
log_file: /var/log/daos/daos_agent.log
```

启动
```bash
# 若使用非root用户启动daos，需要开启IOMMU
# 使用root用户则
# 修改 /usr/lib/systemd/system/daos_server.service 中的用户和组
# 修改 /usr/lib/systemd/system/daos_agent.service 中的用户和组
systemctl daemon-reload
systemctl start dao_server
systemctl enable dao_server
systemctl start dao_agent
systemctl enable dao_agent
```

```bash
# 存储格式化
dmg -i storage format
# 创建pool
dmg pool create --size=2G test_pool -i
# 查看pool
dmg pool list -i
# 查询存储使用
dmg -i storage query usage
# 查询pool详情
dmg -i pool query test_pool
# 创建容器
daos container create --type=POSIX -l test-cont  test_pool
# 查看容器
daos container list test_pool
```


## SPDK

```bash
# 文档地址
# https://spdk.io/doc/nvmf.html

# 内核开启nvme相关驱动
dracut --force --add-drivers "nvme nvme_core nvme_fabrics"
reboot
modprobe nvme nvme_core nvme_fabrics

# 安装daos开发库
yum install -y daos-devel
# 升级python到3.9
。。。
# 安装编译工具
yum install -y git gcc gcc-c++ make
# 启用powertools软件库，spdk安装依赖时用到
dnf config-manager --set-enabled powertools
# 下载源码
git clone https://github.com/spdk/spdk.git
cd spdk
# 更新子项目
git submodule update --init
# 安装依赖
# 若有rhel.sh未能安装成功的包，单独处理
# 在项目根目录执行，如果daos是源码编译安装，则需要--with-daos={{installpath}}
scripts/pkgdep/rhel.sh
# 生成编译配置 ./configure --help 查看帮助
./configure --with-daos
# 编译完成后内容输出在./build
make -j 4
# 单元测试
./test/unit/unittest.sh

# 开启大页内存
vim /etc/sysctl.conf
# 写入 vm.nr_hugepages=1024
sysctl -p

# 启动spdk
scripts/setup.sh
# 运行nvmf_tgt,虚拟机只有一个Numa Node无需指定-m
cd build/bin
nohup nvmf_tgt > nvmf_tgt.log 2>&1 &
```

## SPDK RPC API
```bash
# SPDK查看rpc支持的所有方法
scripts/rpc.py rpc_get_methods

# SPDK创建transport
scripts/rpc.py nvmf_create_transport -t TCP -u 16384 -m 8 -c 8192

# SPDK查看transport
scripts/rpc.py nvmf_get_transports

### 注意  ###
### spdk daos bdev 与 daos 通信，需要在spdk 所在节点安装 daos_agent ###

# SPDK在Daos DFS 上创建SPDK bdev 块设备
scripts/rpc.py bdev_daos_create daosdev0 test_pool test-cont 64 4096

# SPDK查看bdev
scripts/rpc.py bdev_get_bdevs

# SPDK创建subsystem
scripts/rpc.py nvmf_create_subsystem nqn.2016-06.io.spdk:cnode1 -a -s SPDK00000000000001 -d SPDK_Controller1

# SPDK查看subsystem, subsystem中包含该subsystem的namespaces
scripts/rpc.py nvmf_get_subsystems

# SPDK子系统添加命名空间
scripts/rpc.py nvmf_subsystem_add_ns nqn.2016-06.io.spdk:cnode1 daosdev0

# SPDK添加监听
scripts/rpc.py nvmf_subsystem_add_listener nqn.2016-06.io.spdk:cnode1 -t tcp -a 192.168.122.78 -s 4420

# SPDK查看监听
scripts/rpc.py nvmf_subsystem_get_listeners nqn.2016-06.io.spdk:cnode1

# 客户端挂载设备
nvme discover -t tcp -a 192.168.122.78 -s 4420
nvme connect -t tcp -n nqn.2016-06.io.spdk:cnode1 -a 192.168.122.78

# 客户端查看nvme设备
nvme list

# 客户端取消挂载
nvme disconnect -n nqn.2016-06.io.spdk:cnode1

# SPDK取消监听
scripts/rpc.py nvmf_subsystem_remove_listener nqn.2016-06.io.spdk:cnode1 -t tcp -a 192.168.122.78 -s 4420

# SPDK移除subsystem的namespace rpc.py nvmf_subsystem_remove_ns nqn nsid
scripts/rpc.py nvmf_subsystem_remove_ns nqn.2016-06.io.spdk:cnode1 1

# SPDK 移除subsystem
scripts/rpc.py nvmf_delete_subsystem nqn.2016-06.io.spdk:cnode1

# SPDK 移除 bdev 块
scripts/rpc.py bdev_daos_delete
```