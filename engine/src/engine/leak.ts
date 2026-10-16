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
export function leakChecklist(s:State):LeakItem[]{
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
    why:dnsAllEnc?'配置里的国内、境外 DNS 都是 https:// 或 tls://，运营商只看得到「连了 DNS 服务器」，看不到查询内容。':'你填的 DNS 里有明文地址，请改成 https:// 或 tls:// 形式。',});
  add({id:'dns-proxy',group:'DNS',title:'境外域名的 DNS 查询走代理发出',status:rich?'ok':'partial',
    why:core?'respect-rules: true：DNS 连接也按分流规则走，境外 DoH 经代理发出，国内 DoH 直连；proxy-server-nameserver 只负责解析节点自己的域名，避免绕圈。':sb?'境外 DNS 服务器设了 detour 到代理出站；国内规则命中的域名走国内 DoH 直连。':'该客户端没有「DNS 随规则走代理」选项，境外域名的解析可能由国内 DoH 完成（不会泄露内容，但会暴露你在查什么域名给国内 DNS）。'});
  add({id:'dns-mode',group:'DNS',title:'fake-ip（默认）或 redir-host',status:o.fakeIp?'ok':'partial',
    why:o.fakeIp?'fake-ip：应用拿到的是假 IP，真正的 DNS 解析由代理端完成，最不容易泄漏，也更快。国内 / 局域网 / NTP / 连通性检测域名已加入 fake-ip-filter。':'当前是 redir-host（真实解析）：兼容性更好，但本地会先做一次真实 DNS 解析，泄漏面更大。仅在个别程序不兼容 fake-ip 时使用。'});
  add({id:'dns-policy',group:'DNS',title:'nameserver-policy：国内与局域网域名分开解析',status:rich?'ok':'na',
    why:rich?'国内域名用国内 DoH，局域网域名用系统 DNS，其余走境外加密 DNS；direct-nameserver 负责「直连」出口的域名解析。':'此客户端没有按域名指定 DNS 的字段。'});
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
    why:o.blockQuic==='foreign'?'境外 QUIC 被拒绝，浏览器会回落到 TCP+TLS，更稳也更容易被规则识别；国内 QUIC 不拦。':'没有拦截 QUIC：节点不支持 UDP 或 UDP 不稳时，网页可能忽快忽慢。'});
  add({id:'lan',group:'本机/局域网',title:'控制端口与局域网暴露',status:o.allowLan?'off':'ok',
    why:o.allowLan?'allow-lan 已开：局域网内其他设备可以用你的代理，也可能扫到端口。':'只监听 127.0.0.1，随机控制密钥，控制 API 的跨域白名单只含本机与常用面板，不用 *。'});
  add({id:'process',group:'本机/局域网',title:'按进程 / 包名识别',status:rich?'ok':'na',
    why:rich?'find-process-mode: strict 仅在有按 App 规则时才匹配进程，减少开销；桌面端要管理员权限才能识别全部进程。':'此客户端不支持按进程识别。'});
  add({id:'captive',group:'其他',title:'强制门户 / 校时 / 连通性检测',status:core?'ok':'partial',
    why:core?'time.*.com、ntp.*.com、+.pool.ntp.org、connectivitycheck 等已加入 fake-ip-filter，不会因为假 IP 导致校时失败或系统误判「无网络」；校园网认证域名可在「规则 → 特殊网络」里填，会放在规则最前直连。':'已把 captive.apple.com 等放进跳过列表；校园网认证域名请在「特殊网络」填写。'});
  add({id:'sub-dl',group:'其他',title:'订阅 / 规则集的下载出口',status:core?'ok':'partial',
    why:core?'「资源更新」组：首次默认直连，节点就绪后切到「一键代理」，之后不再直连暴露机场域名。':'该客户端的订阅更新走它自己的机制，无法单独指定出口。'});
  return out;
}
