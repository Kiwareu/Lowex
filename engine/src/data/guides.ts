// 各客户端使用指南：导入步骤 / 关键设置 / 注意。
// 依据按官方文档优先；未在官方文档核实的条目标 unverified，界面会标「未核实」。
// 文案保持一句话说清一件事；与 Lowex 生成配置的对应关系写在「关键设置」里。
export interface GuideItem{ t:string; body:string; unverified?:boolean }
export interface GuideSection{ t:string; items:GuideItem[] }
export interface Guide{
  basis:string;   // 依据说明
  over:string;    // 会被客户端自己覆盖的项（或「无」）
  sections:GuideSection[];
}
export const GUIDES:Record<string,Guide>={
verge:{basis:'官方文档（clashverge.dev，v2.5.8）',over:'端口、TUN、DNS（界面里「DNS 覆写」开启时）',
 sections:[
  {t:'导入步骤',items:[
    {t:'文件导入',body:'「订阅」→ 新建 → 选 Local → 导入 Lowex 生成的 .yaml，启用该配置。'},
    {t:'当扩展用',body:'也可以把生成的 .yaml 当作「全局扩展覆写」叠加在你自己的订阅上，节点仍由订阅提供。'}]},
  {t:'关键设置',items:[
    {t:'界面优先',body:'v2.5.4 起，界面里的 TUN / 系统代理开关会覆盖配置里的对应段，以界面为准。'},
    {t:'Windows 开 TUN',body:'需要服务模式或管理员运行，否则流量接管不全。'},
    {t:'扩展配置',body:'Merge（YAML 合并）与 Script（JS main(config)）可叠加在订阅上，先全局后订阅；订阅更新后扩展仍保留。'}]},
  {t:'注意',items:[
    {t:'残留系统代理',body:'客户端崩溃后系统代理可能残留，表现为「没开 Clash 也上不了网」——关掉系统代理或重开客户端。'}]}]},
flclash:{basis:'官方文档与仓库说明；TUN 模型字段为代码推导',over:'端口、IPv6、TUN、分应用代理',
 sections:[
  {t:'导入步骤',items:[
    {t:'文件 / 链接 / 二维码',body:'「配置」→ 添加 → 文件、URL 或二维码（扫描或相册识别）导入生成的 .yaml。'},
    {t:'Deep link',body:'clash://install-config?url=（另有 clashmeta://、flclash://），点链接可直接导入。'}]},
  {t:'关键设置',items:[
    {t:'界面优先',body:'FlClash 会覆盖端口、IPv6、TUN、分应用，生成配置里的这些项只作初始值，以界面设置为准。'},
    {t:'TUN 栈',body:'默认 mixed；没有 strict-route 这一项，别按桌面 Mihomo 的习惯去找。'}]},
  {t:'注意',items:[
    {t:'没有 iOS 版',body:'FlClash 只有 Windows / macOS / Linux / Android，iPhone 别找它。'}]}]},
clashmi:{basis:'官方文档；文件导入入口未在官方文档核实',over:'端口、TUN',
 sections:[
  {t:'导入步骤',items:[
    {t:'文件导入',body:'把生成的 .yaml 传到手机（隔空投送 / 文件 App / iCloud），在「配置」里添加并启用。',unverified:true}]},
  {t:'关键设置',items:[
    {t:'TUN 要设覆写',body:'TUN 必须在「核心设置」里设为「覆写」并开启，否则配置里的 tun 段可能不生效。'},
    {t:'内存上限',body:'iOS 的 VPN 扩展内存上限约 50MB：规则集太多、太大会被系统杀掉，表现为用一会儿突然断网——少开服务组，广告拦截选 Lite。'},
    {t:'Apple 推送',body:'TUN 里 includeAllNetworks 开、exclude 三项关，再加推送规则——这些是 App 内开关，写不进配置。'}]},
  {t:'注意',items:[
    {t:'不支持 ip-asn',body:'iOS 上不支持 ip-asn 数据库，别指望按 ASN 分流在 iOS 上生效。'},
    {t:'附加 HTTP 代理',body:'「附加 HTTP 代理到 VPN」可能影响部分 App，出问题先关它。'},
    {t:'面板密码',body:'面板密码是设备唯一的强制值，改不了。'},
    {t:'scheme 别用错',body:'clash://install-config 不是 ClashMi 的（那是 FlClash / CMFA 的），别用错。'}]}]},
cmfa:{basis:'官方仓库；TUN 与面板处理为代码推导',over:'访问控制（分应用）',
 sections:[
  {t:'导入步骤',items:[
    {t:'文件导入',body:'「配置」→ 新建 → 导入 Lowex 生成的 .yaml 文件。'}]},
  {t:'关键设置',items:[
    {t:'TUN 由系统接管',body:'导入后配置里的 TUN 会被关掉（由 VpnService 接管），external-controller 也会被关——别在配置里指望它们。'},
    {t:'TUN 栈',body:'TUN_STACK 默认 system。'},
    {t:'分应用',body:'分应用在「网络设置 → 访问控制」里选。'},
    {t:'私人 DNS',body:'关闭系统「私人 DNS」，否则 DNS 不走代理。'}]},
  {t:'注意',items:[
    {t:'仅 Android',body:'Clash Meta for Android 只有 Android 版，没有 iOS 版。'}]}]},
clashparty:{basis:'官方仓库与文档（v2.0.4）',over:'端口、TUN',
 sections:[
  {t:'导入步骤',items:[
    {t:'文件导入',body:'「配置」→ 导入本地文件，选 Lowex 生成的 .yaml。'}]},
  {t:'关键设置',items:[
    {t:'TUN 不用服务模式',body:'不用服务模式也能开 TUN。'},
    {t:'DNS 覆写保护',body:'DNS 覆写保护可能拦截生成配置里的 DNS，DNS 异常时先看这项。'},
    {t:'简洁模式',body:'简洁模式可能重写配置字段，配置对不上时先退出简洁模式。'}]},
  {t:'注意',items:[
    {t:'名字变了',body:'仓库已更名 clash-party，Mihomo Party 与 Clash Party 是同一个。'}]}]},
mihomo:{basis:'官方 wiki（v1.19.32）',over:'无——内核直接读配置',
 sections:[
  {t:'导入步骤',items:[
    {t:'命令行',body:'保存为 config.yaml，运行 mihomo -d 目录（或 -f config.yaml）。'}]},
  {t:'关键设置',items:[
    {t:'TUN 栈',body:'默认 mips（v1.19.31 起）；mixed = TCP 用系统栈、UDP 用 gvisor。'},
    {t:'IPv6',body:'ipv6 默认 true——Lowex 需要时会在配置里显式写 false。'},
    {t:'strict-route',body:'strict-route 可能影响 VirtualBox 等虚拟机网络。'}]},
  {t:'注意',items:[
    {t:'Windows 防火墙',body:'Windows 上 system / mixed 栈会被防火墙拦——把内核程序加进防火墙白名单。'},
    {t:'已校验',body:'Lowex 生成的配置已按 v1.19.32 校验过。'}]}]},
singbox:{basis:'官方文档（稳定版 1.14.3）',over:'iOS / Android 官方 App 的 TUN 由 App 管理',
 sections:[
  {t:'导入步骤',items:[
    {t:'导入 JSON',body:'官方 App「配置」→ 新建 → 导入 Lowex 生成的 JSON。'}]},
  {t:'关键设置',items:[
    {t:'没有订阅功能',body:'sing-box 没有订阅字段——Lowex 会把节点展开写进文件，所以要在 Lowex 里粘贴节点或订阅正文。'},
    {t:'嗅探是路由动作',body:'嗅探现在是路由动作（action: sniff），不是入站字段——别按旧教程找入站嗅探开关。'},
    {t:'别配 stack',body:'stack 在 1.15 弃用、1.17 移除，别再配它；endpoint_independent_nat 自 1.11 起已无效。'}]},
  {t:'注意',items:[
    {t:'规则集别贪多',body:'Android 图形界面处理不了超大的 route_address_set，规则集别贪多。'},
    {t:'iOS 没有按进程匹配',body:'未越狱 iOS 没有按进程匹配——按 App 分流在 iOS 上做不到。'}]}]},
karing:{basis:'社区与仓库说明；导入字段的覆盖未核实',over:'导入字段可能被 App 自己的层覆盖',
 sections:[
  {t:'导入步骤',items:[
    {t:'直接给订阅',body:'Karing 原生支持订阅（Clash / V2ray / Stash / sing-box 等），可直接用订阅链接 + karing://install-config?url=。'},
    {t:'导入 JSON',body:'也可以在「设置 → 配置」导入 Lowex 生成的 sing-box JSON。'}]},
  {t:'关键设置',items:[
    {t:'TUN 栈在 App 内',body:'TUN 的 Network Stack 在 App 内设置。'},
    {t:'配置可能被覆盖',body:'导入的 JSON 字段可能被 Karing 自己的层覆盖（未核实），配置对不上时以 App 内设置为准。',unverified:true}]},
  {t:'注意',items:[
    {t:'不是官方客户端',body:'Karing 不是官方 sing-box 客户端，内核改过——官方 sing-box 的文档不一定全适用。'},
    {t:'关 TUN 后仍断网',body:'iOS / macOS 上关掉 TUN 后仍可能断网（NE 进程已启动），重启 App 再试。'}]}]},
surge:{basis:'官方手册（manual.nssurge.com）',over:'TUN 等由 App 自己的 VPN 开关管理，不写进配置',
 sections:[
  {t:'导入步骤',items:[
    {t:'新建配置',body:'「配置」→ 新建 → 粘贴 / 从文件导入 Lowex 生成的 .conf。'}]},
  {t:'关键设置',items:[
    {t:'订阅用 policy-path',body:'订阅用 policy-path 引用——只接受 Surge [Proxy] 行或完整 profile，通用机场订阅不能直接塞。'},
    {t:'include-apns',body:'include-apns 需要先开 include-all-networks。'},
    {t:'external 组',body:'external 策略组在 iOS 上等于 REJECT。'},
    {t:'IPv6',body:'ipv6 默认 false、ipv6-vif 默认关闭。'}]},
  {t:'注意',items:[
    {t:'PROCESS-NAME 无效',body:'PROCESS-NAME 在 iOS 上被忽略——iOS 上按 App 分流做不到。'},
    {t:'skip-proxy',body:'skip-proxy 不是直连规则，别把它当 DIRECT 用。'}]}]},
loon:{basis:'官方文档（nsloon.app）+ 官方示例配置；[Remote Proxy] 行格式未核实',over:'TUN 等由 App 自己的 VPN 开关管理，不写进配置',
 sections:[
  {t:'导入步骤',items:[
    {t:'新建配置',body:'「配置」→ 新建 → 本地 / 粘贴 Lowex 生成的 .conf；订阅写在 [Remote Proxy]。',unverified:true}]},
  {t:'关键设置',items:[
    {t:'ip-mode',body:'ip-mode 已取代旧的 ipv6 键。'},
    {t:'防 STUN 泄漏',body:'disable-stun=true 有官方文档，防 WebRTC 泄漏就用它。'},
    {t:'UDP 回退',body:'udp-fallback-mode 选 REJECT。'}]},
  {t:'注意',items:[
    {t:'没有 macOS 版',body:'Loon 只有 iOS 版。'},
    {t:'规则集格式',body:'规则集只认 .list / .txt 文本格式。'}]}]},
qx:{basis:'官方 sample.conf v1.0.19',over:'TUN 等由 App 自己的 VPN 开关管理，不写进配置',
 sections:[
  {t:'导入步骤',items:[
    {t:'粘贴到编辑器',body:'「设置 → 配置文件 → 下载 / 编辑」，把 Lowex 生成的 .conf 粘贴到编辑器。'}]},
  {t:'关键设置',items:[
    {t:'订阅',body:'[server_remote] + tag / update-interval / opt-parser 管订阅。'},
    {t:'UDP 回退',body:'fallback_udp_policy 默认 reject，且只对终点策略组有效。'},
    {t:'available 组',body:'available 组闲置时不主动测速——它不是实时故障转移，别指望节点挂了立刻切。'}]},
  {t:'注意',items:[
    {t:'别混两代语法',body:'新版 url-latency-benchmark 语法不在 v1.0.19 示例里，别把两代语法混在一个文件里。'},
    {t:'STUN',body:'STUN 只能用 udp_drop_list 丢弃（会连本地 QUIC 一起丢）。'}]}]},
shadowrocket:{basis:'社区最完整手册（官方无公开语法文档）',over:'TUN 等由 App 自己的 VPN 开关管理，不写进配置',
 sections:[
  {t:'导入步骤',items:[
    {t:'先加节点',body:'先在 Shadowrocket「首页」添加节点或订阅——本 .conf 写不进节点。'},
    {t:'再导配置',body:'「配置」→ + → 从文件 / iCloud 导入 Lowex 生成的 .conf。'}]},
  {t:'关键设置',items:[
    {t:'策略组收纳',body:'策略组用 policy-regex-filter + 订阅名 + use=true，按地区名自动收纳首页的节点。'},
    {t:'节点改名',body:'节点改名会打乱收纳——订阅名与正则要对上。'}]},
  {t:'注意',items:[
    {t:'没有官方文档',body:'Shadowrocket 没有官方公开语法文档，本指南按社区手册整理，个别写法以 App 实际行为为准。'},
    {t:'推送延迟',body:'bypass-system 关了可能延迟推送。'}]}]},
stash:{basis:'官方文档（stash.wiki）',over:'TUN 等由 App 自己的 VPN 开关管理，不写进配置',
 sections:[
  {t:'导入步骤',items:[
    {t:'粘贴',body:'「配置」→ 新建 → 粘贴 Lowex 生成的 .yaml。'}]},
  {t:'关键设置',items:[
    {t:'覆写',body:'覆写是 .stoverride YAML 合并——数组默认前置，有 #!append / #!replace 可改。'},
    {t:'托管配置',body:'托管配置首行 #SUBSCRIBED，约 12 小时检查一次更新。'},
    {t:'规则集格式',body:'规则集用 YAML 格式，不用 mrs。'}]},
  {t:'注意',items:[
    {t:'进程规则无效',body:'PROCESS-NAME / PATH 在 iOS 上被忽略。'},
    {t:'开关不在文档里',body:'TUN / 嗅探 / IPv6 / Allow-LAN 开关不在官方文档里——别指望配置控制它们。'}]}]},
egern:{basis:'官方文档（egernapp.com）；主配置导入与 TUN / 嗅探 / IPv6 开关未在官方文档说明',over:'TUN 等由 App 自己的 VPN 开关管理，不写进配置',
 sections:[
  {t:'导入步骤',items:[
    {t:'新建配置',body:'「配置」→ 新建 → 粘贴 Lowex 生成的 .yaml；订阅用「外部资源策略组」。'}]},
  {t:'关键设置',items:[
    {t:'Modules',body:'Modules 是 YAML 片段合并进主配置，支持 {{{ARG}}} 占位与 env——想加自定义片段走 Modules，别直接改主配置。'},
    {t:'规则集格式',body:'规则集是 Surge 格式 .list。'}]},
  {t:'注意',items:[
    {t:'别按 Surge 假设',body:'主配置导入方式与 TUN / 嗅探 / IPv6 开关未在官方文档说明，别按 Surge 语法假设。'},
    {t:'JS 模板',body:'别给 Egern 用 Surge 语法的 JS 模板（Lowex 也不会给）。'}]}]},
};
