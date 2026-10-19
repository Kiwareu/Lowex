<p align="center">
  <img src="docs/brand/lowex-icon-rounded-1024.png" width="128" alt="Lowex">
</p>

<h1 align="center">Lowex</h1>

<p align="center">
  本机生成的代理 / 分流配置工具 · SwiftUI + TypeScript · 不联网、不上传
  <br>
  <sub>On-device proxy &amp; routing config generator for iPhone and iPad</sub>
</p>

<p align="center">
  <a href="https://github.com/Kiwareu/Lowex/releases/latest"><img alt="release" src="https://img.shields.io/github/v/release/Kiwareu/Lowex"></a>
  <img alt="platform" src="https://img.shields.io/badge/iOS-15%2B-pink">
  <a href="LICENSE"><img alt="license" src="https://img.shields.io/github/license/Kiwareu/Lowex"></a>
</p>

<p align="center">
  <b>简体中文</b> · <a href="README.zh-Hant.md">繁體中文</a> · <a href="README.en.md">English</a>
</p>

> **使用前请阅读 [DISCLAIMER.md](DISCLAIMER.md)。** Lowex 不提供任何节点、订阅或网络接入服务，也不鼓励任何违反当地法律的行为。

## 简介

Lowex 是一款运行在 iPhone / iPad 上的配置生成器：选好目标客户端和选项，粘贴你自己的节点或订阅，一键导出适合该客户端的配置文件（规则、策略组、DNS、防泄漏等）。所有生成都在本机完成，没有服务器，不上传节点或订阅。

## 功能

- **14 个客户端**：Clash Verge Rev、FlClash、Clash Mi、Clash Meta for Android、Mihomo Party、Mihomo 内核、sing-box、Karing、Surge、Quantumult X、Shadowrocket、Loon、Stash、Egern。
- **按平台输出**：先选 Windows / iOS / Android，再选客户端；输出只含该平台有效的规则（Windows 仅 `.exe` 进程名，Android 仅包名，iOS 无进程 / 包名规则）。
- **75 个服务分组**：AI、流媒体、社交、开发、银行与券商、跨境账户、远程工作、数字游民工具、加密货币等，可逐组开关与指定出口。
- **故障转移**：每个地区可选「手动 / 自动测速 / 故障转移」，并按各客户端文档只生成它真正支持的策略组类型。
- **防泄漏**：fake-ip DNS、嗅探、QUIC / STUN 拦截，可选的广告 / 追踪 / 遥测拦截。
- **网络环境**：按运营商、网络类型、所在地给出带依据的 DNS / DoH、Bootstrap DNS、IPv6、MTU、QUIC 推荐（依据见 [docs/NETWORK-ENV.md](docs/NETWORK-ENV.md)）。
- **手动节点**：SOCKS5 / HTTP / HTTPS（住宅 / 家宽代理），密码存系统钥匙串，按客户端语法输出（见 [docs/MANUAL-NODES.md](docs/MANUAL-NODES.md)）。
- **一键预设、完整备份与恢复**：数字游民、加密货币、通用防泄漏等预设；设置、订阅、节点、外观与历史记录可整体导出为 JSON，导入前确认「覆盖 / 合并」（备份含订阅与密码，请妥善保管）。
- **记住选择与历史记录**：所有选项、分组、地区、客户端、订阅与节点都会保存在本机（不上传），可一键恢复默认；每次生成的配置自动存入历史（含修改版本，可查看 / 导出 / 删除 / 恢复设置）。
- **导出**：复制、系统分享、保存到「文件」、二维码；多数客户端支持 URL scheme 导入（见 [docs/IMPORT-SCHEMES.md](docs/IMPORT-SCHEMES.md)）。
- **界面**：手写签名风格的字标、浅色 / 深色、强调色、圆角、玻璃强度、渐变速度、字体、自定义壁纸、触感反馈、规则页列表密度（单列平铺 / 双列 / 紧凑 / 按分类）；尊重「减弱动态效果」。
- **多语言**：简体中文 / 繁體中文（台灣、香港）/ English，默认跟随系统，可在 App 内切换（见 [docs/LOCALIZATION.md](docs/LOCALIZATION.md)）。

## 截图

| 首页 | 规则 |
|---|---|
| <img src="docs/screenshots/home.png" width="260"> | <img src="docs/screenshots/rules.png" width="260"> |

> 截图为 v1.3 界面，v1.4 起规则页新增列表密度，细节以实际版本为准。

## 支持的客户端

| 客户端 | 平台 | 导出格式 | 节点 / 订阅 |
|---|---|---|---|
| Clash Verge Rev / Mihomo Party | Windows · macOS · Linux | `.yaml` | 写入配置，或在 App 内添加 |
| FlClash | Windows · macOS · Linux · Android | `.yaml` | 写入配置，或在 App 内添加 |
| Clash Mi | iOS · Android · Windows · macOS | `.yaml` | 写入配置，或在 App 内添加 |
| Clash Meta for Android | Android | `.yaml` | 写入配置，或在 App 内添加 |
| Mihomo 内核 | Linux · Windows · macOS · Android | `.yaml` | 写入配置 |
| sing-box | Windows · macOS · Linux · Android · iOS | `.json` | 写入配置 |
| Karing | iOS · Android · Windows · macOS | `.json` | 写入配置 |
| Surge | iOS · macOS | `.conf` | 写入配置 |
| Quantumult X | iOS | `.conf` | 写入配置，或在 App 内添加 |
| Shadowrocket | iOS · macOS | `.conf` | 写入配置，或在 App 内添加 |
| Loon | iOS | `.conf` | 写入配置 |
| Stash | iOS · macOS | `.yaml` | 写入配置 |
| Egern | iOS · macOS | `.yaml` | 写入配置 |

