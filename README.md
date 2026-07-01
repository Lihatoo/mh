# mh

`mh` 是一个面向 Ubuntu 终端的 mihomo 包装脚本，用来管理 profile、启动/停止 mihomo、切换节点、输出 shell 代理环境变量，以及开关 TUN。

mihomo: https://github.com/mihomo/mihomo

## 部署

目录内需要包含：

- `mh`：控制脚本
- `mihomo`：mihomo 可执行文件
- `<profile>/config.yaml`：profile 配置，通常由 `mh add` 生成

```bash
chmod +x mh
sudo setcap cap_net_admin,cap_net_raw+ep "$(pwd)/mihomo"
```

如需全局使用，可以把 `mh` 放到 `PATH` 中。脚本会优先使用当前目录里的 `mihomo` 作为工作目录；如果当前目录没有 `mihomo`，才使用脚本所在目录。`/usr/local/bin` 不会被当作 profile 根目录；从其他目录运行时可通过 `MIHOMO_ROOT=/path/to/mihomo mh ...` 显式指定。

## 常用命令

```bash
mh add <name> <url|file>     # 添加订阅或本地 provider
mh select [name]             # 切换/启动 profile
mh start <name>              # 等价于 select <name>
mh end                       # 停止 mihomo
mh env                       # 输出代理 export
mh theme [name]              # 查看或切换输出主题
mh sysproxy [on|off|status]  # 开关 GNOME 系统代理
mh update [all|provider]     # 更新当前 profile 的 HTTP provider
mh mode rule|global|direct   # 切换模式
mh rules show|reset          # 查看/重置基础规则
mh tun [on|off|toggle]       # 开关 TUN
mh list [keyword]            # 列出节点并可输入序号切换
mh <keyword>                 # 搜索节点并按延迟排序选择
mh doctor                    # 诊断信息
```

让当前 shell 立刻走代理：

```bash
eval "$(mh env)"
```

默认 mixed-port 是 `127.0.0.1:7890`，socks-port 是 `127.0.0.1:7891`，API 是 `127.0.0.1:9090`。

输出主题可以切换：

```bash
mh theme              # 查看当前主题
mh theme list         # 查看可选主题
mh theme basic        # 基础版，最稳
mh theme ganyu        # 原神甘雨风格
mh theme kaomoji      # 颜文字版，适合 emoji 显示不完整的终端
mh theme minimal      # 极简版
```

GNOME/Ubuntu 桌面可以让 `mh` 帮你开系统代理：

```bash
mh sysproxy status
mh sysproxy on       # HTTP/HTTPS -> 127.0.0.1:7890, SOCKS -> 127.0.0.1:7891
mh sysproxy off
```

## Profile

`mh add name url` 会生成类似结构：

```text
name/
  config.yaml
  mihomo.log
  providers/
    name.yaml
current.profile
run.pid
```

新 profile 默认使用 `rule` 模式：本地/内网直连，其余流量走 `Final`，`Final` 默认选择 `Proxy`。

`providers/<name>.yaml` 只保存订阅下发的节点；`config.yaml` 保存 mh 管理的端口、模式、代理组和规则。mihomo 启动时会读取 `config.yaml`，再按 `proxy-providers` 引用 provider 节点，两者是组合生效。更新订阅只更新 provider 节点文件，不会覆盖本地规则。

域名排除写在当前 profile 的 `bypass.list`，格式尽量贴近 FLClash：

```text
*zhihu.com
*zhimg.com
*jd.com
100ime-iat-api.xfyun.cn
*360buyimg.com
localhost
*.local
127.*
10.*
```

执行 `mh rules reset` 后，`mh` 会把它编译进 `config.yaml` 的 `rules`，例如：

```yaml
rules:
  - DOMAIN-SUFFIX,zhihu.com,DIRECT
  - DOMAIN,100ime-iat-api.xfyun.cn,DIRECT
  - IP-CIDR,127.0.0.0/8,DIRECT,no-resolve
  - MATCH,Final
```

默认订阅更新间隔是 1 天：`interval: 86400`。默认日志级别是 `error`，减少 `mihomo.log` 输出。

## 排错

优先看：

```bash
mh doctor
tail -n 80 <profile>/mihomo.log
```

如果 TUN 启动失败，确认当前用户有 root 权限，或已经给 `mihomo` 设置 `cap_net_admin,cap_net_raw`。

终端可用但浏览器不可用时，通常是浏览器没有使用 shell 里的 `http_proxy` 环境变量。mihomo core 本身只负责监听本地端口或 TUN；FLClash 能“一键开”，是因为 GUI 额外帮你设置了系统代理或 TUN。处理方式三选一：

- 开启 TUN：`mh tun on`
- 开启 GNOME 系统代理：`mh sysproxy on`
- 在系统或浏览器代理里手动设置 HTTP/HTTPS 代理为 `127.0.0.1:7890`，SOCKS 为 `127.0.0.1:7891`
