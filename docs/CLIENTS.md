# 客户端与平台矩阵 / Clients & platforms

由 `engine/src/data/research.ts` 与客户端目录生成（调研日期 2026-10-16）。机器可读版本：[`clients.research.json`](clients.research.json)。

**置信度**：high = 官方文档/仓库或用户截图直接确认；medium = 多个第三方教程/社区文档一致；low = 未取得一手资料。**verified** 表示关键结论有官方/一手来源。App 界面只依赖 high/medium 的结论做判断。

## 总表

| 客户端 | 内核族 | 平台 | 订阅/节点放置 | 置信度 | 官方/一手来源 | 导出格式 |
|---|---|---|---|---|---|---|
| Clash Verge Rev | mihomo | windows / macos / linux | 写进配置 或 App 内自己添加（可选） | medium | 是 | .yaml |
| FlClash | mihomo | windows / macos / linux / android | 写进配置 或 App 内自己添加（可选） | medium | 否/部分 | .yaml |
| Clash Mi | mihomo | ios / android / windows / macos | 写进配置 或 App 内自己添加（可选） | high | 是 | .yaml |
| Clash Meta for Android | mihomo | android | 写进配置 或 App 内自己添加（可选） | medium | 否/部分 | .yaml |
| Mihomo Party / Clash Party | mihomo | windows / macos / linux | 写进配置 或 App 内自己添加（可选） | low | 否/部分 | .yaml |
| Mihomo 内核（命令行/路由器） | mihomo | linux / windows / macos / android | 只能写进配置 | high | 是 | .yaml |
| sing-box | singbox | windows / macos / linux / android / ios | 只能写进配置 | high | 是 | .json |
| Karing（sing-box 内核） | singbox | ios / android / windows / macos | 只能写进配置 | high | 是 | .json |
| Surge | surge | ios / macos | 只能写进配置 | medium | 是 | .conf |
| Quantumult X | qx | ios | 写进配置 或 App 内自己添加（可选） | high | 是 | .conf |
| Shadowrocket | shadowrocket | ios / macos | 写进配置 或 App 内自己添加（可选） | medium | 是 | .conf |
| Loon | loon | ios | 只能写进配置 | high | 是 | .conf |
| Stash | stash | ios / macos | 只能写进配置 | high | 是 | .yaml |
| Egern | egern | ios / macos | 只能写进配置 | medium | 否/部分 | .yaml |

## 逐客户端调研

### Clash Verge Rev

- 置信度：**medium**；一手来源核实：**是**
- App 内添加订阅/节点：订阅页：粘贴 URL 导入（可设更新间隔）；本地文件导入；URL Scheme：clash://install-config?url=<编码后的订阅地址>
- 配置内嵌：proxy-providers（type: http）或 proxies
- 配置导入：订阅 → 新建 → 本地文件 / URL / URL Scheme
- 备份/同步：WebDAV 备份 / 本地备份（二手资料，未逐项核对）
- 覆写/扩展：扩展配置：Merge（YAML 合并，支持 prepend-/append-/delete- 前缀）与 Script（JS main(config)）；全局扩展 + 订阅专属扩展，先全局后订阅
- 导入步骤（写入配置）：订阅 → 新建 → 选「Local」→ 导入生成的 .yaml，启用该配置。
- 导入步骤（App 内添加）：先在「订阅」粘贴你自己的订阅 URL；再把生成的 .yaml 内容粘贴到「全局扩展配置 → Merge」（或当作该订阅的 Merge）。这份文件只含策略组和规则，节点由订阅提供（策略组用 include-all 收纳）。
- 未核实：Merge 对 proxy-groups / rules 整体覆盖的具体行为按文档推断，未在设备上实测；WebDAV 备份细节
- 来源：<https://www.clashverge.dev/guide/profile>、<https://www.clashverge.dev/guide/url_schemes.html>、<https://www.clashverge.dev/guide/extend.html>

### FlClash

