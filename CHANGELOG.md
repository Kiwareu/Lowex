# Changelog

## Unreleased

- 订阅历史记录 + 清空二次确认（分支 `feat/upgrade-98`，未合并到 main）：
  - 节点页订阅卡片新增「历史记录」区：用户贴过的订阅 URL 自动记入历史（UserDefaults 持久化，最多 30 条、最新在前、按字符串去重，无论客户端家族都记录）；历史逐条可删除，也可点一条恢复导入到上方订阅列表（已在列表中的显示「已添加」且整行禁用）。
  - 「清空订阅」「清空历史」均加二次确认弹窗，杜绝误触一下全删；清空订阅不影响历史记录。

- 远程 JS「脚本库」分享区（分支 `feat/upgrade-98`，未合并到 main）：
  - 新增 `engine/src/engine/remoteJsLibrary.ts`：三种类型按客户端 gating——config-overwrite（JS 配置覆写，仅 Party/Verge/FlClash）、http-rewrite（HTTP 重写 .js，仅 Surge/Loon/QX/Shadowrocket/Stash）、config-override（覆写配置链接 .yaml；经核实支持 merge 键 prepend-rules/append-rules 等的 Mihomo 系：clashmi/verge/clashparty/flclash；Stash 的 Override 用另一套语法暂不收录；Surge/Loon/QX/Shadowrocket 等价机制未核实留空）。
  - 种子只放两类：本仓库 `remote-scripts/` 自建（raw 链接，SHA256 待合并到 main 后填入）+ 一个格式示例空条目；绝不硬编码任何未核验的第三方 URL。4 条种子：Mihomo DNS 防泄漏加固覆写（.js）、Surge 系空重写脚本（.js）、Mihomo 覆写配置（.yaml：DNS 防泄漏整段 + fallback 精确化注释 + 规则骨架，基于 Lowex 9.8+ 分析优化）、示例分享条目。
  - 新增 `remote-scripts/mihomo-dns-leak-fix.js`（只补缺不覆盖，绝不碰 IPv6 与已有规则）、`remote-scripts/surge-noop.js`（$done({}) + [Script]/[MITM] 片段示例）、`remote-scripts/mihomo-override-dns-rules.yaml`（DNS 整段 + health-check/精确 fallback 注释说明 + 注释掉的 prepend-rules 示例；无真实节点/订阅）。
  - App「远程 JS」页新增第四张卡片「脚本库」：每行显示类型与「原创/分享·作者」徽标；可复制链接、复制来源标注；.js 行在 SHA256 已锁定时可「填入引用」；config-override 行只给复制链接/来源标注（在代理软件的「覆写/Override」里添加配置链接，不走 App 校验）；未哈希锁定的分享条目显示橙色提示；分支未合并的条目提示“待分支合并到 main 后链接生效”；可「添加我的收藏」（类型三选，url 按类型校验 https + .js / .yaml/.yml）。
  - 入口新增 `remoteJsLibrary` / `remoteJsLibraryAttribution`；`Engine.swift` 加同名桥接；`Store.swift` 加 `libraryCustom`（UserDefaults `lowex.library.custom.v1`）。
  - 版本号保持 1.6.0 / Build 47，未 bump。

## v1.6.0 — 2026-10-20

9.8+ 升级（分支 `feat/upgrade-98`，全部改动在该分支上，未动 main）：

