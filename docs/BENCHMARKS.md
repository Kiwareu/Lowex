# 基准研究 / Benchmarks（2026-10-16）

目的：对照广受好评的公开配置、官方文档和知名博主的方案，找出 Lowex 各客户端输出的差距并改进。**只学习结构与写法，不拷贝内容**；规则集一律以远程 URL 引用，许可证见下表。

## 1. 学习过的来源与许可证

| 来源 | 星标 / 许可证（GitHub API，2026-10-16） | 学到的东西 | 我们怎么用 |
|---|---|---|---|
| [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script) | 28k / GPL-2.0 | 按服务拆分的规则集目录（Surge/QX/Loon/Clash 同源多格式） | 仅以 URL 引用规则集，不复制内容 |
| [Loyalsoldier/clash-rules](https://github.com/Loyalsoldier/clash-rules) | 29k / GPL-3.0 | 「直连 / 代理 / 广告 / 私有 / 国内 IP」的分层方式，域名规则在 IP 规则前 | 学习分层与顺序；不复制 |
| [MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat) | 5k / GPL-3.0 | `.mrs`（mihomo）/ `.srs`（sing-box）二进制规则集体积小、可更新 | 继续以 URL 引用 |
| [ACL4SSR/ACL4SSR](https://github.com/ACL4SSR/ACL4SSR) | 6.8k / CC-BY-SA-4.0 | 经典分组命名与 `.list` 规则 | 仅学结构（CC-BY-SA 有相同方式共享要求，不复制） |
| [Aethersailor/Custom_OpenClash_Rules](https://github.com/Aethersailor/Custom_OpenClash_Rules) | 6.6k / CC-BY-SA-4.0 | 国内/国外 DNS 分流、fake-ip 过滤、IPv6 策略的组合思路 | 仅学结构 |
| [SukkaW/Surge](https://github.com/SukkaW/Surge) 与 Sukka 博客 [《我有特别的 Surge 配置》](https://blog.skk.moe/post/i-have-my-unique-surge-setup/)、[《DNS 泄漏 / Fake IP》](https://blog.skk.moe/post/lets-talk-about-dns-cdn-fake-ip/) | 4.5k / AGPL-3.0 | **非 IP 规则放在 IP 规则前**，Fake-IP 下不在本地解析；`ipv6-vif=disabled`、`always-real-ip`、加密 DNS | 采纳写法（配置项来自 Surge 官方手册）；不复制规则 |
| [Johnshall/Shadowrocket-ADBlock-Rules-Forever](https://github.com/Johnshall/Shadowrocket-ADBlock-Rules-Forever) | 31k / 未声明 | 小火箭规则与 `[General]` 习惯 | 仅学结构 |
| [LOWERTOP/Shadowrocket](https://github.com/LOWERTOP/Shadowrocket)、[svcvit/sr-rule `nodnsleak`](https://raw.githubusercontent.com/svcvit/sr-rule/main/shadowrocket/nodnsleak-pk.ini)、[ianzo0/Shadowrocket-Rule](https://github.com/ianzo0/Shadowrocket-Rule/blob/main/ianzo-full.conf) | 社区 | `dns-fallback-system=false`、`dns-direct-system=false`、`hijack-dns` 硬编码 DNS 列表、`always-real-ip`、`stun-response-ip`、`icmp-auto-reply` | 采纳这些 `[General]` 项 |
| [crossutility/Quantumult-X sample.conf](https://github.com/crossutility/Quantumult-X/blob/master/sample.conf)、[DivineEngine QX DNS](https://divineengine.net/article/quantumult-x-dns-settings/) | 官方样例 | `[dns]` 的 `no-system`、`no-ipv6`、`doh-server`、`prefer-doh3`；`udp_drop_list=QUIC` | 采纳 `no-system`；`prefer-doh3` 未采纳（需客户端回落行为核实） |
| [Loon 官方 General 文档](https://nsloon.bid/document/general) | 官方 | `doh-server`、`disable-stun`、`sni-sniffing`、`ip-mode` | 采纳 `sni-sniffing`；`disable-stun` 仅在「拦截 STUN」时输出 |
| [MetaCubeX 官方 DNS 文档](https://wiki.metacubex.one/en/config/dns/)、[Naomi 樱花庄《Mihomo 配置一把梭》](https://naomi233.github.io/code/exp/05.mihomo-config.html)、[clashopen DNS 泄漏实践](https://clashopen.com/zh-CN/blog/articles/meta-core-dns-leak-prevention-2026.html)、[wener 笔记](https://wener.me/notes/service/network/proxy/mihomo/conf) | MIT（mihomo）/ 博客 | `respect-rules: true` 必须配 `proxy-server-nameserver`；`direct-nameserver`；`nameserver-policy` 国内/私有走国内 DoH，其余境外 DoH；fake-ip + 过滤表 | Lowex 的 Mihomo 输出本来就按此结构，对照后**无需改动** |
| sing-box 官方 [TUN](https://sing-box.sagernet.org/configuration/inbound/tun/) 文档、[core-tutorial](https://core-tutorial.argsment.com/singbox/tun) | NOASSERTION | `sniff` 与 `hijack-dns` 作为路由动作；`strict_route`；`stack: mixed`；DNS 服务器带 `detour` | 采纳 `stack: mixed`、`reverse_mapping: true` |
| YouTube：《2026 防封锁指南：别让 DNS 泄露毁了隐私！一套 Mihomo 逻辑…》[视频](https://www.youtube.com/watch?v=p_ErtI5UmWU)（仅读到描述/文字稿片段）、《Mihomo（Nikki）一键完美配置》[视频](https://m.youtube.com/watch?v=RsVX8n1FOVg)（只有标题） | 创作者内容，未取得许可，不复制 | 规则顺序：局域网/私有 → 国内服务直连 → AI/Google/YouTube/GitHub 等境外服务 → GeoSite/GeoIP 中国兜底 → MATCH；`fake-ip`+`respect-rules` | 与我们现有顺序一致 |
| X（Twitter）：[@riverleaf88](https://x.com/riverleaf88) 的 sing-box 配置生成器帖子；帖子里提到「IPv6 / 国内解析到海外 / 出口 IP 漂移」是常见痛点 | 公开帖，只读 | 痛点清单（IPv6 策略、DNS 分流、出口漂移） | 只作为需求参考，未取用其内容 |

> 未能访问的：Semporia/Clash-Rules、fmz200/wangzhe666、DivineEngine/Profiles 在 GitHub API 返回 Not Found（仓库已改名或删除），未研究。

## 2. 与来源矛盾、已纠正的一点

部分 2026 年博客说「sing-box 1.14 已移除 FakeIP」。**官方文档仍保留 `type: "fakeip"` DNS server，且 sing-box 1.14.3 `check` 通过 Lowex 输出**，所以没有改成真实解析。结论：以官方文档 + 实际校验为准，博客说法记为「不可靠」。

## 3. 差距 → 改进（逐客户端）

| 客户端 | 发现的差距 | 改进 |
|---|---|---|
| Mihomo 系（Verge Rev / FlClash / Clash Mi / CMFA / Clash Party / Mihomo） | 对照官方文档与多个博主：`respect-rules`、`proxy-server-nameserver`、`direct-nameserver`、`nameserver-policy`、fake-ip 过滤、sniffer、`strict-route`、IPv6 策略均已具备；规则域名在 IP 前 | 无结构性差距；用 mihomo 1.19.32 `-t` 校验通过 |
| Stash | 输出没有 STUN 规则（逻辑规则语法未核实） | **未改**，在防泄漏清单里如实显示「未开启」 |
| sing-box / Karing | TUN 缺 `stack`；DNS 缺 `reverse_mapping` | 加 `stack: mixed`、`reverse_mapping: true`；sing-box 1.14.3 `check` 通过 |
| Surge | 缺 `ipv6-vif`、`hijack-dns`、`always-real-ip` | 新增 `ipv6-vif = disabled`（关 IPv6 时）、`hijack-dns = *:53`、`always-real-ip`（局域网/连通性/校时域名） |
| Shadowrocket | 缺 `dns-fallback-system=false`、`dns-direct-system=false`、`prefer-ipv6=false`、`icmp-auto-reply`、`hijack-dns`、`always-real-ip`、`stun-response-ip` | 全部新增（`stun-response-ip` 仅在「拦截 STUN」时） |
| Quantumult X | `[dns]` 缺 `no-system`（DNS 失败回落到系统 DNS） | 新增 `no-system` |
| Loon | 缺 `sni-sniffing`；拦截 STUN 时缺 `disable-stun` | 新增（`disable-stun` 仅在拦截 STUN 时） |
| Egern | 结构与官方示例一致 | 无改动；仍标「未用真机导入」 |

## 4. 防泄漏分数怎么算（不造假）

「防泄漏检查」里每一项都会去**生成出的配置文本**里找对应字段（例如 `respect-rules: true`、`hijack-dns`、`ipv6-vif = disabled`、`no-system`、`"action": "hijack-dns"`）：找到才算「已防护」，找不到就降级并写明原因。综合分 = 适用项加权得分 ÷ 适用项总权重（已防护 1、部分与「需你手动」各 0.5、未开启 0，不适用的项不计入）。

2026-10-16 在默认选项（iOS/其他系统各自的默认客户端）下实测：

| 客户端 | 分数 | 没满分的原因 |
|---|---|---|
| Mihomo 系 | 98 | 浏览器自身 WebRTC 需你手动设置（配置管不了） |
| sing-box / Karing | 95 | 校时/连通性检测、订阅下载出口没有对应字段 |
| Stash | 90 | 没有 STUN 规则 |
| Shadowrocket | 86 | 无 TUN 严格路由概念、DNS 经代理仅部分可控 |
| Surge | 81 | 同上，且订阅下载出口不可单独指定 |
| QX / Loon | 74 | 没有 DNS 劫持 / respect-rules / strict-route 之类的开关 |
| Egern | 73 | 同上 |

客户端本身没有的开关无法靠配置补齐，所以这些客户端达不到 98；这是诚实结果，不是配置没写好。

## 5. 校验结果

- Mihomo v1.19.32：10 份默认输出 + 120 份随机选项（IPv6/TUN/fake-ip/故转/负载均衡/广告/STUN/QUIC/低内存/App 内模式）全部 `-t` 通过。
- sing-box 1.14.3：`check` 全部通过（含 Karing 输出）。
- 文本客户端（Surge、Shadowrocket、QX、Loon、Egern、Stash）：没有官方校验器，按官方手册/样例逐项核对语法，并用 lint 检查不含 `undefined/NaN/[object`；**未做真机导入，标为未验证**。

## 6. 时效性核查（检查日期：2026-10-16）

要求：学习/引用的来源最近 1–2 年内仍在维护，不用已废弃的语法。

**仓库最近一次推送（GitHub API）**，均未归档：

| 仓库 | 最近推送 | 仓库 | 最近推送 |
|---|---|---|---|
| blackmatrix7/ios_rule_script | 2026-10-15 | MetaCubeX/mihomo | 2026-10-13 |
| Loyalsoldier/clash-rules | 2026-10-15 | SagerNet/sing-box | 2026-10-13 |
| MetaCubeX/meta-rules-dat | 2026-10-16 | clash-verge-rev/clash-verge-rev | 2026-10-16 |
| ACL4SSR/ACL4SSR | 2026-10-07 | chen08209/FlClash | 2026-10-16 |
| Aethersailor/Custom_OpenClash_Rules | 2026-10-16 | MetaCubeX/ClashMetaForAndroid | 2026-10-13 |
| SukkaW/Surge | 2026-10-16 | KaringX/clashmi-docu | 2026-09-20 |
| Johnshall/Shadowrocket-ADBlock-Rules-Forever | 2026-10-15 | Loon0x00/LoonExampleConfig | 2026-09-18 |
| LOWERTOP/Shadowrocket | 2026-10-15 | ClashConnectRules/Egern | 2026-09-13 |
| svcvit/sr-rule | 2026-07-13 | crossutility/Quantumult-X | 2026-06-29 |
| ianzo0/Shadowrocket-Rule | 2026-07-30 | Koolson/Qure（仅图标 URL） | 2026-06-30 |
| tom-snow/Sidestore-ClashMi | 2026-02-13 | | |

- 已排除：Semporia/Clash-Rules、fmz200/wangzhe666、DivineEngine/Profiles（API 返回 Not Found，视为已失效）。
- 博客与视频的发布日期没有逐一核实；其中的写法一律与同期官方文档交叉核对后才采用（例如 Surge 选项以 manual.nssurge.com 为准，mihomo 以 wiki.metacubex.one 为准，sing-box 以 sing-box.sagernet.org 为准）。已发现并拒绝一条过时/错误说法（「sing-box 1.14 移除 FakeIP」，见第 2 节）。

**废弃语法检查**：

- Mihomo 输出用 mihomo 1.19.32 校验，无 warn / deprecated 提示；不使用 Clash Premium 独有键（如 `script:` 规则块、`tun.device-url`），Stash 走独立生成路径。
- sing-box 输出用 1.14.3 校验，无弃用提示；使用新式带类型 DNS server（`type: https/local/fakeip`），嗅探用路由动作 `sniff`（不在入站里写 `sniff`），远程规则集用 `http_client`（不用已废弃的 `download_detour`），不使用 `rule_set_ip_cidr_accept_empty`。
- Loon 用 `ip-mode`（取代旧的 `ipv6`）；Surge 的 `ipv6-vif` 用 `disabled`（旧值 `off` 仅兼容）；Shadowrocket / QX 选项来自 2026 年仍在更新的社区手册与官方样例。
- **局限**：Surge、Loon、Shadowrocket、QX、Egern、Stash 没有官方离线校验器，无法自动发现这些客户端的新弃用项；若你发现某项在新版本里被移除，请提 issue。