- 置信度：**medium**；一手来源核实：**否/部分**
- App 内添加订阅/节点：配置 → 添加：URL / 本地 YAML 文件 / 二维码（扫描或相册识别）；Deep link：flclash://install-config?url=<编码后的地址>（兼容 clash://install-config）
- 配置内嵌：proxy-providers 或 proxies
- 配置导入：文件 / URL / 二维码 / Deep link
- 备份/同步：WebDAV / 本地文件备份与恢复
- 覆写/扩展：覆写：标准覆写（界面）与覆写脚本（JS），订阅更新后保留
- 导入步骤（写入配置）：「配置」→ 添加 → 选择文件，导入生成的 .yaml 并启用。
- 导入步骤（App 内添加）：先在「配置」里用 URL / 二维码添加你的订阅；再在该订阅的「覆写」里把生成的 .yaml 作为覆写内容（或覆写脚本）。文件只含策略组与规则。
- 未核实：覆写对数组字段是合并还是替换，未实测；Deep link 以社区文档为准
- 来源：<https://flclashguide.com/guides/import-subscription/>、<https://flclashapp.org/tutorial/>、<https://deepwiki.com/chen08209/FlClash/6.3-profile-management>

### Clash Mi

- 置信度：**high**；一手来源核实：**是**
- App 内添加订阅/节点：我的配置：获取配置 / 添加配置链接 / 从剪贴板导入 / 扫描二维码 / 导入配置文件 / 登录（用户截图 + 官方文档）；导入时可选覆写方式：内置-覆写 / 内置-不覆写；链接加 overwrite=false 可在添加时关闭 App 默认覆写
- 配置内嵌：proxy-providers（官方社区常见做法：完整 proxy-providers 配置文件）
- 配置导入：URL / 剪贴板 / 二维码 / 本地文件
- 备份/同步：未发现官方备份/同步功能（未核实）
- 覆写/扩展：三层：订阅配置 ← 自定义覆写配置（可导入 YAML）← Clash Mi 内置覆写（DNS/TUN/端口）。「内置-不覆写」＝完全使用订阅/配置原文，不应用 App 内置的 DNS、TUN、端口覆写；订阅只认 Clash 格式（.yml/.yaml），不认 sing-box/v2ray 订阅
- 导入步骤（写入配置）：我的配置 → 导入配置文件（或添加配置链接），选「内置-不覆写」，让 DNS/TUN 以生成文件为准。
- 导入步骤（App 内添加）：先在「我的配置」用「添加配置链接 / 剪贴板 / 扫码」加你的订阅；再把生成的 .yaml 导入为「自定义覆写配置」。若订阅的 DNS/TUN 要保持原样选「内置-不覆写」。
- 未核实：自定义覆写对 proxy-groups / rules 是替换还是合并，官方 FAQ 只写了「覆写」，未实测
- 来源：<https://clashmi.app/guide/faq>、<https://github.com/KaringX/clashmi-docu/blob/main/guide/faq.md>、<https://github.com/tom-snow/Sidestore-ClashMi>、用户截图（我的配置页）

### Clash Meta for Android

- 置信度：**medium**；一手来源核实：**否/部分**
- App 内添加订阅/节点：配置 → ＋ → 从 URL 导入（可设更新间隔）/ 本地文件
- 配置内嵌：proxy-providers 或 proxies
- 配置导入：URL / 文件
- 备份/同步：无内置云备份（未核实）
- 覆写/扩展：扩展覆写配置 / Meta Features 的 override（订阅刷新后保留）
- 导入步骤（写入配置）：配置 → ＋ → 文件，选生成的 .yaml，并设为当前配置。
- 导入步骤（App 内添加）：先「从 URL 导入」你的订阅；再在 Meta Features 里使用「扩展覆写配置」放入生成内容。
- 未核实：覆写入口名称随版本不同；数组字段替换/合并未实测
- 来源：<https://clashmetaforandroid.com/tutorial/>、<https://github.com/MetaCubeX/ClashMetaForAndroid/discussions/517>

### Mihomo Party / Clash Party

