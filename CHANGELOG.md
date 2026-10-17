# Changelog

## v1.2.0

系统要求 iOS 18 及以上。

- **客户端研究**：逐个客户端核对订阅 / 节点放置、导入方式与备份能力（[docs/CLIENTS.md](docs/CLIENTS.md)）；Clash 系 GUI 支持「写入配置」或「客户端内添加」。
- **故障转移与防泄漏**：按各客户端官方文档审计策略组类型，只生成真正支持的；按基准研究补强 DNS / 防泄漏，并给出有依据的防泄漏评分（[docs/BENCHMARKS.md](docs/BENCHMARKS.md)）。
- **网络环境**：按运营商、网络类型、所在地给出 DNS / DoH、Bootstrap DNS、IPv6、MTU、QUIC 推荐（[docs/NETWORK-ENV.md](docs/NETWORK-ENV.md)）。
- **多语言**：简体中文 / 繁體中文（台灣、香港）/ English，默认跟随系统。
- 内置 97 张服务 / 地区图标；设置备份与恢复；完整预览与一键清除配置；展开 / 收起与点击响应修复。

## v1.1.0

系统要求 iOS 18 及以上。

- **核心生成器**：14 个客户端，Windows / iOS / Android 三平台，75 个服务分组，智能推荐。
- 按客户端能力显示选项，不支持的灰显并说明，生成时自动省略。
- **节点页**：订阅 URL、节点链接 / Base64、手动节点（SOCKS5 / HTTP / HTTPS，密码存钥匙串）分开输入。
- **节点放置**：Quantumult X、Shadowrocket 可选「写入配置」或「客户端内添加」。
- **导出**：复制、分享、保存到「文件」、二维码、URL scheme 导入；外观主题与触感反馈。
