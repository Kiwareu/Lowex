# UI 设计说明

## 间距与层级
- 8pt 网格：`Space.xs/s/m/l/xl = 4/8/12/16/24`；页面水平边距 16、卡片内边距 16、卡片间距 12；最小点击区域 `Space.tap = 44`。
- 卡片层级：`HeroCard`（玻璃，每页最多 1–2 张）> `PlainCard`（柔和卡片）> 行内 `softCard`。
- 统一分区标题 `SectionHeader`（标题 + 说明）；字标 `Lowex` 为圆润 semibold、轻微负字距。

## 背景
- 自定义壁纸优先；否则 `MeshBackdrop`（iOS 18+ 用 `MeshGradient` 3×3，更早系统回退为径向渐变）。四个角点固定，内部 5 个控制点做缓慢漂移（约 20fps，速度由外观里的「渐变速度」控制）；减弱动态效果时 `TimelineView` 暂停，静止显示。深色模式用低亮度同色系。

## 展开 / 收起（根因见 CHANGELOG）
所有展开头用 `ExpandHeader`：整行 `contentShape(Rectangle())`、最小高度 44、`ChevronBadge`（圆底品牌色）、`Haptics.light()` + spring。按钮一律 `.buttonStyle(.plain)`，不再叠 `onTapGesture`。图标按钮用 `IconTapStyle`（≥44×44）。

## 启动动画
单一时间线：`appeared`（spring）→ 0.35s → `progress` 0→1（`timingCurve(0.45,0,0.2,1)`，1.9s）→ 等 Store 就绪 → 停顿 0.3s → 淡出 0.55s。字标填充 = 渐变文字 + `mask(Rectangle().scaleEffect(x: progress, anchor: .leading))`，进度条同理，只做变换。`Boot` 在后台线程解析 `engine.js`，再在主线程建 `Store`。减弱动态效果：0.25s 淡入、0.7s 停顿、0.25s 淡出。

## 启动页与首页显示
启动页背景 = `PinkBackground`（自带不透明底色，色值同 `LaunchBackground`），全屏含安全区；首页先布局但 `opacity 0`、不可点，动画结束后与启动页做淡入 / 淡出 + 轻微缩放。`UILaunchScreen` 用 `LaunchBackground` 颜色（浅 / 深）。

## 字标
`Lowex` 使用 Great Vibes（Robert Leuschke / The Great Vibes Pro Project Authors，SIL OFL 1.1，随 App 以 `UIAppFonts` 注册；许可证全文 `docs/brand/OFL-GreatVibes.txt`）。仅用于 Latin 字标 "Lowex"，名称不随语言变化。字体不可用时退回系统衬线斜体。

## Logo
手绘风 W 字标：马克笔质感的白色玻璃笔画，起笔与收笔各有一道书法式弧线，中间是一个小圆环，叠色处略深；暖橙粉渐变底，右上角一颗小星光。`AppIcon` 为 1024 全出血方图（系统自动套圆角），`BrandMark` 为 120 / 180 / 512 圆角版。由 `tools/brand/make_icon.py` 生成（同时输出 `docs/brand/lowex-icon.svg` 矢量版：扁平白色笔画，不含阴影与高光）。

## 未验证
没有在模拟器或真机运行过，以上动画、点击手感、帧率均未实测；背景在 iPhone XS 上的实际帧率也未测。

## v1.4 界面决策

- **列表密度**（`LayoutDensity`，存 `ap.density`）：单列平铺 = 原样；双列 = 服务分组 / 地区两列网格；紧凑 = 单行卡片（图标 22pt、出口菜单与开关同行）。**默认紧凑**：用户截图里一屏只看到约 3.5 个服务分组，选择状态难以记住；紧凑模式一屏约 8 个。已开启项在三种模式下都有品牌色底色 + 描边，不只靠开关。
- **规则页分区标签**：由等宽分段改为可横向滚动的胶囊（`ChipTabs`），高度约 28pt。
- **标语与版本**：从首页字标下方移走（字标下方空间紧、与「L」的尾巴抢位置），放到首页与「更多」页底部的页脚，并在「关于」顶部保留标语。
- **「更多」页**：外观与偏好（外观、语言、列表密度）/ 工具（防泄漏、模块、作者规则、备份）/ 关于（关于、免责声明、GitHub）。
- **首页「一键预设」与「生成选项」的顺序**：保持预设在前。`applyPreset` 会整体改写 `opts`，若放在生成选项之后，用户逐项调好的选择会被预设覆盖；先套预设、再微调才不会丢选择。预设卡片上加了一行提示说明这一点。
- **DNS**：`DnsListEditor` 提供常用服务器多选与自定义地址；`DnsValidator` 按客户端放行写法——mihomo / Stash / sing-box 可用 DoH、`tls://`（DoT）、纯 IP；Surge / Loon / Quantumult X / Egern / Shadowrocket 只接受 DoH（裸域名按 `https://域名/dns-query` 处理，IP 会提示改用 DoH）。海外 DNS 只在引擎声明支持 `dnsRemote` 的客户端显示。