- 安全：`prelude.js` 的 `crypto.getRandomValues` 改用原生 `SecRandomCopyBytes` 注入的真随机，无可信随机源时直接抛错，绝不回退 `Math.random`（`Engine.swift` 新增 `installSecureRandom`）。
- 校验器：`validate.ts` 首次被接入（之前是死代码），入口新增 `validateConfig`；同步 Surge / Loon / Shadowrocket `[General]` 白名单与 Egern `https` 节点类型；新增 fallback / 健康检查 / TUN / STUN 断言。
- 地区正则：`regions.json` 为唯一源，OT 改为 `(?i)` + 全量关键词镜像（修小写 hk/us/eu 误入“其他”）；INI 各家族删第二套 `SIMPLE_RE`，改用 `toPortableFilter` 做方言适配（lookbehind 展开为可移植写法）；回国正则统一到 `HOME_REGEX`。
- 分流：Mihomo 的 package 注释说明与 `PROCESS-NAME` 的关系（Android 默认进程名即包名；`plan.ts` 已按平台分流）；Surge / Loon / Shadowrocket 补 `PROCESS-NAME` 生成（之前静默丢弃），QX / Egern 丢弃时写明原因；Surge / Shadowrocket 的 macOS 开 `processRules`。
- sing-box / Egern 的 HTTP 出站 TLS SNI 改为 `n.sni ?? n.server`。
- 能力矩阵：QUIC / STUN 拆三档并经 `tiers()` 暴露；Egern 图标移除（未核实）；failover / tolerance / 节点过滤 / 本地端口 / 日志级别加边界注释；Shadowrocket STUN 补 Google 端口 19302–19309。
- Fallback 精确可靠：订阅 `health-check` 默认开（间隔 600 秒）；fallback 组 `lazy: false` + 间隔 ≤600 秒；默认测速间隔 1800 → 600 秒；预设同步。
- DNS：Mihomo 加 `fallback` + `fallback-filter`（只信任非 CN 答案，防投毒）。
- 分层预设 A/B：显式定义（A 有故障转移 / B 无故障转移），入口新增 `presetMode()`；sing-box 的 A 自动降级为地区-自动。
- 远程 JS 独立模块（`remoteJs.ts`，与生成配置互斥，不写进配置文件）：Mihomo 系配置级覆写（仅 Party / Verge Rev / FlClash）与 Surge 系 HTTP 重写（Surge / Loon / QX / Shadowrocket / Stash）分客户端 gating；仅 https + `.js` + SHA256 锁定 + 自建/受信源；MITM 最小范围，敏感域名需显式确认；付费绕过关键词拒绝；附自建模板。
- 各预设各自优化到最佳（`tools.ts` PRESETS，全在 `feat/upgrade-98` 上）：
  - 统一安全基线：未知域名走代理、IPv6 关、fake-ip + TUN 开、境外 QUIC 拦、STUN 走代理、广告 Lite + 追踪/遥测拦截、故障转移开、测速 600 秒、负载均衡关、局域网关；差异只在定位。
  - 修 `balanced` 之前是空操作（返回 `{groups:{}}`）：现在真正重置为全新方案默认开启的分组。
  - 修多数预设悄悄关掉广告/遥测/追踪器拦截（`only()` 会把未列出的组关掉，而 `opts.ads='lite'` 成了死配置）：现在各预设统一开拦截（REJECT）。
  - AI 预设：AI 组出口由 `R:US`（经故障转移，IP 会跳）改为 `R:US/m`（固定手动节点，防 AI 风控）。
  - 流媒体预设：补 `media-more`（Hulu / Crunchyroll 等）；开发者预设：补 `cloud-dev`（AWS / Azure / GCP / Vercel 等）。
  - 数字游民预设：删死条目 `line`（该分组已在 `groups.ts` 的 REMOVED 里，选了也不生效）；金融组出口固定 `R:DE/m`（之前按输入 state 的 regions 判断，输入通常没开 DE 会误取 SG，而预设本身会开启 DE）。
  - `all` 预设：补开广告/遥测/追踪器拦截（之前因 `category==='reject'` 被过滤，沿用旧状态）。
  - 分层预设 A：Surge / Loon / Shadowrocket / Egern 的故转组测速间隔钳到 ≤600 秒（之前直接用 `urlTestInterval`，设大了切换迟钝），与 Mihomo 一致。
- 打包：重新构建并提交 `native/Resources/engine.js`（IPA 构建直接用仓库内的该文件，不重新构建引擎）。

## v1.5.2 — 2026-10-18

