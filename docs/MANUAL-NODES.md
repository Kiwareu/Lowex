# 手动节点（SOCKS5 / HTTP / HTTPS）

「节点」页第三块可手动添加静态代理，适合住宅 / 家宽代理套餐。**本文不含任何真实服务器或账号。**

## 页面布局
节点页从上到下：① 订阅链接 URL（仅能写订阅的客户端）② 节点链接 / Base64（小火箭无此区）③ 手动添加节点。不支持的区块隐藏，仅保留一行小字说明。

## 放置方式
Quantumult X 与小火箭可选「写入配置文件」或「在客户端 App 内自己添加」；选后者时生成的配置不含订阅、节点链接和手动节点，策略组按名称里的地区关键词收纳 App 内已有节点。其余客户端只能写入配置。

## 字段
名称（决定归入哪个地区：名称里含「香港」「日本」等关键词会进对应地区组）、类型（SOCKS5 / HTTP / HTTPS，SOCKS5 可选 TLS）、主机、端口、用户名与密码（可留空）。可编辑、删除、单独开关。

## 密码存放
- 密码保存在本机**钥匙串**（`AfterFirstUnlockThisDeviceOnly`）；若当前签名方式不允许使用钥匙串，回退保存到 App 沙盒的私有文件（不备份、开启文件保护）。
- 不进 UserDefaults 状态、不写日志、不上传。仅在你点「生成」时随配置文本写入输出文件。

## 各客户端支持与写法
| 客户端族 | SOCKS5 | SOCKS5-TLS | HTTP | HTTPS | 写法 |
|---|---|---|---|---|---|
| Clash / Mihomo / Stash（Verge、FlClash、Clash Mi、CMFA、Mihomo、Clash Party、Stash） | ✓ | ✓ | ✓ | ✓ | `proxies:` 里 `type: socks5 / http`，`tls: true` |
| sing-box / Karing | ✓ | ✗ | ✓ | ✓ | outbounds：`type: socks`（version 5）/ `type: http` + `tls` |
| Surge | ✓ | ✓ | ✓ | ✓ | `[Proxy]`：`名称 = socks5 / socks5-tls / http / https, 主机, 端口, 用户, 密码` |
| Shadowrocket | ✓ | ✓ | ✓ | ✓ | conf `[Proxy]` 同 Surge 写法（来源：社区手册 LOWERTOP/Shadowrocket 的配置说明；官方未公开文档） |
| Loon | ✓ | ✗ | ✓ | ✓ | `名称 = socks5,主机,端口,"用户","密码",udp=true`；HTTPS 为 `https,...`（官方文档无 SOCKS5 over TLS） |
| Quantumult X | ✓ | ✓ | ✓ | ✓ | `[server_local]`：`socks5=主机:端口, username=, password=, over-tls=true, tag=名称` / `http=…` |
| Egern | ✓ | ✗ | ✓ | ✓ | `proxies:` 里 `socks5:` / `http:` / `https:`（SOCKS5 over TLS 字段未核实，跳过） |

## 特殊字符与校验
- 主机不能含空格、逗号、引号、斜杠；端口 1–65535；名称、主机非空。
- Surge / Shadowrocket / Quantumult X：账号密码里的英文逗号、双引号无法安全转义，该节点会被**跳过并在生成结果里给出原因**（Loon 用引号包裹，可含逗号，但不能含双引号）。YAML / JSON 客户端由序列化器处理，任意字符均可。
- 客户端写不出的节点不会写入配置，也不会被策略组引用；节点列表里会显示橙色提示。
