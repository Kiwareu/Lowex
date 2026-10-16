export type Platform = 'windows'|'macos'|'linux'|'ios'|'android';
export type Family = 'mihomo'|'singbox'|'surge'|'qx'|'shadowrocket'|'loon'|'stash'|'egern';
export interface Client{
  id:string; name:string; family:Family; platforms:Platform[]; blurb:string;
  beta?:boolean;            // 没有官方二进制校验（闭源 App）
  docs?:string;             // 已逐项对照的官方文档/样例（有则界面显示「文档核对」而不是 beta）
  ext:string; mime:string;  // 输出文件
  importHint:string;        // 如何导入
  overrides?:string[];      // 客户端界面会覆盖的设置
  subInConfig:boolean;      // 订阅 URL 可否写进配置
  processRules:boolean;     // 是否支持按进程/包名分流
  status:string;            // 维护状态依据
}

export const CLIENTS:Client[]=[
 {id:'verge',name:'Clash Verge Rev',family:'mihomo',platforms:['windows','macos','linux'],blurb:'桌面首选 · Mihomo 内核',ext:'yaml',mime:'text/yaml',subInConfig:true,processRules:true,status:'v2.5.8（2026-10-09）仍在更新',importHint:'「订阅」→ 新建 → 本地文件导入；或把文件作为「全局扩展覆写」。系统代理 / TUN 以界面开关为准。',overrides:['端口','TUN','DNS（界面里「DNS 覆写」开启时）']},
 {id:'flclash',name:'FlClash',family:'mihomo',platforms:['windows','macos','linux','android'],blurb:'Win / Android · Mihomo 内核',ext:'yaml',mime:'text/yaml',subInConfig:true,processRules:true,status:'v0.9.0（2026-10-14）仍在更新',importHint:'「配置」→ 添加 → 文件导入。FlClash 会覆盖端口 / IPv6 / TUN / 分应用，请在界面里同步。',overrides:['端口','IPv6','TUN','分应用代理']},
 {id:'clashmi',name:'Clash Mi',family:'mihomo',platforms:['ios','android','windows','macos'],blurb:'iOS / Android · Mihomo 内核',ext:'yaml',mime:'text/yaml',subInConfig:true,processRules:false,status:'v1.0.31（2026-10-09）仍在更新',importHint:'「配置」→ 添加 → 从文件导入（或用 iCloud/文件 App 打开）。本地面板端口 7066，CORS 已用 :* 通配。',overrides:['端口','TUN']},
 {id:'cmfa',name:'Clash Meta for Android',family:'mihomo',platforms:['android'],blurb:'Android · Mihomo 内核',ext:'yaml',mime:'text/yaml',subInConfig:true,processRules:true,status:'v2.11.35（2026-09-30）仍在更新',importHint:'「配置」→ 新建 → 文件。分应用请在「网络设置→访问控制」里选；关闭系统「私人 DNS」。',overrides:['访问控制（分应用）']},
 {id:'clashparty',name:'Mihomo Party / Clash Party',family:'mihomo',platforms:['windows','macos','linux'],blurb:'桌面 · 仓库已更名 clash-party',ext:'yaml',mime:'text/yaml',subInConfig:true,processRules:true,status:'v2.0.3（2026-09-20）；产品名可能已变，两个名字都能用',importHint:'「配置」→ 导入本地文件。',overrides:['端口','TUN']},
 {id:'mihomo',name:'Mihomo 内核（命令行/路由器）',family:'mihomo',platforms:['linux','windows','macos','android'],blurb:'直接 mihomo -f config.yaml',ext:'yaml',mime:'text/yaml',subInConfig:true,processRules:true,status:'v1.19.32（2026-09-30）',importHint:'保存为 config.yaml，运行 mihomo -d 目录。生成前已按 v1.19.32 校验。'},
 {id:'singbox',name:'sing-box',family:'singbox',platforms:['windows','macos','linux','android','ios'],blurb:'通用内核 · 官方 App（iOS/Android）',ext:'json',mime:'application/json',subInConfig:false,processRules:true,status:'v1.14.3（2026-10-09）；生成按 1.14 语法并用 sing-box check 校验',importHint:'官方 App：「配置」→ 新建 → 导入 JSON。sing-box 无订阅字段：必须在 Lowex 粘贴节点链接/正文，生成时展开进 outbounds。',overrides:['iOS/Android 官方 App 的 TUN 由 App 管理']},
 {id:'karing',name:'Karing（sing-box 内核）',family:'singbox',platforms:['ios','android','windows','macos'],blurb:'iOS / Android / 桌面',beta:true,ext:'json',mime:'application/json',subInConfig:false,processRules:true,status:'v1.2.25（2026-09）仍在更新；本站未实测导入',importHint:'「设置→配置」导入 sing-box JSON。Karing 自带订阅，也可以直接用它的订阅 + 本站的规则。'},
 {id:'surge',name:'Surge',family:'surge',platforms:['ios','macos'],blurb:'iOS / macOS',beta:true,docs:'manual.nssurge.com（策略组 / 规则 / General / 节点参数）逐项核对',ext:'conf',mime:'text/plain',subInConfig:true,processRules:false,status:'闭源付费；已按官方手册逐项核对，无法在服务器上跑真机',importHint:'「配置」→ 新建 → 粘贴 / 从文件导入。订阅用 policy-path 引用。'},
 {id:'qx',name:'Quantumult X',family:'qx',platforms:['ios'],blurb:'iOS',beta:true,docs:'官方 sample.conf（crossutility/Quantumult-X）逐项核对',ext:'conf',mime:'text/plain',subInConfig:true,processRules:false,status:'闭源付费；已按官方 sample.conf 逐项核对，无法在服务器上跑真机',importHint:'「设置→配置文件→下载 / 编辑」，粘贴到编辑器。'},
 {id:'shadowrocket',name:'Shadowrocket（小火箭）',family:'shadowrocket',platforms:['ios','macos'],blurb:'iOS',beta:true,docs:'社区手册 LOWERTOP/Shadowrocket（README + lazy_group.conf）逐项核对；官方无公开语法文档',ext:'conf',mime:'text/plain',subInConfig:false,processRules:false,status:'闭源付费；没有官方公开语法文档，按社区最完整的手册核对，无法在服务器上跑真机',importHint:'① 在小火箭「首页」添加节点或订阅（本 conf 写不进节点）。②「配置」→ + → 从文件/iCloud 导入本 conf。③ 策略组用 policy-regex-filter 按地区名自动收纳首页节点。'},
 {id:'loon',name:'Loon',family:'loon',platforms:['ios'],blurb:'iOS',beta:true,docs:'nsloon.app 官方文档 + Loon0x00/LoonExampleConfig 逐项核对',ext:'conf',mime:'text/plain',subInConfig:true,processRules:false,status:'闭源付费；已按官方文档与官方示例配置逐项核对，无法在服务器上跑真机',importHint:'「配置」→ 新建 → 本地 / 粘贴。订阅写在 [Remote Proxy]。'},
 {id:'stash',name:'Stash',family:'stash',platforms:['ios','macos'],blurb:'iOS / macOS · Clash 风格',beta:true,docs:'stash.wiki 官方文档（策略组 / 规则集合 / 远程代理集）逐项核对',ext:'yaml',mime:'text/yaml',subInConfig:true,processRules:false,status:'闭源付费；Clash 语法子集，已按 stash.wiki 核对，无法在服务器上跑真机',importHint:'「配置」→ 新建 → 粘贴。规则集使用 YAML 格式（不用 mrs）。'},
 {id:'egern',name:'Egern',family:'egern',platforms:['ios','macos'],blurb:'iOS / macOS',beta:true,docs:'egernapp.com 官方文档（配置示例 / 规则 / 策略组）逐项核对',ext:'yaml',mime:'text/yaml',subInConfig:true,processRules:false,status:'闭源；本版已按官方配置示例输出完整配置（节点、策略组、规则、DNS）',importHint:'「配置」→ 新建 → 粘贴。订阅用「外部资源策略组」，规则集是 Surge 格式 .list。'},
];
export const PLATFORMS:{id:Platform;name:string}[]=[{id:'windows',name:'Windows'},{id:'ios',name:'iOS'},{id:'android',name:'Android'},{id:'macos',name:'macOS'},{id:'linux',name:'Linux'}];