- 修复：Mihomo 系 / Stash 配置里的「资源更新」组不再被隐藏，会正常显示在客户端面板主列表。
- 新增：规则页与生成提示说明「资源更新」组需先在客户端面板里选中具体节点（或「一键代理」）才会生效。

## v1.5.1 — 2026-10-17

- 文案调整。

## v1.5.0 — 2026-10-17

最新版本。系统要求 iOS 15.0 及以上。**未在真机测试；闭源客户端的导入行为只对照官方文档。**

- **历史记录**（更多 → 历史记录）：每次生成自动保存在本机；同一客户端 / 文件名重新生成或手动编辑记为新版本；可查看、复制、保存、分享、编辑、删除，并恢复当时的设置。
- **记住所有选择**：选项、分组、地区、客户端以及订阅与粘贴的节点都会保存（订阅 / 节点存在沙盒私有文件，不上传）；更多 → 恢复默认设置。
- **完整备份**：设置、订阅、节点、手动节点、外观偏好、历史一并备份；导入前先显示内容，再选「覆盖」或「合并」；带敏感信息提醒；兼容旧版备份。
- **保存到「文件」不再变成 .txt**：原因是 `fileExporter` 的动态类型（.yaml / .conf）不在文档声明的可写类型里，系统退回 .plainText；现改用文档选择器按文件 URL 导出，系统分享同样使用带扩展名的文件。
- **一键导入**：逐个核对各客户端 scheme（Clash Party 改 `mihomo://`，Surge / Stash 去掉未记载的 name，Shadowrocket 按手册不编码）；没有在线直链时 scheme 只能唤起 App，新增「用客户端打开文件」。QX 无整份配置 scheme。
- **规则页「按分类」**：第 4 种显示方式，单列、分类标题按常用度排序、行高一致、名称完整。
- **AI 分组**：「AI 更多」补入 Meta AI（含 Muse Spark）、Copilot、Perplexity、Character.AI、Hugging Face 等；新增「AI 智能体 / 编程助手」与「国内 AI（直连）」。
- 更正 v1.4.4：Egern DNS 转发匹配器应为 `domain_suffix` / `domain_wildcard`（官方 DNS 文档）。

## v1.4.4 — 2026-10-17

系统要求 iOS 15.0 及以上。**本版为能力审计与小提示；未在真机测试，闭源客户端的语法只对照官方文档 / 社区手册。**

- **Wi-Fi 通话提示**（四种语言）：规则已支持并会写入配置，但能否生效取决于客户端、iOS 版本、运营商和节点；sing-box 在 iOS 上额外提示。
- **全客户端能力审计**：Stash 选了 QUIC 却不生成 → 现在生成；Stash 补上 STUN；Loon 重复写出 `disable-stun` → 只写一次；Shadowrocket 去掉文档里没有的 `dns-fallback-system`；Egern DNS 转发改用文档示例的 `wildcard` 匹配；sing-box 在手机上没有本地端口 / 局域网入站，对应选项不再显示。
- 新增能力矩阵自检：每个选项「声明支持 ⇔ 改动后生成物确实变化」，并检查各客户端规则类型不越界。

## v1.4.3 — 2026-10-17

系统要求 iOS 15.0 及以上。**本版以性能与排版为主；未在真机测量。**

- **规则页服务名不再被截断**：出口菜单挪到名称右侧的紧凑小标签，箭头 / 星标 / 开关缩小；名称最多两行并自动缩放，双列模式名称占满单元格宽度。节点页地区名同样允许两行。
- **玻璃质感保留并加强**：卡片和列表行改用渐变高光 + 斜向描边的半透明叠层（不做逐行实时模糊），每页顶部的大卡片保留真实模糊；整体更通透。
- **滚动性能排查与修复**：只让当前标签页的背景动画运行（之前五个标签页各跑一份）；规则行开关改成轻量绘制；内置图标启动时后台预解码、缩放并烘焙圆角；底栏渐隐改成纯渐变；滚动监听不再每帧创建定时任务；规则页每次渲染只读取一次分组状态。
- **性能模式**（更多 → 自定义外观与主题）：关闭背景动画并用更轻量的叠层，外观几乎不变；iPhone XS 等较旧机型默认开启。
- 设置标题改为「自定义外观与主题」，去掉括号说明。
- 连点「版本」7 次可显示 / 隐藏帧率浮层（CADisplayLink），用来在真机上自测。