- 置信度：**low**；一手来源核实：**否/部分**
- App 内添加订阅/节点：订阅：URL / 本地文件（以官方仓库说明为准）
- 配置内嵌：proxy-providers 或 proxies
- 配置导入：URL / 文件
- 备份/同步：未核实
- 覆写/扩展：覆写配置（YAML / JS），按订阅启用（以仓库说明为准）
- 导入步骤（写入配置）：订阅 → 导入本地文件，选生成的 .yaml。
- 导入步骤（App 内添加）：先添加你自己的订阅；再在「覆写」里导入生成的 .yaml（只含策略组与规则）。
- 未核实：本次未取得一手文档；结论来自内核族共性与印象

### Mihomo 内核（命令行/路由器）

- 置信度：**high**；一手来源核实：**是**
- App 内添加订阅/节点：—
- 配置内嵌：proxy-providers 或 proxies（mihomo -f config.yaml）
- 配置导入：文件
- 备份/同步：—
- 覆写/扩展：无（直接改文件）
- 导入步骤（写入配置）：保存为 config.yaml，mihomo -f config.yaml 启动。
- 来源：<https://wiki.metacubex.one/>

### sing-box

- 置信度：**high**；一手来源核实：**是**
- App 内添加订阅/节点：SFI / sing-box 官方 App：远程配置 URL（sing-box://import-remote-profile?url=…#名称）；iCloud（sing-box 文件夹，可自动更新）；本地 JSON 文件
- 配置内嵌：没有订阅字段：节点必须展开成 outbounds
- 配置导入：远程 URL / iCloud / 本地文件 / URL Scheme
- 备份/同步：iCloud 配置存储
- 覆写/扩展：无
- 导入步骤（写入配置）：Profiles → New → Local/iCloud 或 Remote，导入生成的 .json。
- 未核实：远程配置是「整份配置」，不是节点订阅，所以订阅 URL 无法写进 sing-box 配置
- 来源：<https://sing-box.sagernet.org/clients/general/>

### Karing（sing-box 内核）

- 置信度：**high**；一手来源核实：**是**
- App 内添加订阅/节点：添加配置链接（clash/stash/v2ray/sing-box/ss/sub/github 类型）；从剪贴板导入；扫描二维码；导入本地配置文件（不可更新）；自定义；URL Scheme：karing://install-config?url=…&name=…
- 配置内嵌：没有订阅字段：节点展开成 outbounds
- 配置导入：链接 / 剪贴板 / 二维码 / 文件 / Scheme
- 备份/同步：备份与同步：iCloud（仅 iOS/macOS）/ WebDAV / 局域网同步；导入导出
- 覆写/扩展：无（有自定义配置入口）
- 导入步骤（写入配置）：添加配置 → 导入本地配置文件，选生成的 .json。
- 未核实：当前不提供 Karing「在 App 内添加订阅 + 导入规则覆盖」模式，因为 Karing 的覆盖机制未核实
- 来源：<https://karing.app/en/app-manual/add-profiles>、<https://karing.pro/en/faq/karing-subscription/>

### Surge

- 置信度：**medium**；一手来源核实：**是**
- App 内添加订阅/节点：策略组 policy-path 引用订阅 / 完整 Profile（写在配置里）；surge:///install-config?url=… 安装托管配置
- 配置内嵌：[Proxy Group] policy-path=URL；#!include 引用托管配置
- 配置导入：URL（托管配置） / 文件 / Scheme
- 备份/同步：iCloud 同步配置（未核实）
- 覆写/扩展：Detached Profile + #!include ManagedProfile.conf
- 导入步骤（写入配置）：配置 → 从 URL 安装或用「文件」打开 .conf。
- 未核实：App 界面里单独添加节点的入口未核实，所以不提供「App 内添加」模式
- 来源：<https://kb.nssurge.com/surge-knowledge-base/guidelines/proxy-provider>、<https://manual.nssurge.com/policy-groups/policy-including.html>、<https://kb.nssurge.com/surge-knowledge-base/guidelines/detached-profile>

### Quantumult X

