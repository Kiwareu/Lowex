// 防泄漏检查清单：根据当前选择的客户端和参数，逐项给出状态与说明
import type {State} from './types';
import {CLIENTS} from '../data/clients';
export type LeakStatus='ok'|'partial'|'manual'|'off'|'na';
export interface LeakItem{id:string;title:string;status:LeakStatus;why:string;how?:string;link?:{t:string;u:string}[];group:'DNS'|'IP'|'WebRTC'|'本机/局域网'|'其他'}
export const LEAK_SITES={
  ip:{t:'BrowserLeaks · IP',u:'https://browserleaks.com/ip'},
  webrtc:{t:'BrowserLeaks · WebRTC',u:'https://browserleaks.com/webrtc'},
  dns:{t:'BrowserLeaks · DNS',u:'https://browserleaks.com/dns'},
  ipleak:{t:'ipleak.net',u:'https://ipleak.net'},
  dnsleaktest:{t:'dnsleaktest.com',u:'https://www.dnsleaktest.com'},
  ipv6:{t:'test-ipv6.com',u:'https://test-ipv6.com'},
};
export const STATUS_TEXT:Record<LeakStatus,string>={ok:'已防护',partial:'部分',manual:'需你手动',off:'未开启',na:'不适用'};
export function leakChecklist(s:State,text?:string):LeakItem[]{
  const out=leakBase(s);
  return text?applyProbes(s,text,out):out;
}
function leakBase(s:State):LeakItem[]{
  const c=CLIENTS.find(x=>x.id===s.client)!;const o=s.opts;const f=c.family;
  const core=f==='mihomo'||f==='stash';const sb=f==='singbox';const rich=core||sb;
  const enc=(u:string)=>/^(https|tls|quic|h3):\/\//.test(u);
  const dnsAllEnc=[...o.dnsCn,...o.dnsRemote].every(enc);
  const out:LeakItem[]=[];const add=(i:LeakItem)=>out.push(i);
  add({id:'dns-hijack',group:'DNS',title:'不让明文 DNS（UDP/TCP 53）发给运营商',
    status:rich?(o.tun?'ok':'off'):'partial',
    why:rich?(o.tun?`TUN 已开：所有 53 端口的 DNS 请求被内核接管（${sb?'hijack-dns':'dns-hijack any:53'}），再按 DoH 规则转发，不会以明文离开设备。`:'没开 TUN：只有设了系统代理的程序会走内核，其他程序的 DNS 仍可能明文发给运营商。请开启 TUN。'):`${c.name} 靠系统 VPN 接管流量，并用配置里的加密 DNS（DoH）；个别不走 VPN 的系统服务仍可能用系统 DNS，属客户端限制。`,
    link:[LEAK_SITES.dns,LEAK_SITES.dnsleaktest]});
  add({id:'dns-enc',group:'DNS',title:'DNS 使用 DoH / DoT 加密',status:dnsAllEnc?'ok':'partial',
    why:dnsAllEnc?'配置里的本地、境外 DNS 都是 https:// 或 tls://，运营商只看得到「连了 DNS 服务器」，看不到查询内容。':'你填的 DNS 里有明文地址，请改成 https:// 或 tls:// 形式。',});
  add({id:'dns-proxy',group:'DNS',title:'境外域名的 DNS 查询走代理发出',status:rich?'ok':'partial',
    why:core?'respect-rules: true：DNS 连接也按分流规则走，境外 DoH 经代理发出，直连 DoH 直连；proxy-server-nameserver 只负责解析节点自己的域名，避免绕圈。':sb?'境外 DNS 服务器设了 detour 到代理出站；本地规则命中的域名走直连 DoH 直连。':'该客户端没有「DNS 随规则走代理」选项，境外域名的解析可能由直连 DoH 完成（不会泄露内容，但会暴露你在查什么域名给直连 DNS）。'});
  add({id:'dns-mode',group:'DNS',title:'fake-ip（默认）或 redir-host',status:o.fakeIp?'ok':'partial',
    why:o.fakeIp?'fake-ip：应用拿到的是假 IP，真正的 DNS 解析由代理端完成，最不容易泄漏，也更快。本地 / 局域网 / NTP / 连通性检测域名已加入 fake-ip-filter。':'当前是 redir-host（真实解析）：兼容性更好，但本地会先做一次真实 DNS 解析，泄漏面更大。仅在个别程序不兼容 fake-ip 时使用。'});
  add({id:'dns-policy',group:'DNS',title:'nameserver-policy：本地与局域网域名分开解析',status:rich?'ok':'na',
    why:rich?'直连域名用直连 DoH，局域网域名用系统 DNS，其余走境外加密 DNS；direct-nameserver 负责「直连」出口的域名解析。':'此客户端没有按域名指定 DNS 的字段。'});
  add({id:'ecs',group:'DNS',title:'ECS（EDNS Client Subnet）',status:'ok',
    why:'生成的配置不发送 ECS（mihomo 不加 #ecs= 参数、sing-box 不设 client_subnet），所以不会把你的真实网段带给 DNS 服务商。需要「让 CDN 就近返回」时，才建议手动加上代理出口所在地的网段，而不是你本地的。'});
  add({id:'ipv6',group:'IP',title:'IPv6 泄漏',status:o.ipv6?'off':'ok',
    why:o.ipv6?'IPv6 已开启：如果节点不支持 IPv6，浏览器可能走本机 IPv6 直连暴露真实地址。除非节点和网络都完整支持 IPv6，否则建议关闭。':'IPv6 已关闭：DNS 不返回 AAAA，TUN 不接管 IPv6，避免从 IPv6 绕过代理。',
    link:[LEAK_SITES.ipv6,LEAK_SITES.ip]});
  add({id:'tun-strict',group:'IP',title:'TUN 严格路由 / 自动识别出口网卡',status:rich?(o.tun?'ok':'off'):'partial',
    why:rich?(o.tun?`strict-route 和 auto-detect-interface 已开：流量不会绕开 TUN 从物理网卡走，也避免代理自己的连接回环。`:'没开 TUN。'):'此类客户端用系统 VPN 隧道，等价于全局接管；是否「断线即断网」取决于客户端的 Kill Switch 选项（请在 App 内开启，如果有）。'});
  add({id:'sniffer',group:'IP',title:'域名嗅探（sniffer）',status:rich?'ok':'na',
    why:rich?'对 TLS / QUIC / HTTP 嗅探域名用于规则匹配，不改写目标地址（HTTP 除外），避免直接用 IP 访问时规则失效而走错出口。':'此客户端自行处理。'});
  add({id:'geoip',group:'IP',title:'geoip 与 DNS 解析',status:'ok',
    why:'IP 规则都带 no-resolve，不会为了匹配 IP 规则而额外做本地 DNS；不使用 GeoIP 数据库（geo-auto-update: false），全部用 .mrs / .srs 规则集，体积小、可更新。'});
  add({id:'webrtc-stun',group:'WebRTC',title:'STUN / WebRTC 的 UDP 流量',status:o.stun==='off'?'off':(f==='shadowrocket'||f==='qx'||f==='loon'||f==='surge'||f==='egern')?'partial':'ok',
    why:o.stun==='off'?'未处理 STUN：WebRTC 可能直接问 STUN 服务器拿到你的真实公网 IP。':o.stun==='reject'?'STUN 端口（3478-3479、5349、19302-19309）已拦截：WebRTC 拿不到公网地址，通话类网页可能连不上。':'STUN 端口走代理：WebRTC 看到的是代理出口 IP（需要节点支持 UDP）。'+(f==='mihomo'||f==='stash'||sb?'':'　注意：该客户端规则能力有限，仅对能写出规则的部分生效。')});
  add({id:'webrtc-browser',group:'WebRTC',title:'浏览器自身的 WebRTC 泄漏（局域网 IP、绕过代理的 UDP）',status:'manual',
    why:'配置只能管「流量去哪」，管不了浏览器把本机/局域网地址写进 WebRTC 的 ICE 候选。现代 Chrome / Edge 默认用 mDNS 隐藏局域网 IP，但公网 IP 在 TUN 全局接管下已经是出口 IP；仍想彻底关闭，需要在浏览器里设置。',
    how:'Firefox：地址栏输入 about:config，把 media.peerconnection.enabled 设为 false（会让网页视频通话失效）。Chrome / Edge：没有内置开关，安装 uBlock Origin 并在设置里勾选「阻止 WebRTC 泄漏本地 IP」，或安装「WebRTC Leak Prevent」类扩展；Edge 还可在 edge://flags 搜索 WebRTC 相关选项。Safari / iOS：无需处理，系统不暴露局域网 IP。',
    link:[LEAK_SITES.webrtc,LEAK_SITES.ipleak]});
  add({id:'quic',group:'WebRTC',title:'QUIC（UDP 443）',status:o.blockQuic==='foreign'?'ok':'off',
    why:o.blockQuic==='foreign'?'境外 QUIC 被拒绝，浏览器会回落到 TCP+TLS，更稳也更容易被规则识别；直连 QUIC 不拦。':'没有拦截 QUIC：节点不支持 UDP 或 UDP 不稳时，网页可能忽快忽慢。'});
  add({id:'lan',group:'本机/局域网',title:'控制端口与局域网暴露',status:o.allowLan?'off':'ok',
    why:o.allowLan?'allow-lan 已开：局域网内其他设备可以用你的代理，也可能扫到端口。':'只监听 127.0.0.1，随机控制密钥，控制 API 的跨域白名单只含本机与常用面板，不用 *。'});
  add({id:'process',group:'本机/局域网',title:'按进程 / 包名识别',status:rich?'ok':'na',
    why:rich?'find-process-mode: strict 仅在有按 App 规则时才匹配进程，减少开销；桌面端要管理员权限才能识别全部进程。':'此客户端不支持按进程识别。'});
  add({id:'captive',group:'其他',title:'强制门户 / 校时 / 连通性检测',status:core?'ok':'partial',
    why:core?'time.*.com、ntp.*.com、+.pool.ntp.org、connectivitycheck 等已加入 fake-ip-filter，不会因为假 IP 导致校时失败或系统误判「无网络」；校园网认证域名可在「规则 → 特殊网络」里填，会放在规则最前直连。':'已把 captive.apple.com 等放进跳过列表；校园网认证域名请在「特殊网络」填写。'});
  add({id:'sub-dl',group:'其他',title:'订阅 / 规则集的下载出口',status:core?'ok':'partial',
    why:core?'「资源更新」组：首次默认直连，节点就绪后切到「一键代理」，之后不再直连暴露服务商域名。':'该客户端的订阅更新走它自己的机制，无法单独指定出口。'});
  return out;
}

