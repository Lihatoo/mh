# mh (mihomo wrapper)

>基于 mihomo 的纯ubuntu终端控制梯子工具，适合简单全局控制与。

mihomo: https://github.com/mihomo/mihomo

# 部署

将目录下的`mh`复制到`/usr/local/bin`下，并添加执行权限。
```bash
sudo chmod +x mh   # 给予执行权限
sudo setcap cap_net_admin,cap_net_raw+ep  /home/lht/bfile/mihomo/mihomo # 给予网络tun权限
```
然后在任何终端都可以使用`mh`命令

# 使用

## 导入

> 支持两种导入方法
```bash
mh add name path
mh add name url
mh select name #  选择一个配置
```
分别是订阅链接或者是某个已配置好的`yaml`文件
得到如下的项目结构
```json
tnt
├── cache.db
├── config.yaml  # 这是mh生成的配置文件，用于启动mihomo
├── geoip.metadb # 这是运行中生成的文件
├── mihomo.log # 这是日志，可以用config.yaml 的log_file 指定error,warning,info,debug
└── providers
    └── tnt.yaml  # 这是提供节点的文件，来自你的订阅链接,tnt为你输入的名称
current.profile # 保存是否需要tun配置
run.pid  # 运行时保存的进程id，目前只能支持起一个mihomo
```

## 换节点

```bash
mh -l # 列出搜索可选择节点
mh name # 搜索并列表选择节点
```

## 其他操作

```bash
mh tun on/off # 开启/关闭tun
mh -h # 帮助
mh  # 快速预览信息
mh db # 一些测试，debug专用
```

# 错误
> 主要错误都可以看看`mihomo.log`文件，从其中分析
## 网络dns解析失败
> 节点正常搜索，测速正常，可是无法使用（浏览器，网站）
> 查看日志，前面下载正常，就是网络解析不了

`mh db`选择7 ,看看有几个dns！

问我这里显示有两个dns，也就是说错误的ip解析可能来自另一个干扰的`tailscale0`（我这里是这个）