- 置信度：**high**；一手来源核实：**是**
- App 内添加订阅/节点：节点页长按「节点」→ 引用（订阅）添加；URL Scheme：quantumult-x:///add-resource?remote-resource=<JSON>（追加，不覆盖）；update-configuration 会替换全部资源
- 配置内嵌：[server_remote]（订阅）、[server_local]（节点）
- 配置导入：URL / iCloud/Profiles 目录 / Scheme / 剪贴板
- 备份/同步：iCloud 配置
- 覆写/扩展：策略组 server-tag-regex / resource-tag-regex 可按名称从 App 内全部节点/订阅里筛选
- 导入步骤（写入配置）：配置文件 → 下载 / 打开本地文件，再「编辑」确认 [server_remote] 已有订阅。
- 导入步骤（App 内添加）：先在「设置 → 节点 → 引用」添加订阅（长按「节点」也可）；再导入生成的 conf。策略组用 server-tag-regex 按节点名里的地区收纳。
- 来源：<https://github.com/crossutility/Quantumult-X/blob/master/url-scheme.md>、<https://raw.githubusercontent.com/crossutility/Quantumult-X/master/sample.conf>、<https://qx.atlucky.me/shi-yong-fang-fa/pei-zhi-wen-jian-xiang-jie/jie-dian/serverremote-jie-dian-zi-yuan>

### Shadowrocket

- 置信度：**medium**；一手来源核实：**是**
- App 内添加订阅/节点：首页 ＋ → 类型 Subscribe → 粘贴 URL（可设备注、正则筛选、自动更新）；扫码 / 粘贴节点链接 / 手动填写；配置里的订阅分组：策略组可按订阅收纳
- 配置内嵌：conf 的 [Proxy] 只能放本地节点（社区手册：仅为兼容其他配置，不是首选）；订阅无法写进 conf
- 配置导入：配置页 → 远程文件 URL / iCloud / 本地文件 / Wi-Fi 上传
- 备份/同步：iCloud 自动同步（配置、模块、脚本）
- 覆写/扩展：策略组 policy-regex-filter 按节点名筛选 App 内全部节点
- 导入步骤（写入配置）：配置 → 添加配置 / 导入文件，选生成的 conf 并设为当前配置。订阅仍要在首页 App 内添加。
- 导入步骤（App 内添加）：首页 ＋ 添加订阅或节点；再导入生成的 conf。策略组用 policy-regex-filter 按节点名里的地区收纳。
- 未核实：[Proxy] 内 socks5/http 手动节点语法来自社区手册
- 来源：<https://github.com/LOWERTOP/Shadowrocket>、<https://shadowrocketx.com/en/guide-subscription.html>、<https://shadowrocket6.com/en/import.html>

### Loon

- 置信度：**high**；一手来源核实：**是**
- App 内添加订阅/节点：配置 → 订阅节点 → ＋（写入当前配置的 [Remote Proxy]）；loon://import?nodelist=<编码URL>（节点订阅）；loon://import?sub=<编码URL>（远端配置）；rules / plugin 等
- 配置内嵌：[Remote Proxy]；筛选写 [Remote Filter]（NodeSelect / NameKeyword / NameRegex），策略组引用别名
- 配置导入：URL（sub） / 文件 / Scheme
- 备份/同步：iCloud（未核实）
- 覆写/扩展：插件（Plugin）
- 导入步骤（写入配置）：配置 → 远端配置 / 导入文件，选生成的 conf。
- 未核实：App 内添加的订阅同样写进当前配置，Remote Filter 需要引用别名，所以没有独立的「App 内模式」
- 来源：<https://nsloon.bid/document/scheme>、<https://github.com/chiupam/tutorial/blob/master/Loon/Plus/Remote_Filter.md>、<https://raw.githubusercontent.com/fanmingming/Rules/main/Loon.conf>

### Stash

