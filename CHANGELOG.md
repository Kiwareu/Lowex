# Changelog

## v1.5.2 (build 16)
App 内显示 `v1.5 (build 16)`。
- **账号改名**：GitHub 账号 `wenxu184` → **Kiwareu**。仓库现为 [Kiwareu/Lowex](https://github.com/Kiwareu/Lowex)、[Kiwareu/Lowex-Icons](https://github.com/Kiwareu/Lowex-Icons)。App 内的 GitHub 链接、生成配置里的图标地址（`raw.githubusercontent.com/Kiwareu/Lowex-Icons/main/icons/<文件名>.png`）、文档、图标仓库说明全部改为新名，不依赖 GitHub 的旧名重定向。
- 历史提交保留旧作者名 `wenxu184`；之后的提交使用 Kiwareu 的 GitHub noreply 邮箱。

## v1.5.1 (build 15)
App 内显示 `v1.5 (build 15)`。
- **根因**：v1.5.0 的图标只是网络地址，App 靠 raw.githubusercontent.com 下载；国内网络下容易失败或被缓存了旧的占位图 / 旧图，规则页就显示成灰色占位或旧的 ¥ 银行图标。引擎给出的组 id 和图标地址本身是对的（已逐个核对）。
- **修复**：97 张图标（75 个服务组、3 个核心组、8 个特殊组、11 个地区旗帜）缩成 192px 打进 App（`BundledIcons/`），内置图优先、离线即时显示；升级时自动清掉旧图标缓存。
- 剩余用上游图标的 48 个服务组（ChatGPT、YouTube、Netflix… 以及通用的加密货币、游戏、影音、学术、PT 等）全部按统一风格重绘；品牌类用 Simple Icons（CC0）矢量为底，Simple Icons 没有的品牌（AI 服务、Disney+、Prime Video、LinkedIn、Nintendo、Xbox、Microsoft、OneDrive、Slack、Amazon）为手绘简化版。
- 所有图标统一为 `https://raw.githubusercontent.com/Kiwareu/Lowex-Icons/main/icons/<文件名>.png` 并写进生成的配置（文件名：组 id；特殊组 `s-<名>`；地区 `region-<ID>`）。

## v1.5.0 (build 14)
App 内显示 `v1.5 (build 14)`。
- 补齐 27 个服务组图标并上传 [Lowex-Icons](https://github.com/Kiwareu/Lowex-Icons)：bunq、SumUp、WhatsApp、HSBC、暴雪战网、X（Twitter 组）、Meta 以 Simple Icons（CC0）矢量为底重绘；Maya、Kraken、Bybit、MEXC、Bitget、Blackcat 为手绘简化版（非官方原图）；fintech / 远程工作 / AI 更多 / 社交更多 / 购物更多 / 隐私 / 国内银行直连及各类银行、券商、数字游民工具为分类通用图标（银行类不再带货币符号）。统一 512×512 圆角方块。
- App 内置这些组 id，生成的配置直接引用 `https://raw.githubusercontent.com/Kiwareu/Lowex-Icons/main/icons/<组 id>.png`。
- 详见 [`docs/ICONS-TODO.md`](docs/ICONS-TODO.md)。

## v1.4.0 (build 13)
App 内显示 `v1.4 (build 13)`。
- **故障转移逐客户端核对**（官方文档，见 [`docs/CLIENTS.md`](docs/CLIENTS.md) 的「策略组类型与故障转移」）：Mihomo 系、Stash、Surge、Egern 支持 fallback；Loon 的 fallback 只能放节点 / 远程节点，已改写；小火箭、Quantumult X 改用 `policy-regex-filter` / `server-tag-regex` 成员；**sing-box 只有 selector / urltest，没有 fallback**，v1.3 及以前输出的「故转」组其实不会故障转移，现已去掉，该客户端不再显示故障转移选项。
- 生成页：预览显示**完整**配置（UITextView，等宽、可滚动、可选择）；新增「清除配置」：只清生成结果，或重置选项（保留节点 / 订阅）。
- 关于页（及「更多」页）加 GitHub 项目链接。
- 图标全量核对（75 个组 + 12 个地区）：Bunq / SumUp / Maya 等错图改占位图；新建公开仓库 [Lowex-Icons](https://github.com/Kiwareu/Lowex-Icons)，按 `<组 id>.png` 上传后 App 启动时自动采用。待办见 [`docs/ICONS-TODO.md`](docs/ICONS-TODO.md)。

## v1.3.0 (build 12)
App 内显示 `v1.3 (build 12)`。
- 对照 GitHub 高星配置、官方文档、博主文章（含 YouTube / X 公开内容）做了基准研究，来源、许可证和学到的东西见 [`docs/BENCHMARKS.md`](docs/BENCHMARKS.md)；只学结构，规则集仍以 URL 引用，不复制 GPL / CC-BY-SA 内容。
- 各客户端补强：Surge（`ipv6-vif`、`hijack-dns`、`always-real-ip`）、Shadowrocket（`dns-fallback-system=false`、`dns-direct-system=false`、`hijack-dns`、`always-real-ip`、`icmp-auto-reply`、`stun-response-ip`）、Quantumult X（`no-system`）、Loon（`sni-sniffing`、拦截 STUN 时 `disable-stun`）、sing-box / Karing（TUN `stack: mixed`、DNS `reverse_mapping`）。
- 防泄漏检查：每项都从生成出的配置文本里取证，新增综合分（0–100）；找不到对应字段就如实降级，客户端本身没有的开关不会被「补分」。
- 校验：mihomo 1.19.32 `-t` 与 sing-box 1.14.3 `check` 通过 10 份默认输出 + 120 份随机选项输出；闭源客户端按文档核对，未做真机导入。

## v1.2.0 (build 11)
App 内显示 `v1.2 (build 11)`。
- **先调研再设计**：逐个客户端核对「App 内添加订阅/节点」「配置导入」「备份/同步」「覆写机制」，结果、来源 URL、置信度（high/medium/low）和「未核实」清单写进 [`docs/CLIENTS.md`](docs/CLIENTS.md) 与机器可读的 [`docs/clients.research.json`](docs/clients.research.json)。
- **纠错**：此前 v1.1 认为 Clash Mi 等客户端不能在 App 内添加订阅——错误。Clash Mi（添加配置链接/剪贴板/扫码/文件）、Clash Verge Rev、FlClash、Clash Meta for Android、Clash Party 都可以。Shadowrocket 的 conf 确实不能携带订阅（只可带本地节点），Surge/Loon/Stash/Egern/sing-box/Karing 的 App 内添加与配置是同一份数据，所以仍只提供「写入配置」。
- 「节点放在哪里」选择扩展到所有 Mihomo 系 GUI 客户端（Verge Rev、FlClash、Clash Mi、CMFA、Clash Party）：选「在客户端 App 内自己添加」时输出**覆写用 YAML**（不含订阅/节点，策略组用 `include-all` + 地区正则收纳），按各客户端的覆写入口给出导入步骤。
- 导入步骤按「客户端 × 放置方式」分别显示；首页显示该客户端的资料可信度。
- 新增「备份与恢复 Lowex 设置」：导出/导入/分享本地 JSON（订阅链接永不写入；手动节点需手动勾选）。
- 已知未核实：Clash Mi 等「自定义覆写」对 proxy-groups / rules 是替换还是合并，官方文档未写明，未在设备上实测；如覆写后分组异常请改用「写入配置文件」。

## v1.1.0 (build 10)
版本规则：此前的内部 3.6 版本线（build 5–8）统一记为 **v1.0.x**；本次为 **v1.1**，App 内显示 `v1.1 (build 10)`。
- 节点页按客户端能力显示三块并从上到下排列：① 订阅链接 URL（一行一个，可逐条删除）② 节点链接 / Base64 ③ 手动添加节点（SOCKS5 / HTTP / HTTPS）。客户端写不出的区块直接隐藏，只留一行小字说明（小火箭隐藏订阅与链接；sing-box / Karing 隐藏订阅区）。填写内容在生成时自动写入配置对应位置。
- 同时支持两种放置方式的客户端（Quantumult X、小火箭）在节点页提供「写入配置文件 / 在客户端 App 内自己添加」选择：选后者时配置不含订阅与节点（含手动节点），分组按名称正则收纳；其余客户端只能写入配置，页面上有一行小字说明。
- 首页：当前客户端不支持的选项合并成一行小字提示，不再逐个占位。
- 版本号改为 1.1.0；发布流程只在 tag 构建里上传 Release 附件，避免旧构建覆盖。


## v1.0.0 — 首次公开发布 / First public release
对应旧内部版本 3.6.0（build 5–8），现统一记为 v1.0.x。

- Windows / iOS / Android 三平台配置生成，14 个客户端，按平台严格隔离规则（PROCESS-NAME `.exe` 仅 Windows，包名仅 Android，iOS 无）。
- 75 个服务分组，新增：汇丰 HSBC、香港银行 / 虚拟银行、新加坡银行、跨境商业账户、远程工作平台、券商、数字游民工具。
- 故障转移（手动 / 自动 / 故转）、防泄漏（fake-ip、嗅探、QUIC / STUN 拦截）、一键预设（数字游民、加密货币、通用防泄漏）。
- 生成页：复制、系统分享、保存到「文件」、二维码、客户端 URL scheme 导入。
- 外观：浅色 / 深色 / 跟随系统，强调色，圆角，玻璃强度，渐变速度，字体，自定义壁纸；启动动画与烟花（尊重「减弱动态效果」）。
- 首次启动免责声明；图标磁盘缓存。

**首发后修订（同一 v1.0.0，标签已更新）**：配置名称自动跟随所选客户端（手动修改后才固定）；切换系统 / 客户端时统一对齐状态（不支持的选项回默认、不适用的进程名 / 包名规则移除、旧结果与提示清空）；步骤指示改为真实完成状态；节点粘贴区不再把已有节点重复追加；订阅 URL 追加去重；旧版本状态升级时补默认选项；底部标签栏上方增加渐隐衬底与更大的内容下边距；深色模式输入框配色。

**build 7**：系统 / 客户端改为平铺大按钮（原菜单与分段控件易误触或无反馈）；首页与「关于」显示版本与 build；配置名带「自动 / 自定义」标记，未聚焦时始终显示当前自动名；升级时丢弃一切 `Lowex-<客户端名>` 形式的旧名称。

**build 8**：节点页拆为「订阅 URL / 节点链接与 Base64 / 手动节点」三块并按客户端说明行为；新增手动 SOCKS5 / HTTP / HTTPS 节点（可编辑 / 删除 / 开关，密码存钥匙串；Clash、sing-box、Surge、Shadowrocket、Loon、QX、Egern、Stash 各按官方写法输出，写不出的给出原因）；键盘「完成」按钮、点空白收起、滚动收起、Return 收起；全局触感反馈及设置开关。

内部版本映射 / Internal mapping: 3.5.x（Apple-only 预览）→ 3.6.0（多平台）= v1.0.x；v1.1.0 起 App 版本与 tag 一致。