## v1.4.2 — 2026-10-17

系统要求 iOS 15.0 及以上。

- **规则页显示模式统一**：单列 / 双列 / 紧凑下，所有分组行尺寸一致；双列模式点名称或 ⓘ 弹出详情，不再撑乱布局。
- **按常用度排序**：AI、Telegram、YouTube、Netflix、Google、Apple、Microsoft、Discord 等在前，小众的在后（只影响显示顺序，不影响生成结果）。
- **节点页地区分组**改为两列等尺寸大卡片，数量为奇数时最后一项占满整行。
- **界面一致性检查**：客户端选择、导出按钮等网格统一尺寸；步骤标签、DNS 摘要等文字防截断；收藏按钮点按区域加大。
- 客户端名称统一显示为 Shadowrocket。

## v1.4.1 — 2026-10-17

系统要求 iOS 15.0 及以上。

- **规则页更顺滑**：切换显示模式不再重建整个界面；滚动时暂停背景动画；每行只在自身变化时重绘；出口选择改为统一弹窗，不再每行一个菜单。
- **节点页地区分组**用自己的自适应胶囊布局，不再跟随规则页的显示模式；列表密度只在规则页切换，「更多」页和外观设置里不再重复。卡片整体收紧。
- **DNS 区域整理**：国内 / 海外各一行，点开再多选常用服务器；「改用当前网络自带 DNS」单独一项并说明；自定义服务器与 Bootstrap（只用来解析 DoH / DoT 服务器自己的域名）放进折叠的「高级」。
- **免责声明重写**：措辞改为中性（适用于用户所在地的法律法规），补充无担保、责任限制、第三方内容、隐私、AI 辅助开发与测试说明、许可；应用内与 DISCLAIMER.md（简 / 繁 / 英）一致。

## v1.4.0 — 2026-10-17

系统要求 iOS 15.0 及以上。

- **列表密度**：规则与节点页新增「单列平铺 / 双列 / 紧凑」，默认紧凑，一屏能看到更多选项；开启的项有底色和描边，三种模式下都清楚。「更多」页和外观设置里也能切换。
- **更小更圆的标签**：规则页顶部分区改为可横向滚动的胶囊标签，卡片内边距也收紧。
- **DNS**：勾选常用服务器（国内：阿里、腾讯 DNSPod、360；海外：Cloudflare、Google、Quad9、AdGuard），或自己添加地址；按当前客户端能用的写法校验，不支持的写法会提示而不会写进配置。
- **「更多」页整理**：分为外观与偏好 / 工具 / 关于三组；标语「本机生成 · 不上传」与版本移到页脚，不再挤在首页字标下面。
- 首页「一键预设」保持在「生成选项」之前，并注明预设会改写下面的选项。

## v1.3.0 — 2026-10-17

系统要求 iOS 15.0 及以上。

- **支持 iOS 15 及以上**：导航、相册选图、背景渐变、材质等在旧系统上自动回退（详见 [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md)）。
- **全新外观**：新图标；首页手写签名风格字标；启动页重做——全屏不透明、玻璃胶囊进度条，与系统启动屏同色、无闪屏，整段约 1 秒。
- 节点页「节点放在哪里」改为可换行的按钮组，小屏与大字号下完整显示；「关于」页重写，界面版本只显示 `v1.3` 形式。
- 项目整理：补全 README（简体 / 繁體 / English）、行为准则、PR 模板，清除不必要的个人信息；发布资产命名为 `Lowex-vX.Y.Z.ipa` 并附 `.sha256`。

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