// ───── 从生成出的配置文本里取证：每一项都去文本里找对应字段，找不到就如实降级，不凭「应该有」打分 ─────
type Probe={id:string;fam:string[];re:RegExp;ok:string;miss:string;weakRe?:RegExp};
const PROBES:Probe[]=[
  {id:'dns-hijack',fam:['mihomo'],re:/^tun:\n(?:[ \t]+.*\n)*?[ \t]+enable: true[\s\S]*?dns-hijack/m,ok:'配置里有 tun.enable: true 和 dns-hijack。',miss:'配置里没有开启 TUN 的 dns-hijack。'},
  {id:'dns-hijack',fam:['singbox'],re:/"action": ?"hijack-dns"/,ok:'路由规则里有 hijack-dns。',miss:'路由规则里没有 hijack-dns。'},
  {id:'dns-hijack',fam:['surge'],re:/^hijack-dns *= *\*:53/m,ok:'[General] 里有 hijack-dns = *:53：连写死 DNS 的软件也被接管。',miss:'没有 hijack-dns。'},
  {id:'dns-hijack',fam:['shadowrocket'],re:/^hijack-dns *= *.*8\.8\.8\.8:53/m,ok:'[General] 里有 hijack-dns，覆盖常见硬编码公共 DNS。',miss:'没有 hijack-dns。'},
  {id:'dns-enc',fam:['mihomo','stash'],re:/nameserver:[\s\S]*?https:\/\/|nameserver:[\s\S]*?tls:\/\//,ok:'nameserver 使用 DoH/DoT。',miss:'nameserver 里没有加密 DNS。'},
  {id:'dns-enc',fam:['surge'],re:/^encrypted-dns-server *= *(https|quic|tls)/m,ok:'有 encrypted-dns-server。',miss:'没有 encrypted-dns-server。'},
  {id:'dns-enc',fam:['shadowrocket'],re:/^dns-server *= *(https|h3|quic|tls)/m,ok:'dns-server 为加密 DNS。',miss:'dns-server 不是加密 DNS。'},
  {id:'dns-enc',fam:['qx'],re:/^doh-server *=|^doq-server *=/m,ok:'[dns] 有 doh-server。',miss:'[dns] 没有 doh/doq-server。'},
  {id:'dns-enc',fam:['loon'],re:/^doh-server *= *https/m,ok:'[General] 有 doh-server。',miss:'没有 doh-server。'},
  {id:'dns-enc',fam:['egern'],re:/upstreams:[\s\S]*?https:\/\//,ok:'upstreams 使用 DoH。',miss:'upstreams 里没有加密 DNS。'},
  {id:'dns-enc',fam:['singbox'],re:/"type": ?"(https|tls|quic)"/,ok:'DNS server 为 https/tls。',miss:'没有加密 DNS server。'},
  {id:'dns-proxy',fam:['mihomo'],re:/respect-rules: true/,ok:'有 respect-rules: true。',miss:'没有 respect-rules: true，境外 DNS 可能直连。'},
  {id:'dns-proxy',fam:['singbox'],re:/"detour": ?"[^"]+"/,ok:'境外 DNS server 带 detour。',miss:'境外 DNS 没有 detour。'},
  {id:'dns-mode',fam:['mihomo','stash'],re:/enhanced-mode: fake-ip/,ok:'enhanced-mode: fake-ip。',miss:'不是 fake-ip。'},
  {id:'dns-mode',fam:['singbox'],re:/"type": ?"fakeip"/,ok:'有 fakeip DNS server（官方文档仍保留该类型，sing-box 1.14.3 校验通过）。',miss:'没有 fakeip，使用真实解析。'},
  {id:'dns-policy',fam:['mihomo'],re:/nameserver-policy:/,ok:'有 nameserver-policy。',miss:'没有 nameserver-policy。'},
  {id:'ipv6',fam:['mihomo','stash'],re:/^ipv6: false/m,ok:'顶层 ipv6: false。',miss:'IPv6 没有关闭。'},
  {id:'ipv6',fam:['surge','shadowrocket'],re:/^ipv6 *= *false/m,ok:'ipv6 = false。',miss:'IPv6 没有关闭。'},
  {id:'ipv6',fam:['loon'],re:/^ip-mode *= *ipv4-only/m,ok:'ip-mode = ipv4-only。',miss:'没有 ipv4-only。'},
  {id:'ipv6',fam:['qx'],re:/^no-ipv6/m,ok:'[dns] 有 no-ipv6。',miss:'没有 no-ipv6。'},
  {id:'ipv6',fam:['egern'],re:/^ipv6: false/m,ok:'ipv6: false。',miss:'没有关闭 IPv6。'},
  {id:'ipv6',fam:['singbox'],re:/"strategy": ?"ipv4_only"/,ok:'DNS strategy: ipv4_only。',miss:'没有 ipv4_only。'},
  {id:'tun-strict',fam:['mihomo'],re:/strict-route: true/,ok:'strict-route: true。',miss:'没有 strict-route。'},
  {id:'tun-strict',fam:['singbox'],re:/"strict_route": ?true/,ok:'strict_route: true。',miss:'没有 strict_route。'},
  {id:'sniffer',fam:['mihomo'],re:/^sniffer:/m,ok:'有 sniffer 段。',miss:'没有 sniffer。'},
  {id:'sniffer',fam:['singbox'],re:/"action": ?"sniff"/,ok:'路由有 sniff 动作。',miss:'没有 sniff。'},
  {id:'sniffer',fam:['loon'],re:/^sni-sniffing *= *true/m,ok:'sni-sniffing = true。',miss:'没有 SNI 嗅探。'},
  {id:'webrtc-stun',fam:['shadowrocket'],re:/^stun-response-ip|STUN|3478/m,ok:'有 STUN 处理（stun-response-ip 或规则）。',miss:'没有 STUN 处理。'},
  {id:'webrtc-stun',fam:['loon'],re:/^disable-stun *= *true|3478/m,ok:'有 disable-stun 或 STUN 规则。',miss:'没有 STUN 处理。'},
  {id:'webrtc-stun',fam:['mihomo','singbox','surge','qx','egern','stash'],re:/3478/,ok:'有 3478 STUN 端口规则。',miss:'没有 STUN 端口规则。'},
  {id:'quic',fam:['mihomo','stash','singbox'],re:/DST-PORT,443|"port": ?\[?443|port: ?443|protocol: ?quic|UDP/i,ok:'有 UDP/443 QUIC 规则。',miss:'没有 QUIC 规则。'},
  {id:'quic',fam:['shadowrocket'],re:/^block-quic *= *all-proxy/m,ok:'block-quic = all-proxy。',miss:'没有 block-quic。'},
  {id:'quic',fam:['qx'],re:/^udp_drop_list=.*QUIC/m,ok:'udp_drop_list=QUIC。',miss:'没有 udp_drop_list。'},
  {id:'quic',fam:['surge','loon','egern'],re:/QUIC|quic/,ok:'有 QUIC 规则。',miss:'没有 QUIC 规则。'},
  {id:'dns-sys',fam:['shadowrocket'],re:/^dns-fallback-system *= *false/m,ok:'dns-fallback-system = false：DNS 失败不会悄悄回落到运营商 DNS。',miss:'没有关闭系统 DNS 回落。'},
  {id:'dns-sys',fam:['qx'],re:/^no-system/m,ok:'[dns] 有 no-system：不用系统 DNS。',miss:'没有 no-system。'},
  {id:'real-ip',fam:['surge','shadowrocket'],re:/^always-real-ip *=.*captive\.apple\.com/m,ok:'always-real-ip 已覆盖连通性检测 / 校时 / 局域网域名。',miss:'没有 always-real-ip。'},
];
const EXTRA:Record<string,{group:LeakItem['group'];title:string;fam:string[]}>={
  'dns-sys':{group:'DNS',title:'DNS 失败时不回落到系统 / 运营商 DNS',fam:['shadowrocket','qx']},
  'real-ip':{group:'其他',title:'校时 / 连通性检测 / 局域网域名返回真实 IP',fam:['surge','shadowrocket']},
};
const WEIGHT:Record<string,number>={'dns-hijack':14,'dns-enc':10,'dns-proxy':12,'dns-mode':8,'dns-policy':4,'dns-sys':6,'ecs':3,'ipv6':10,'tun-strict':6,'sniffer':4,'geoip':3,'webrtc-stun':8,'webrtc-browser':4,'quic':4,'lan':3,'process':1,'captive':3,'real-ip':3,'sub-dl':2};
export interface LeakScore{score:number;applicable:number;note:string;items:{id:string;weight:number;credit:number}[]}
export function applyProbes(s:State,text:string,items:LeakItem[]):LeakItem[]{
  const f=CLIENTS.find(x=>x.id===s.client)!.family as string;
  const out=items.map(i=>({...i}));
  for(const pr of PROBES.filter(p=>p.fam.includes(f))){
    let it=out.find(i=>i.id===pr.id);
    const hit=pr.re.test(text);
    if(!it){const e=EXTRA[pr.id];if(!e||!e.fam.includes(f))continue;it={id:pr.id,group:e.group,title:e.title,status:'ok',why:''};out.push(it)}
    if(it.status==='na'&&!hit)continue;
    if(hit){if(it.status==='off'&&pr.id==='ipv6'){/* 用户开启 IPv6 时由选项决定 */}
      else if(it.status!=='manual'){if(it.status==='partial'||it.status==='na')it.status='ok'}
      it.why='【配置取证】'+pr.ok+' '+it.why}
    else{ if(it.status==='ok')it.status='off'; it.why='【配置取证】'+pr.miss+' '+it.why}
  }
  return out;
}
export function leakScore(items:LeakItem[]):LeakScore{
  let got=0,tot=0;const det:LeakScore['items']=[];
  for(const i of items){if(i.status==='na')continue;const w=WEIGHT[i.id]??2;const c=i.status==='ok'?1:i.status==='partial'?0.5:i.status==='manual'?0.5:0;tot+=w;got+=w*c;det.push({id:i.id,weight:w,credit:c})}
  const score=tot?Math.round(got/tot*100):0;
  return{score,applicable:det.length,items:det,note:'分数 = 适用项加权得分 / 适用项总权重；已防护 1 分、部分与「需你手动」各 0.5 分、未开启 0 分，不适用的项不计入。每项状态来自生成出的配置文本里能否找到对应字段。'};
}