## v1.4.1 调整

- 列表密度只在规则页切换（`LayoutPrefs`，独立小对象）；从「更多」与外观设置移除。之前它挂在 `Appearance.revision` 上，每次切换都会 `.id()` 重建整个界面树，是滚动卡顿的一个来源。
- 规则页性能：行 `GroupRow` 只吃值类型并 `.equatable()`；出口选择用一个 `confirmationDialog` 代替每行一个 `Picker(.menu)`；双列按对分行放进同一个 `LazyVStack`（不嵌套 `LazyVGrid`）；滚动期间 `ScrollActivity` 暂停背景网格渐变（15fps）。未做 Instruments 实测。
- 节点页地区分组：自适应宽度的胶囊网格，与规则页显示模式无关。
- DNS：本地 / 海外各一行摘要，点开弹层多选；自定义地址与 Bootstrap 在折叠的「高级」里，文案区分「服务器列表」「当前网络自带 DNS」「Bootstrap」三个概念。

## v1.4.2 一致性规则

- 同一模式下同一列表的所有行 / 格尺寸必须一致：`GroupRow` 固定行高（单列 60 / 紧凑 44 / 双列 84），详情在双列里用弹层而不是撑高格子；单列与紧凑下用户主动展开才会变高。
- 之前的混排原因：展开详情与「出口」菜单都在行内、行高随内容变化，且切换模式时已实例化的行保留旧样式；现在行高固定，行 id 带上模式，切换时整行重建。
- 网格统一用 `PairGrid`（两列、等宽等高、奇数时最后一格占满整行），用于地区分组与客户端选择。
- 服务分组显示顺序由 `RulesView.popularity` 决定，只影响界面，不影响引擎输出。

## v1.4.3 性能规则

- 列表行与普通卡片的玻璃感用 `GlassFill`（渐变 + 斜向高光描边的半透明叠层）实现，不做逐行实时模糊；只有每页一两张头部大卡片用真实材质。滚动路径上不放：带模糊半径的阴影、每行一个 UIKit 控件（UISwitch）、每个图标一层遮罩。
- 主要名称必须完整显示：行内次要控件（出口、箭头、星标、开关）缩小，名称允许两行。
- 背景动画只在可见标签页运行，滚动时暂停；性能模式下背景静止。
- 内置图标统一走 `IconCache.warm()`：120px 缩略图 + 预解码 + 圆角烘焙。
- 列表行是值类型 + `Equatable`；一次渲染里的共享数据（分组状态、收藏、分类）只取一次再传给各行。
- 自测：连点版本号 7 次打开帧率浮层。

## Wi-Fi 通话提示（v1.4.4）
首页选项区与「更多 → Wi-Fi 通话」卡片都显示 `WifiCallNote`：规则会生成，但能否生效取决于客户端、iOS、运营商与节点；sing-box 在手机上多一行提示。手机上 sing-box 系隐藏「本地端口 / 允许局域网」（`Store.supports`）。

## v1.5.0
- 规则页密度新增「按分类」：单列、行高与「单列平铺」一致，分类标题按 AI → 流媒体 → 社交 → 游戏 → 开发 → 办公 → 金融 … 排序（`RulesView.categoryOrder`，只影响界面）。
- 持久化：`Store.state` 变化 0.5 秒后写入 UserDefaults；订阅与粘贴的节点单独写到沙盒私有文件 `nodes-private.json`（`LocalFile`，不上传、不进设备备份）；进入后台立即写盘。
- 历史记录：`HistoryStore`（`history.json`，最多 60 条 × 20 版本）；备份 v2 含 `state` / `prefs` / `history`。
- 导出：一律用 `UIDocumentPickerViewController(forExporting:)` + 带扩展名的临时文件（不用 `fileExporter`，原因见 CHANGELOG v1.5.0）。
