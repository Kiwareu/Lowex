# 网络环境与 DNS 参数研究

调研日期：2026-10-17。只采用官方文档 / 官方公告为「官方」依据；论坛帖子、社区经验标为「未核实」，不会被当成事实写进默认值。

## 结论摘要
1. **国内公共 DoH 与运营商无关**：DNSPod 官方说明 119.29.29.29 经 BGP Anycast 与国内主要运营商互联，后端递归按省份 / 运营商分区部署并支持 ECS；阿里公共 DNS 官方说明支持 ECS 与 DoH/DoT。没有任何官方资料说明移动 / 联通 / 电信需要不同的公共 DNS，所以 **不按运营商换 DNS 服务商**；运营商只影响 IPv6、MTU、UDP 质量这类「网络特性」提示。
2. **DNSPod 的 IP 形式 DoH（1.12.12.12 / 120.53.53.53）已被官方建议弃用**（2024-09-29 公告，暂未下线），改用 `https://doh.pub/dns-query`。v1.7.0 默认的国内 DoH 由 `223.5.5.5 + 1.12.12.12` 改为 `223.5.5.5 + doh.pub`。
3. **域名形式 DoH 需要 bootstrap DNS**：mihomo 的 `default-nameserver` 只能写纯 IP（官方文档）；sing-box 1.12 起用 `domain_resolver` 取代已弃用的 `address_resolver`（旧写法在 1.14 移除）。新增「Bootstrap DNS」选项（默认 223.5.5.5、119.29.29.29）。
4. **IPv6**：三大运营商骨干 / 城域网 / 4G 已全面部署 IPv6，新增家庭宽带默认开启；截至 2025-09，IPv6 活跃用户占网民 77.02%，家庭网关开启率 96.86%（官方数据）。因此国内设备多半有 IPv6，而很多机场节点没有 IPv6 出口，AAAA 会绕过代理。默认仍「关闭 IPv6」，仅在节点与网络都支持时手动打开。
5. **明文 DNS 有被运营商劫持 / 污染的实证**（USENIX Security 2018 的测量论文；近年社区帖子也有按目标 IP 劫持公共 DNS 的报告，见下），所以国内、境外 DNS 都用 DoH/DoT；`respect-rules` 让境外 DoH 经代理发出。DoH 本身也可能被阻断，因此保留「国内域名用系统 DNS」开关作为兜底。

## 新的环境模型（引擎 `recommend.ts`）
- **网络类型（可选）**：中国移动 / 电信 / 联通 宽带、中国广电宽带 / 5G、中国移动 / 联通 / 电信 手机流量、其他蜂窝、校园网、公司网络、海外网络、其他。**所在地**：大陆 / 香港 / 澳门 / 台湾 / 海外。
- 选定后「按环境智能推荐」会给出整套带依据的推荐（每项标注「官方 / 经验值 / 未核实」），可逐项再改。
- 新增可调项（只在客户端支持时输出，不跨平台混用）：
  | 选项 | 说明 | 输出到 |
  |---|---|---|
  | 国内 DNS 预设 | 阿里+腾讯（默认）/ 仅阿里 / 仅腾讯 / 360 / 自定义 | 所有客户端（国内 DoH） |
  | Bootstrap DNS | 解析 DoH 域名本身的纯 IP DNS | mihomo、Stash（`default-nameserver`）、sing-box（`dns-bootstrap` + `domain_resolver`）、Egern（bootstrap） |
  | 国内域名用系统 DNS | 国内域名 / 直连出口改用系统（运营商 / 校园 / 公司）DNS，节点域名仍用 DoH | mihomo、sing-box |
  | IPv6 | 既有开关；推荐文案按运营商补充官方数据 | 全部 |
- 未做：**ECS**。mihomo 可用 `#ecs=`、sing-box 可设 `client_subnet`，但把代理出口的网段发给国内 DNS 会让 CDN 解析到错误区域，把本机网段发给境外 DNS 又会暴露位置；没有可验证的通用最优值，所以生成的配置不发送 ECS（既有行为）。
- 未做：**按运营商内置运营商 DNS 地址**。各省运营商 DNS 地址不同且无统一官方清单，不能给出可验证的值；需要时请用「国内域名用系统 DNS」。

## 来源与可信度
| 结论 | 来源 | 日期 | 可信度 |
|---|---|---|---|
| 阿里公共 DNS 地址、DoH/DoT、ECS | https://alidns.com/ 、https://alidns.com/articles/6018321800a44d0e45e90d71 | 访问 2026-10-17（页面无日期） | 官方 |
| DNSPod 免费版 DoH `doh.pub`、DoT `dot.pub`，QPS 限制，无 SLA | 腾讯云《公共解析 Public DNS》文档 | 2024-09-27 更新 | 官方 |
| 不再公开 1.12.12.12 / 120.53.53.53 的 IP 接入，建议域名 | https://docs.dnspod.cn/notices/mian-fei-ban-dot-dohbu-zai-gong-kai-ipjie-ru-de-gong-gao/ | 2024-09-29 公告，2024-11-04 更新 | 官方 |
| 119.29.29.29 Anycast、与 16 家 ISP 互联、按省 / 运营商分区递归、ECS | https://docs.dnspod.com/public-dns/public-dns-introduction/ | 访问 2026-10-17 | 官方 |
| 360 DoH `https://doh.360.cn/dns-query` | https://sdns.360.net/dnsPublic.html | 访问 2026-10-17 | 官方（文档较少） |
| mihomo：`default-nameserver` 仅 IP、`proxy-server-nameserver`、`respect-rules` 需配合前者、ecs 写法 | https://wiki.metacubex.one/en/config/dns/ | 访问 2026-10-17 | 官方 |
| sing-box 1.12 `domain_resolver`、旧 DNS 服务器格式 1.14 移除 | https://sing-box.sagernet.org/migration/ | 访问 2026-10-17 | 官方 |
| Surge `encrypted-dns-server`（https / h3 / quic / tls）、`hijack-dns`、`ipv6` | https://manual.nssurge.com/dns/encrypted-dns.html 、https://manual.nssurge.com/profile/general.html | 访问 2026-10-17 | 官方 |
| IPv6 活跃用户 8.65 亿 / 77.02%，家庭网关开启率 96.86%，新增家宽默认开启 | 数字中国建设峰会 / 央视网 | 2025-10-30 | 官方 |
| IPv6 活跃用户 8.34 亿 / 75.29%（2025-06） | 中央网信办 https://www.cac.gov.cn/2025-08/1/c_1755590302116970.htm | 2025-08-01 | 官方 |
| 「网络去 NAT」专项、固网 IPv6 连通率目标 | 工信部办公厅 / 网信办秘书局通知 | 2024 | 官方 |
| 运营商劫持明文 DNS 的测量 | 《谁劫持了我的 DNS》USENIX Security 2018（奇安信技术研究院解读） | 2018（超过 2 年，仅作背景） | 学术 |
| 江苏电信劫持公共 DNS、DoH 能否被劫持的讨论 | V2EX 帖 1139109 / 1137767 | 无法确认日期 | 社区，未核实 |
| 校园网强制校内 DNS、放行 53 端口 | linux.do、校内论坛帖 | 无法确认日期 | 社区，未核实 |

## 仍未核实（不会作为事实写入默认值）
- 联通 / 电信对境外 UDP 的 QoS、联通国际方向大包丢失（MTU 1400 / 1380 只是经验起点，已标「经验值」）。
- 校园网 / 公司网络对 DoH、53 端口的具体限制。
- 各地运营商 DNS 与公共 DNS 的实际延迟差异。
