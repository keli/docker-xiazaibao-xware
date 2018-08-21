# Docker运行下载宝固件中的XWare远程下载

第三方硬件上的迅雷远程下载已经都没有速度了。迅雷自己生产的下载宝也已经停产。

还好下载宝虽然死了，但毕竟曾经是亲儿子，网上流传的最新338固件用来远程下载还有速度。

因为本人在群晖NAS之外，不想只是为了远程下载多跑一个硬件，所以就有了本项目：

在docker中用qemu模拟mips芯片运行下载宝固件中的xware……


## 使用方法

### 必要条件

**请注意：你需要一个下载宝硬件的MAC地址！且该下载宝不能已经被绑定到不属于你的帐户！**

因为下载宝中的xware会提交mac地址给服务器校验，如果不是下载宝的mac地址则不会返回激活码。并且一个下载宝MAC地址只会绑定一个迅雷帐户。

### 拉取镜像

```
docker pull keli/xiazaibao-xware:latest
```

### 创建一个下载目录用于挂载卷

```
mkdir ~/data
```

### 运行示例

```
docker run -d \
        --name=xware \
        -p 9000:9000 \
        -v ~/data:/data \
        --mac-address 00:1A:2B:3C:4D:5E \
        --privileged \
        keli/xiazaibao-xware
```

也可以通过macvlan建立bridge接入到本地网络再运行，不依赖端口转发了，这样就更像一台本地接入的设备：

```
docker network create -d macvlan \
        --subnet=192.168.1.1/24 --gateway=192.168.1.1 \
        --ip-range=192.168.1.64/27 -o parent=eth0 macvlan

docker run -d \
        --name=xware \
        --network macvlan \
        -v ~/data:/data \
        --mac-address 00:1A:2B:3C:4D:5E \
        --privileged \
        keli/xiazaibao-xware
```

#### 注意要点：

* --privileged 提高权限不可少
* --mac-address 指定一个下载宝的mac地址


### 查看激活码/到下载宝远程迅雷页面增加设备

```
docker logs xware
```

输出的底部寻找以下这样一行

```
active_key: aabbcc
```

访问 http://yc.xzb.xunlei.com 或在迅雷客户端的下载宝应用中，输入激活码 aabbcc 以绑定设备。

## 其他事项

#### 从2018年7月底开始下载宝的离线加速已经无法使用（据论坛截图已被官方客服确认），但还可以正常下载。目前尚未找到解决办法。

#### 本镜像修改了 /xzb/etc/etm.ini，随意设置了jumpkey参数使之不为空，这样冷门资源虽然无法离线加速，但至少高速通道通常能有速度。
