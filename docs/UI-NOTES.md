# UI 设计说明（v1.7.0）

## 间距与层级
- 8pt 网格：`Space.xs/s/m/l/xl = 4/8/12/16/24`；页面水平边距 16、卡片内边距 16、卡片间距 12；最小点击区域 `Space.tap = 44`。
- 卡片层级：`HeroCard`（玻璃，每页最多 1–2 张）> `PlainCard`（柔和卡片）> 行内 `softCard`。
- 统一分区标题 `SectionHeader`（标题 + 说明）；字标 `Lowex` 为圆润 semibold、轻微负字距。

## 背景
- 自定义壁纸优先；否则 `MeshBackdrop`（iOS 18 `MeshGradient` 3×3）。四个角点固定，内部 5 个控制点做缓慢漂移（约 20fps，速度由外观里的「渐变速度」控制）；减弱动态效果时 `TimelineView` 暂停，静止显示。深色模式用低亮度同色系。

## 展开 / 收起（根因见 CHANGELOG v1.7.0）
所有展开头用 `ExpandHeader`：整行 `contentShape(Rectangle())`、最小高度 44、`ChevronBadge`（圆底品牌色）、`Haptics.light()` + spring。按钮一律 `.buttonStyle(.plain)`，不再叠 `onTapGesture`。图标按钮用 `IconTapStyle`（≥44×44）。

## 启动动画
单一时间线：`appeared`（spring）→ 0.35s → `progress` 0→1（`timingCurve(0.45,0,0.2,1)`，1.9s）→ 等 Store 就绪 → 停顿 0.3s → 淡出 0.55s。字标填充 = 渐变文字 + `mask(Rectangle().scaleEffect(x: progress, anchor: .leading))`，进度条同理，只做变换。`Boot` 在后台线程解析 `engine.js`，再在主线程建 `Store`。减弱动态效果：0.25s 淡入、0.7s 停顿、0.25s 淡出。

## 启动页与首页显示（v1.8.0）
启动页背景 = `PinkBackground`（自带不透明底色，色值同 `LaunchBackground`），全屏含安全区；首页先布局但 `opacity 0`、不可点，动画结束后与启动页做淡入 / 淡出 + 轻微缩放。`UILaunchScreen` 用 `LaunchBackground` 颜色（浅 / 深）。

## 字标
`Lowex` 使用 Great Vibes（Robert Leuschke / The Great Vibes Pro Project Authors，SIL OFL 1.1，随 App 以 `UIAppFonts` 注册；许可证全文 `docs/brand/OFL-GreatVibes.txt`）。仅用于 Latin 字标 "Lowex"，名称不随语言变化。字体不可用时退回系统衬线斜体。

## Logo
地球形 O（经纬网格，玻璃质感）+ 网络节点式 W + X 形星光，居中，网格渐变底（粉 / 紫 / 橙）；源文件 `docs/brand/lowex-icon.svg`；`AppIcon` 为 1024 全出血方图（系统自动套圆角），`BrandMark` 为 120 / 180 / 512 圆角版。由 SVG 经 cairosvg 渲染（`tools/render-icon.py`）。

## 未验证
没有在模拟器或真机运行过，以上动画、点击手感、帧率均未实测；背景在 iPhone XS 上的实际帧率也未测。
