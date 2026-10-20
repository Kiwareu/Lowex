/** 「作者自用规则分享」：作者随时可以编辑这个文件来增删条目，不用改界面代码。
 *  每条可以包含：服务分组（groups，id 见 src/data/groups.json）、自定义域名（domains）、自定义规则集（sets）。
 *  出口 policy：'PROXY' | 'DIRECT' | 'REJECT' | 'R:地区id'。
 *  不要放订阅、节点、密钥、个人域名等私人信息。 */
import type {Policy,Opts} from '../engine/types';
export interface SharedEntry{
  id:string;name:string;desc:string;
  groups?:{id:string;policy:Policy}[];
  domains?:{domain:string;policy:Policy}[];
  sets?:{name:string;url:string;kind:'domain'|'ip'|'classical';policy:Policy}[];
  /** 防泄漏 / DNS 等设置（只放不含私人信息的取值：开关、枚举、MTU 等）；「加入」时一并套用 */
  opts?:Partial<Opts>;
  /** 结构说明（给人看，不影响生成） */
  notes?:string[];
}
export const SHARED_UPDATED='2026-10-17';
export const SHARED:SharedEntry[]=[
 {id:'pack-nomad',name:'规则包 · 数字游民银行',desc:'打开 Bunq / SumUp / Maya / Blackcat + 金融科技 / 欧洲银行；出口请自行改成「某地区 · 手动」。不含任何私人订阅。',
  groups:['bunq','sumup','maya','blackcat','fintech','bank-eu','paypal'].map(id=>({id,policy:'PROXY' as Policy}))},
 {id:'pack-crypto',name:'规则包 · 加密货币',desc:'打开通用加密规则集 + Bybit EU / MEXC / Krak / Bitget Wallet；建议固定新加坡或香港手动节点。',
  groups:['crypto','crypto-more','bybit-eu','mexc','krak','bitget-wallet'].map(id=>({id,policy:'PROXY' as Policy}))},
 {id:'daily',name:'日常出海',desc:'AI、YouTube、Netflix、Telegram、GitHub、Google、X 走代理。先用这条打底，再按需要微调。',
  groups:['ai','youtube','netflix','telegram','github','google','twitter'].map(id=>({id,policy:'PROXY' as Policy}))},
 {id:'cn-direct',name:'直连优先直连',desc:'直连域名、局域网、Apple、微软、哔哩哔哩、PT 下载直连，省流量也更快。',
  groups:['cn','private','apple','microsoft','bilibili','pt'].map(id=>({id,policy:'DIRECT' as Policy}))},
 {id:'clean',name:'清爽一点',desc:'拦截广告域名和遥测请求（只拒绝域名，不解密流量，不需要 MITM）。误伤时先关掉这一条。',
  groups:[{id:'ads',policy:'REJECT'},{id:'telemetry',policy:'REJECT'}]},
 {id:'finance',name:'金融与交易所：固定出口',desc:'PayPal、Wise / bunq 等金融科技、海外银行、加密货币平台走代理。这类服务对 IP 地区很敏感：加进来后请到「规则」里把出口改成「某地区 · 手动选节点」，别用自动测速组。',
  groups:['paypal','fintech','bank-overseas','crypto','crypto-more'].map(id=>({id,policy:'PROXY' as Policy}))},
 {id:'dev',name:'开发者常用',desc:'GitHub、Stack Overflow、JetBrains、npm、云平台走代理，加速依赖下载和文档访问。',
  groups:['github','cloud-dev','npm','docker'].map(id=>({id,policy:'PROXY' as Policy}))},
 {id:'author-routing',name:'作者自用方案 · 分组布局',desc:'作者日常在用的分流分组（已去掉订阅、服务器、密码、节点名等一切私人信息，只留结构）。思路：一个总出口「一键代理」，每个服务一个独立策略组，默认跟随总出口；微软 / OneDrive / Apple 默认直连（本地有 CDN）；金融与交易所各自独立成组，方便单独固定节点。',
  groups:[
   ...['ai','youtube','google','github','steam','tiktok','twitter','telegram','netflix','disney','spotify','paypal','meta','line','crypto','fintech','bank-overseas'].map(id=>({id,policy:'PROXY' as Policy})),
   ...['onedrive','microsoft','apple','games-cn','cn-bank-direct','private'].map(id=>({id,policy:'DIRECT' as Policy})),
   ...['ads','telemetry','trackers'].map(id=>({id,policy:'REJECT' as Policy}))],
  domains:[
   ...['bunq.com','bunq.me','bunq.app','sumup.com','sumup.co.uk','sumup.de','sumup.me','sumup.io','maya.ph','paymaya.com','mayabank.ph','bybit.eu','bybit.nl','krak.io','krak.app','krakcard.com','blackcatcard.com','blackcat.app','papaya.eu','bitkeep.com','bitgetwallet.com','speedtest.net','ookla.com'].map(domain=>({domain,policy:'PROXY' as Policy}))],
  notes:['策略组顺序：一键代理 → 各服务组 → 漏网之鱼 → 国内直连 → 资源更新（订阅与规则集的下载出口，默认走一键代理；代理不可用时手动切 DIRECT）。','「资源更新」组需要先在客户端的控制面板里手动选中一个具体节点（或「一键代理」），选好之后才会生效；没选之前它默认直连。','出口三层：每个地区有「手动 / 自动测速 / 故障转移」三个组，故障转移 = 手动优先、自动兜底；总出口里依次列出各地区故障转移、自动、手动，最后是「其他 / 国内直连」。','规则顺序：局域网 → 广告拦截 → 本地游戏直连 → 服务分流（具体服务在前）→ 自定义服务（交易所 / 银行 / 社交，规则集 + 精确域名）→ 非直连域名走一键代理 → 直连域名与 IP 直连 → 漏网之鱼。','规则集全部用 mrs 二进制格式（体积小、省内存），来源 MetaCubeX/meta-rules-dat；自定义服务没有现成规则集的，用精确 DOMAIN-SUFFIX，不用宽泛的 DOMAIN-KEYWORD。','地区识别正则：短代码加单词边界（避免 Germany 被当成英国、Deutschland 被当成欧洲），不含任何节点名或服务商名。']},
 {id:'author-dns',name:'作者自用方案 · DNS 与防泄漏',desc:'作者在 Mihomo 上用的 DNS / 防泄漏设置（只含通用取值）。「加入」会把对应开关套用到当前方案。',
  opts:{ipv6:false,tun:true,mtu:1420,tunStack:'mixed',fakeIp:true,blockQuic:'foreign',stun:'reject',unknown:'proxy',keepAlive:true,telemetry:true,trackers:true},
  notes:['IPv6 全关：顶层、DNS、TUN 三处联动，防止 AAAA 解析绕过代理。','TUN：mixed 协议栈 + strict-route + auto-route + 劫持所有 53 端口（udp 与 tcp），MTU 1420，UDP 超时 300 秒。','DNS：fake-ip（blacklist 模式，局域网 / NTP / 连通性检测域名排除）+ respect-rules（境外查询按规则走代理）；本地、直连用阿里 + 腾讯 DoH；节点域名与直连域名各用独立 nameserver；局域网域名走系统 DNS；关闭 prefer-h3（官方说明与 respect-rules 同开不稳）；use-system-hosts 关。','嗅探：保守模式，只用嗅探结果做规则匹配，不改写目标地址（仅 HTTP 例外）；对 Netflix、TikTok、交易所、WhatsApp、LINE 等强制嗅探；跳过小米 / 推送 / 内网设备域名。','QUIC：拦截境外 UDP 443，回落 TCP；STUN 拦截：WebRTC 拿不到公网地址，零泄漏面（如需网页通话可改「走代理」）。','控制面板：只监听本机，secret 必设，CORS 白名单只列本机和常见面板域名，不用 * ，并开 allow-private-network。','杂项：geo 数据库不用（全部 mrs 规则集）、etag 支持、记住所选节点与 fake-ip 映射、TCP 保活 600/30、find-process-mode strict、订阅与规则集更新间隔 24 小时。']},
];