逐客户端的调研、置信度与一手来源见 [docs/CLIENTS.md](docs/CLIENTS.md)。

## 平台与系统要求

- **运行 Lowex 的设备**：iPhone / iPad，**iOS 15.0 及以上**（与 sing-box、Karing 等客户端的最低要求相当；依据见 [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md)）。
- **生成的配置面向**：Windows / macOS / Linux / Android / iOS 上的各客户端。
- 作者日常在 iOS 18 设备上测试；iOS 15–17 目前只做过编译验证，没有逐版本的真机测试，遇到问题请提 Issue。

## 工作原理

- 全部在本机运行：没有服务器，不上传节点、订阅或生成结果；唯一的网络请求是可选的 App Store 搜索（iTunes Search API）和规则图标（已内置，另可从公开图标库补充）。
- 界面用 **SwiftUI** 编写；生成引擎是 **TypeScript**，打包成 `engine.js` 后在系统自带的 **JavaScriptCore** 里运行。
- 引擎按所选客户端的能力矩阵裁剪选项，生成后用各客户端的官方校验工具（mihomo `-t`、`sing-box check`）做回归测试。

## 安装

> Lowex 不在 App Store 上架，提供**未签名 IPA**。

1. 到 [Releases](https://github.com/Kiwareu/Lowex/releases) 下载最新的 `Lowex-vX.Y.Z.ipa`（旁边的 `.sha256` 文件可校验完整性）。
2. 安装方式任选：
   - **TrollStore**：在受支持的系统上（官方支持 iOS 14.0–16.6.1、16.7 RC、17.0）用 TrollStore 打开 IPA 安装。
   - **自行签名 / 侧载**：用 AltStore、Sideloadly、Feather 等工具，以你自己的 Apple ID 或证书签名后安装。
3. 校验：`shasum -a 256 -c Lowex-vX.Y.Z.ipa.sha256`。

## 使用

1. **首页**：选系统与客户端，选网络环境，按需套用预设。
2. **节点**：粘贴你自己的节点 / 订阅；对支持的客户端，可选择「写入配置」或「客户端内添加」。
3. **规则**：开关服务分组、设定出口，可按 App / 域名 / Wi-Fi 通话分流。
4. **生成**：生成后复制、分享、保存到文件、扫码，或用 URL scheme 一键导入。

## 从源码构建

需要 macOS、Xcode 与 Node.js。

```bash
cd engine && npm install && npm run build       # 生成 native/Resources/engine.js
cd ../native && brew install xcodegen && xcodegen generate
xcodebuild -project LowexNative.xcodeproj -scheme LowexNative -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO
```

> 正式 Bundle ID 为 `com.wenx.lowex`（见 `native/project.yml` 中的 `PRODUCT_BUNDLE_IDENTIFIER`）；旧的 `com.wenx.lowex.native` 已不再使用。

也可以直接运行 GitHub Actions 的 *Build Lowex IPA*（macOS runner，输出未签名 IPA）。

## 验证与测试

- 引擎的输出用 `mihomo -t` 与 `sing-box check` 校验，并对随机选项组合做模糊测试（IPv6 / TUN / fake-ip / 故障转移 / 广告拦截 / STUN / QUIC 等）。
- `python3 tools/check-i18n.py` 检查 4 张界面语言表是否齐全。
- 编译由 CI（macOS runner）验证；没有自动化的界面测试。

## 贡献

欢迎 Issue 与 PR，详见 [CONTRIBUTING.md](CONTRIBUTING.md) 与 [行为准则](CODE_OF_CONDUCT.md)。请不要在 Issue 里贴节点、订阅链接或令牌。

## 安全

漏洞请通过 GitHub 的 *Security → Report a vulnerability*（私密安全公告）提交，详见 [SECURITY.md](SECURITY.md)。

## 许可

[MIT](LICENSE)（仅适用于本仓库自有代码）。内置字体 Great Vibes 使用 SIL OFL 1.1，许可证见 [docs/brand/OFL-GreatVibes.txt](docs/brand/OFL-GreatVibes.txt)。第三方规则与图标来源见下。

## 免责声明

Lowex 与文中提到的任何客户端、服务、银行或平台均无隶属、授权或背书关系，相关名称与商标归其各自权利人所有。本软件按「现状」提供，不附带任何担保，作者与贡献者不承担使用后果；开发与测试使用了 AI 辅助工具，可能仍有错误，请自行验证生成结果。请遵守所在地适用的法律法规，详见 [DISCLAIMER.md](DISCLAIMER.md)。

## 更新日志

见 [CHANGELOG.md](CHANGELOG.md) 与 [Releases](https://github.com/Kiwareu/Lowex/releases)。

## 致谢与数据来源

Lowex 只在生成的配置里**引用**以下公开资源的 URL，不在本仓库内分发其内容，请遵循各自的许可：

- [MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat)（GPL-3.0）
- [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script)（GPL-2.0）
- [SagerNet/sing-geosite / sing-geoip](https://github.com/SagerNet)
- [ACL4SSR/ACL4SSR](https://github.com/ACL4SSR/ACL4SSR)（CC BY-SA 4.0）
- 图标重绘参考了 Koolson/Qure、lige47/QuanX-icon-rule、luestr/IconResource、Semporia/Hand-Painted-icon、Orz-3/mini 等社区图标库；品牌标志归各权利人所有，仅用于识别对应服务。内置图标另见 [Lowex-Icons](https://github.com/Kiwareu/Lowex-Icons)。
- 字体：[Great Vibes](https://github.com/googlefonts/great-vibes)（SIL OFL 1.1）。