- 置信度：**high**；一手来源核实：**是**
- App 内添加订阅/节点：设置 → 配置文件 → 从 URL 下载（订阅本身就是配置）；AirDrop / iCloud / OneDrive 文件打开；stash://install-config?url=…；.stoverride 覆写文件可直接导入
- 配置内嵌：proxy-providers / proxies
- 配置导入：URL / 文件 / Scheme
- 备份/同步：iCloud 同步 Providers（release notes）
- 覆写/扩展：.stoverride：标量覆盖、字典递归合并、数组默认插到原数组前（#!replace 整体替换），可带参数；订阅更新后保留
- 导入步骤（写入配置）：设置 → 配置文件 → 导入生成的 .yaml 并选中。
- 未核实：App 内添加订阅 + 覆写叠加规则的组合没有实测，所以不提供第二种模式
- 来源：<https://stash.wiki/get-started>、<https://stash.wiki/configuration/override>、<https://stash.wiki/release-notes/ios>

### Egern

- 置信度：**medium**；一手来源核实：**否/部分**
- App 内添加订阅/节点：工具 → 策略组 → 外部（External）填订阅 URL
- 配置内嵌：policy_groups 里 type: external + urls
- 配置导入：URL / 文件 / Surge 配置文件导入
- 备份/同步：未核实
- 覆写/扩展：模块（Surge 模块格式）
- 导入步骤（写入配置）：导入生成的 .yaml 并启用。
- 未核实：导入入口、备份能力来自第三方教程，未对照官方文档
- 来源：<https://github.com/ClashConnectRules/Egern/blob/main/README_zh.md>、<https://getegern.org/>

## 策略组类型与故障转移（2026-10-17 核对）

故障转移 = 一个组按顺序用第一个健康的成员，挂了才换（fallback）。下表只认官方文档；来源页面均为当前版本文档。

| 客户端族 | 支持故障转移 | 策略组类型 | Lowex 输出 | 可信度 |
|---|---|---|---|---|
| mihomoFamily | 是 | select / url-test / fallback / load-balance / relay | type: fallback（成员为该区的手动组与自动组，lazy、max-failed-times、empty-fallback） | high |
| stash | 是 | select / url-test / fallback / load-balance / relay | type: fallback；策略组可嵌套策略组 | high |
| surge | 是 | select / url-test / fallback / load-balance / smart / subnet | fallback, <手动组>, <自动组> | high |
| loon | 是 | select / url-test / fallback / load-balance / ssid | fallback + 该区节点 / Remote Filter（不嵌套策略组） | high |
| shadowrocket | 是 | select / url-test / fallback / load-balance / random | fallback + policy-regex-filter（不嵌套策略组） | medium |
| qx | 是 | static / available / round-robin / dynamic / ssid / url-latency-benchmark | available=<名>, server-tag-regex=…（QX 的故障转移类型叫 available） | high |
| egern | 是 | select / auto_test / fallback / load_balance / external / conditional | fallback: {policies: [手动组, 自动组]} | medium |
| singbox | 否 | selector / urltest | 无故障转移组：自动组用 urltest（选延迟最低的健康节点，节点挂了自动换） | high |
| karing | 否 | selector / urltest | 同 sing-box（本工具输出 sing-box JSON） | medium |

- **mihomoFamily**：Verge Rev / FlClash / Clash Mi / CMFA / Clash Party / Mihomo 内核同一内核。 来源：<https://wiki.metacubex.one/en/config/proxy-groups/>
- **stash**：官方文档明确「策略组可以包含另一个策略组」。 来源：<https://stash.wiki/proxy-protocols/proxy-groups>
- **surge**：官方：除 smart 外，所有类型都可嵌套其他策略组。 来源：<https://manual.nssurge.com/policy-groups/overview.html>、<https://manual.nssurge.com/llms.txt>
- **loon**：官方示例注明 url-test / fallback「只支持单个节点和远端节点，其他会被忽略」——现在不再把策略组塞进 fallback。 来源：<https://nsloon.bid/document/policygroup>、<https://github.com/Loon0x00/LoonExampleConfig/blob/master/example.conf>
- **shadowrocket**：社区手册列出 url-test / fallback / load-balance / random；嵌套行为未核实，故用正则收纳节点。 来源：<https://github.com/LOWERTOP/Shadowrocket>
- **qx**：官方 sample.conf：server-tag-regex 对 static / available / round-robin 有效；现在不再嵌套策略组。 来源：<https://raw.githubusercontent.com/crossutility/Quantumult-X/master/sample.conf>
- **egern**：官方 FAQ：策略组可包含其他策略组。 来源：<https://egern.top/configuration/example>、<https://egernapp.com/zh-CN/docs/faq/>
- **singbox**：官方只有 selector / urltest；priority / loadbalance 仅是未合并的 PR / issue。早期版本曾误输出了一个不会故障转移的「故转」selector，v1.4 已移除。 来源：<https://sing-box.sagernet.org/configuration/outbound/urltest/>、<https://github.com/SagerNet/sing-box/pull/4217>、<https://github.com/SagerNet/sing-box/pull/4321>
- **karing**：Karing 自身的分组能力未核实，只按 sing-box 内核能力输出。 来源：<https://karing.app/en/app-manual/add-profiles>

