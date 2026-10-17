# Changelog

## v1.3.0 — 2026-10-17

首个正式版本，汇总了目前为止的全部功能。

### 生成与客户端
- 14 个客户端：Clash Verge Rev、FlClash、Clash Mi、Clash Meta for Android、Mihomo Party、Mihomo 内核、sing-box、Karing、Surge、Quantumult X、Shadowrocket、Loon、Stash、Egern；逐个核对订阅 / 节点放置方式、导入方式与备份能力（见 [docs/CLIENTS.md](docs/CLIENTS.md)）。
- 按平台输出：Windows / iOS / Android 各自只含有效规则（Windows 仅 `.exe` 进程名，Android 仅包名，iOS 无进程 / 包名）。
- 75 个服务分组：AI、流媒体、社交、开发、银行与券商、跨境账户、远程工作、数字游民工具、加密货币等。
- 故障转移：每个地区「手动 / 自动测速 / 故转」；按各客户端官方文档只生成它真正支持的策略组类型（sing-box 仅 selector / urltest，Loon 与 Quantumult X 不嵌套策略组等）。
- 防泄漏：fake-ip DNS、嗅探、QUIC / STUN 拦截、可选的广告 / 追踪 / 遥测拦截；基准研究见 [docs/BENCHMARKS.md](docs/BENCHMARKS.md)。
- 网络环境：中国广电 / 三家运营商手机流量等网络类型；国内 DoH 预设与 Bootstrap DNS；按依据给出 IPv6 / MTU / QUIC 推荐（[docs/NETWORK-ENV.md](docs/NETWORK-ENV.md)）。
- 手动节点：SOCKS5 / HTTP / HTTPS，密码存钥匙串，按客户端语法输出。
- 一键预设；导出：复制、分享、保存到「文件」、二维码、URL scheme 导入。

### 应用
- **支持 iOS 15 及以上**：导航、相册选图、背景渐变、材质等在旧系统上都有兼容实现（[docs/COMPATIBILITY.md](docs/COMPATIBILITY.md)）。
- 界面语言：简体中文 / 繁體中文（台灣、香港）/ English，默认跟随系统，可在应用内切换。
- 外观：浅色 / 深色、强调色、圆角、玻璃强度、渐变速度、字体、自定义壁纸；触感反馈；尊重「减弱动态效果」。
- 启动页：全屏不透明背景（与系统启动屏同色，无闪屏）、手写签名字标与玻璃胶囊进度条；首页在下面先布局好，动画结束后淡入。
- 首页顶部：手写签名风格字标（Great Vibes，SIL OFL 1.1）随屏宽铺满，副标题紧凑排布。
- 全新图标：手绘风 W 字标，马克笔质感，起笔与收笔带书法式弧线。
- 节点页「节点放在哪里」改为可换行的按钮组（「写入配置」/「客户端内添加」），小屏与大字号下完整显示。
- 备份与恢复、内置 97 张服务 / 地区图标、「关于」页介绍应用本身与工作方式。

### 工程
- SwiftUI + TypeScript 引擎（JavaScriptCore）；mihomo `-t` / `sing-box check` 校验与随机选项模糊测试；`tools/check-i18n.py` 检查语言表。
- 发布资产命名为 `Lowex-vX.Y.Z.ipa`，附 `.sha256`。
