# mh (mihomo wrapper)

基于 mihomo 的纯终端控制梯子工具，适合简单全局控制与分享。
A terminal-only proxy wrapper based on mihomo, designed for simple global control and sharing.

A small Bash wrapper around `mihomo` to manage profiles, start/stop the service, switch nodes, and toggle TUN.

重要：必须使用 `sudo` 启动。
Important: You must run this script with `sudo`.

Repo / 仓库:
```
https://github.com/Lihatoo/mh
```

## What it does / 功能

- Creates per-profile directories under `MIHOMO_ROOT/<name>/` with generated `config.yaml`
- Starts/stops `mihomo` and records PID in `run.pid`
- Switches nodes by keyword and optionally ranks by delay
- Toggles TUN in the current profile and restarts
- Exports/unsets HTTP proxy environment variables

- 在 `MIHOMO_ROOT/<name>/` 下创建 profile 目录并生成 `config.yaml`
- 启动/停止 `mihomo`，PID 记录在 `run.pid`
- 通过关键词切换节点，并可按延迟排序
- 切换 TUN 并重启
- 导出/取消 HTTP 代理环境变量

## Requirements / 依赖

- Linux with `bash`
- `mihomo` binary in `MIHOMO_ROOT/mihomo`
- Tools: `ss`, `yq`, `jq`, `curl`, `find`, `ip`

- Linux + `bash`
- `mihomo` 二进制放在 `MIHOMO_ROOT/mihomo`
- 工具：`ss`, `yq`, `jq`, `curl`, `find`, `ip`

## Quick start / 快速开始

1. Set the root path / 设置根路径

Open `mh` and update this line to the absolute path of this repo:
打开 `mh`，把下面这行改成仓库的绝对路径：

```
MIHOMO_ROOT=/path/to/this/repo
```

2. Make the script executable / 授权可执行

```
chmod +x mh
```

3. Put `mh` in `/usr/local/bin` for direct use / 放到 `/usr/local/bin` 以便直接使用

```
sudo cp mh /usr/local/bin/mh
```

4. Start with `sudo` (required) / 必须用 `sudo` 启动

```
sudo mh
```

## Usage / 用法

Create a profile from a subscription URL (quote the URL is recommended):
从订阅 URL 创建 profile（建议加双引号）：

```
sudo mh add <name> "<url>"
```

Create a profile from a local file:
从本地文件创建 profile：

```
sudo mh add <name> /path/to/subscription.yaml
```

Start/select a profile:
启动/切换 profile：

```
sudo mh select
sudo mh select <name>
```

Stop:
停止：

```
sudo mh end
```

Toggle proxy env vars (current shell only):
导出/取消代理环境变量（只影响当前 shell）：

```
sudo -E mh on
sudo -E mh off
```

List nodes in the main group:
列出主组节点：

```
sudo mh -l
```

Switch node by keyword and rank by delay:
按关键词切换并按延迟排序：

```
sudo mh 美国
sudo mh HK
```

Toggle TUN (requires sudo):
切换 TUN（需要 sudo）：

```
sudo mh tnu on
sudo mh tnu off
sudo mh tnu toggle
```

Run connectivity test:
网络连通性测试：

```
sudo mh test
```

Show help:
查看帮助：

```
sudo mh --help
```

## Notes / 说明

- Default ports: `mixed-port=7890`, API `external-controller=127.0.0.1:9090`.
- If you use `sudo` and want `HTTP_PROXY/HTTPS_PROXY` to persist, use `sudo -E`.
- When you run `mh` with no arguments, it checks ports, environment, TUN status, and current node delay.

- 默认端口：`mixed-port=7890`，API `external-controller=127.0.0.1:9090`。
- 若想保留 `HTTP_PROXY/HTTPS_PROXY`，请用 `sudo -E`。
- 不带参数运行 `mh` 会检查端口、环境、TUN 状态和当前节点延迟。

## Template / 模板

Use `profile_template/` as a sanitized example of the basic profile format.
可参考 `profile_template/` 作为去隐私后的基础配置格式示例。



## Files created / 生成文件

- `current.profile`: name of the active profile / 当前 profile 名称
- `run.pid`: PID of the running `mihomo` process / 运行中的 PID
- `<profile>/mihomo.log`: log output for each profile / 日志文件

## Example session / 示例

```
# add profile
sudo mh add test "https://example.com/sub.yaml"

# start/select
sudo mh select test

# switch node by keyword
sudo mh 日本
```

## Links / 相关链接

Official mihomo repo:
官方 mihomo 仓库：

```
https://github.com/MetaCubeX/mihomo
```