不支持故障转移的客户端（sing-box、Karing）：App 里不显示「故障转移」选项，生成的配置里也不含该组；自动组使用 urltest。

Karing 的自有分组能力未核实，按 sing-box 内核能力处理。QX / Shadowrocket / Egern / Loon / Surge / Stash 没有离线校验器，未做真机验证。

## Clash Mi「内置-不覆写」

Clash Mi 的覆写分三层：订阅配置 ← 自定义覆写配置 ← 内置覆写（DNS / TUN / 端口等）。「内置-不覆写」表示完全使用订阅或导入配置原文，不叠加 App 内置覆写；「内置-覆写」（默认）则用 App 设置覆盖。添加配置链接时加 `overwrite=false` 等价于不覆写。Lowex 生成的完整配置（含 proxy-providers）建议选「内置-不覆写」，否则 DNS/TUN/端口会被 App 设置改写。来源：<https://clashmi.app/guide/faq>。

## 平台规则隔离 / Platform isolation
- **Windows**：仅此平台可出现 `PROCESS-NAME,xxx.exe`；不会出现包名。
- **Android**：仅此平台可出现 Android 包名规则；不会出现 `.exe`。
- **iOS**：没有进程名 / 包名规则，按应用分流自动退化为按域名或服务组。
- **Wi-Fi 通话规则**：只在 iOS / Android 生成。


## 能力审计（v1.4.4，2026-10-17）

方法：对每个客户端生成「全开 / 最少」输出（每个平台各一份），逐项对照本文件、`clients.research.json` 与官方文档 / 社区手册；再用 `caps-test` 检查「矩阵声明支持 ⇔ 改动选项后生成物确实变化」，用规则类型白名单检查没有越界关键字。

| 客户端 | 发现 | 处理 |
|---|---|---|
| Stash | QUIC 选项可选但不生成；STUN 未列入矩阵 | 按 Stash 文档生成 `AND,((NETWORK,UDP),(DST-PORT,443),(NOT,((GEOIP,CN)))),REJECT` 与 `PROTOCOL,STUN,REJECT` |
| Loon | `[General]` 里 `disable-stun` 写了两遍 | 只写一次 |
| Shadowrocket | `dns-fallback-system` 不在官方 / 社区样例里 | 删除 |
| Egern | `dns.forward` 用了未核实的 `domain_suffix` 匹配 | 改为文档示例的 `wildcard: *.cn` |
| sing-box / Karing（手机） | 手机端只有 TUN 入站，但「本地端口 / 允许局域网」仍显示 | 手机平台隐藏这两项 |
| Mihomo 系 / Surge / QX | 未发现不一致 | — |

未实现 / 未核实（保持现状）：
- 负载均衡组：Surge / Shadowrocket / Egern 官方文档有此类型，当前只对 Mihomo / Stash 生成（缺口，非越界）。
- Surge 会写 `loglevel`，而「日志级别」选项对 Surge 隐藏。
- Egern 的 `rule_set` 指向 Surge `.list`、策略组 `icon` 在官方示例里没有出现，标为未核实。
- Surge、Loon、Shadowrocket、QX、Egern、Stash、Karing 为闭源，未在真机验证；Wi-Fi 通话流量是否进入隧道取决于 iOS 与客户端的「包含蜂窝 / 全部网络」设置。
