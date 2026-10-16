# 客户端与平台矩阵 / Clients & platforms

由引擎目录自动导出（v1.0.0）。App 界面只开放 Windows / iOS / Android 三个系统；macOS / Linux 客户端在引擎中保留。

| 客户端 | 内核族 | 平台 | 订阅写入配置 | 进程/包名规则 | 导出格式 |
|---|---|---|---|---|---|
| Clash Verge Rev | mihomo | Windows / macOS / Linux | 是 | 是（Windows .exe / Android 包名） | .yaml |
| FlClash | mihomo | Windows / macOS / Linux / Android | 是 | 是（Windows .exe / Android 包名） | .yaml |
| Clash Mi | mihomo | iOS / Android / Windows / macOS | 是 | 否 | .yaml |
| Clash Meta for Android | mihomo | Android | 是 | 是（Windows .exe / Android 包名） | .yaml |
| Mihomo Party / Clash Party | mihomo | Windows / macOS / Linux | 是 | 是（Windows .exe / Android 包名） | .yaml |
| Mihomo 内核（命令行/路由器） | mihomo | Linux / Windows / macOS / Android | 是 | 是（Windows .exe / Android 包名） | .yaml |
| sing-box | singbox | Windows / macOS / Linux / Android / iOS | 否 | 是（Windows .exe / Android 包名） | .json |
| Karing（sing-box 内核） | singbox | iOS / Android / Windows / macOS | 否 | 是（Windows .exe / Android 包名） | .json |
| Surge | surge | iOS / macOS | 是 | 否 | .conf |
| Quantumult X | qx | iOS | 是 | 否 | .conf |
| Shadowrocket（小火箭） | shadowrocket | iOS / macOS | 否 | 否 | .conf |
| Loon | loon | iOS | 是 | 否 | .conf |
| Stash | stash | iOS / macOS | 是 | 否 | .yaml |
| Egern | egern | iOS / macOS | 是 | 否 | .yaml |

分组数: 75，内置 App 库: 300 条


## 平台规则隔离 / Platform isolation
- **Windows**：仅此平台可出现 `PROCESS-NAME,xxx.exe`；不会出现包名。
- **Android**：仅此平台可出现 Android 包名规则；不会出现 `.exe`。
- **iOS**：没有进程名 / 包名规则，按应用分流自动退化为按域名或服务组。
- **Wi-Fi 通话规则**：只在 iOS / Android 生成。
- 同一内核（如 mihomo）在不同平台共享的是语法与通用规则，平台专属规则按所选系统裁剪。
- 订阅「写入配置」否 = 订阅 / 节点需在客户端内添加（Shadowrocket），或必须展开为节点（sing-box、Karing）。
