# 系统要求与兼容性 / Compatibility

**Lowex 最低支持 iOS 15.0。**

## 为什么是 iOS 15

同类代理客户端在 App Store 上标注的最低系统（2026-10-17 查询）：

| 客户端 | 最低 iOS | 来源 |
|---|---|---|
| Shadowrocket | 13.0 | <https://apps.apple.com/us/app/shadowrocket/id932747118> |
| sing-box（SFI） | 15.0 | <https://sing-box.sagernet.org/clients/apple/> |
| Karing | 15.0 | <https://apps.apple.com/us/app/karing/id6472431552> · <https://karing.app/en/download> |
| Stash | 16.0 | <https://apps.apple.com/us/app/stash-rule-based-proxy/id1596063349> · <https://stash.ws/ios> |
| Surge 5 | 17.0 | <https://apps.apple.com/us/app/surge-5/id1442620678> |

Lowex 选择 iOS 15.0：覆盖面与 sing-box / Karing 相当，同时 SwiftUI 的主要 API（`.task`、`.refreshable`、`.searchable`、`Material` 等）已可用，兼容代价可控。更低的版本（iOS 13 / 14）需要重写大量 SwiftUI 代码，不在计划内。

## 旧系统上的降级

较新的系统 API 全部集中在 `native/Sources/Compat.swift` 与 `Theme.swift` 里做可用性判断：

| 功能 | 新系统 | iOS 15 回退 |
|---|---|---|
| 导航 | `NavigationStack`（iOS 16+） | 单列 `NavigationView` |
| 背景渐变 | `MeshGradient`（iOS 18+） | 四团缓慢漂移的径向渐变 |
| 玻璃卡片 | 系统 Liquid Glass（iOS 26+） | 系统模糊材质 `Material` |
| 相册选图 | `PhotosPicker`（iOS 16+）→ 统一改用 `PHPickerViewController`（iOS 14+） | 同左 |
| 全局字体风格 | `fontDesign`（iOS 16.1+） | 系统默认字体 |
| 半高弹窗 | `presentationDetents`（iOS 16+） | 全高弹窗 |
| 键盘随滚动收起 | `scrollDismissesKeyboard`（iOS 16+） | 点空白收起 |
| 列表 / 编辑器透明背景 | `scrollContentBackground`（iOS 16+） | 全局 appearance 清除背景 |
| 底部留白与回弹 | `contentMargins` / `scrollBounceBehavior`（iOS 17+） | 底部安全区留白 |
| 备份分享 | 系统分享面板 | 同左（不再用 iOS 16 的 `ShareLink`） |
| 触感反馈 | `UIImpactFeedbackGenerator` 等（iOS 10+） | 同左 |

JavaScriptCore（运行规则引擎）在所有受支持的系统上都可用。

## 验证状态

- **编译**：CI 以 iOS 15.0 为部署目标，用最新 Xcode 编译通过。
- **运行**：作者在 iOS 18 设备上测试。iOS 15–17 **没有逐版本的真机 / 模拟器测试**，只做过编译验证与代码层面的降级处理；iOS 26 的 Liquid Glass 路径同样没有真机验证。
- 发现旧系统上的问题请到 Issues 反馈，并注明系统版本与设备。

## 安装方式与系统

- IPA 未签名。TrollStore 官方支持 iOS 14.0–16.6.1、16.7 RC（20H18）和 17.0；其他系统请用 AltStore、Sideloadly、Feather 等侧载工具自行签名。
