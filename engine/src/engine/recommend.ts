import type {Location,Network,Opts} from './types';
export const NETWORKS:{id:Network;name:string;desc:string}[]=[
 {id:'mobile',name:'中国移动宽带',desc:'家宽'},{id:'telecom',name:'中国电信宽带',desc:'家宽'},{id:'unicom',name:'中国联通宽带',desc:'家宽'},
 {id:'cellular',name:'手机蜂窝数据',desc:'4G/5G'},{id:'campus',name:'校园网',desc:'含认证'},{id:'company',name:'公司网络',desc:'内网 / 公司 VPN'},
 {id:'overseas',name:'海外网络',desc:'人在境外'},{id:'other',name:'其他 / 不确定',desc:'通用'}];
export const LOCATIONS:{id:Location;name:string}[]=[{id:'cn',name:'中国大陆'},{id:'hk',name:'香港'},{id:'mo',name:'澳门'},{id:'tw',name:'台湾'},{id:'overseas',name:'海外'}];
export type Basis='官方'|'经验值'|'未核实';
export interface Rec{key:keyof Opts|'regions'|'note';label:string;value:string;why:string;basis:Basis;patch?:Partial<Opts>;}
const ALI='https://223.5.5.5/dns-query',TX='https://1.12.12.12/dns-query';
export function defaultOpts():Opts{
  const a=new Uint8Array(12);crypto.getRandomValues(a);
  return{ipv6:false,tun:true,mtu:1420,mixedPort:7890,apiPort:9090,secret:Array.from(a,x=>x.toString(16).padStart(2,'0')).join(''),logLevel:'warning',allowLan:false,
  dnsCn:[ALI,TX],dnsRemote:['https://1.1.1.1/dns-query','https://8.8.8.8/dns-query'],fakeIp:true,
  blockQuic:'foreign',stun:'proxy',unknown:'proxy',ads:'lite',telemetry:true,trackers:true,icons:true,lowMemory:false,keepAlive:false,
  testUrl:'https://www.gstatic.com/generate_204',urlTestInterval:1800,
  campusDomain:'',campusCidr:'',homeDomain:'',lanGateway:'',lanDns:'',wifiCalling:false,mcc:'',mnc:'',wifiRegion:'',tunStack:'mixed',
  panelOrigins:['https://metacubexd.pages.dev','https://board.zash.run.place'],nodeInclude:'',nodeExclude:'剩余流量|套餐到期|距离下次重置|官网|过期时间',lbGroup:false,tolerance:50,failover:true};
}
/** 按网络环境 + 所在地给出整套推荐。patch 合并进 Opts；列表里的每一项都带说明与依据。 */
export function recommend(net:Network,loc:Location,platform:string):{patch:Partial<Opts>;list:Rec[];exitTips:string[];regionsOn:string[]}{
  const patch:Partial<Opts>={};const list:Rec[]=[];
  const mobileOS=platform==='ios'||platform==='android';
  const add=(r:Rec)=>{list.push(r);if(r.patch)Object.assign(patch,r.patch)};
  // IPv6
  const v6campus=net==='campus';
  add({key:'ipv6',label:'IPv6',value:'关闭',why:'很多机场节点没有 IPv6 出口；开着会让 AAAA 解析绕过代理造成泄漏。顶层 ipv6、dns.ipv6、TUN 的 inet6 三处联动关闭。'+(v6campus?'（校园网有的对 IPv6 免流/免认证，关掉会损失，可手动打开）':''),basis:'官方',patch:{ipv6:false}});
  // MTU
  let mtu=1420,mwhy='给 WireGuard/QUIC/隧道封装留余量；PPPoE 链路 1492 → 内层 1420 足够。';
  if(net==='cellular'||platform==='android'&&net==='other'){mtu=1400;mwhy='蜂窝链路常有更小的 MTU，1380~1400 更稳。';}
  if(net==='unicom'){mtu=1400;mwhy='联通国际方向大包丢失的报告较多，从 1400 起，仍丢包再降到 1380。';}
  if(net==='company'){mtu=1380;mwhy='公司网络常叠加 IPsec/WireGuard 封装，1380 起试。';}
  if(net==='campus'){mtu=1400;mwhy='校园网设备不明，从 1400 起试；无官方依据。';}
  add({key:'mtu',label:'TUN MTU',value:String(mtu),why:mwhy,basis:'经验值',patch:{mtu}});
  // DNS
  const dnsCn=[ALI,TX];let dwhy='国内域名用阿里 + 腾讯 DoH 直连：加密、可达、CDN 就近解析。';
  if(net==='telecom'){dnsCn.push('https://doh.pub/dns-query');dwhy+=' 电信可以再加 doh.pub 做备用。'}
  let remote=['https://1.1.1.1/dns-query','https://8.8.8.8/dns-query'];let rwhy='境外域名走境外 DoH，经代理发出（respect-rules），避免明文被污染；不用 fallback / fallback-filter。';
  if(loc==='hk'||loc==='tw'||loc==='mo'){rwhy+=' 港澳台可直连 1.1.1.1/8.8.8.8，不一定需要经代理。'}
  add({key:'dnsCn',label:'国内 DNS（DoH）',value:dnsCn.join('、'),why:dwhy,basis:'经验值',patch:{dnsCn}});
  add({key:'dnsRemote',label:'境外 DNS（DoH）',value:remote.join('、'),why:rwhy,basis:'经验值',patch:{dnsRemote:remote}});
  add({key:'fakeIp',label:'DNS 模式',value:'fake-ip',why:'先返回假 IP，真正解析推迟到出口端：防 DNS 泄漏、速度快；国内/局域网域名自动放进 fake-ip-filter。',basis:'官方',patch:{fakeIp:true}});
  // QUIC
  const quic=loc==='overseas'||net==='overseas'?'off':'foreign';
  add({key:'blockQuic',label:'QUIC',value:quic==='off'?'放行':'拦截境外 QUIC（回落 TCP）',why:quic==='off'?'人在海外直连境外服务，不必拦 QUIC。':'境外 UDP/QUIC 在国内线路上常被限速或丢包，拦掉让浏览器回落 TCP 更稳；国内 QUIC 不受影响。联通 / 电信 UDP 质量参差，这项更建议开。',basis:'经验值',patch:{blockQuic:quic}});
  // STUN
  add({key:'stun',label:'STUN / WebRTC',value:'走代理',why:'防止 WebRTC 暴露真实 IP；要求节点支持 UDP。节点不支持 UDP 时音视频会断，请改为「拦截」。',basis:'经验值',patch:{stun:'proxy'}});
  // keepalive
  const ka=net==='cellular'||mobileOS;
  add({key:'keepAlive',label:'TCP 保活（keep-alive 600/30）',value:ka?'开':'关',why:ka?'蜂窝 / 移动设备 NAT 老化短，保活更稳也更省电。':'桌面有线 / 宽带可不设。',basis:'经验值',patch:{keepAlive:ka}});
  // tun
  add({key:'tun',label:'TUN 虚拟网卡',value:'开',why:'接管全局流量，按进程 / 包名规则才完整生效。只用系统代理时可关。'+(platform==='android'?' 安卓请先关系统「私人 DNS」，否则 DNS 劫持失效（官方说明）。':''),basis:'官方',patch:{tun:true}});
  // ads / trackers
  add({key:'ads',label:'广告拦截 + 追踪器拦截',value:'Lite + 追踪器',why:'广告规则集 + 约 70 个常见追踪 / 分析 SDK 域名一并拒绝（各客户端自动用 REJECT 写法，只拒绝域名、不需要 MITM）。iOS 内存紧，用 Lite；桌面想要更全可手动选完整版。出问题时先关本项。',basis:'经验值',patch:{ads:'lite',trackers:true}});
  // low memory
  add({key:'lowMemory',label:'低内存模式',value:platform==='ios'?'开':'关',why:'iOS 的 VPN 扩展内存上限很低：用 lru 缓存、3 天更新规则集、广告规则用 Lite 版。',basis:'经验值',patch:{lowMemory:platform==='ios',ads:'lite'}});
  // unknown
  const unk=loc==='overseas'||net==='overseas'?'direct':'proxy';
  add({key:'unknown',label:'未知域名（两边规则都没命中）',value:unk==='proxy'?'走代理（保守防泄漏）':'直连',why:unk==='proxy'?'geolocation-!cn 放在 cn 之前：新站默认走代理，更保守；代价是少量国内新站绕路。':'人在海外时境外服务直连即可，国内服务才走「回国」线路。',basis:'官方',patch:{unknown:unk}});
  // location
  if(loc==='overseas'||net==='overseas'){add({key:'note',label:'回国线路',value:'国内服务 → 回国',why:'国内域名 / IP 的出口从「直连」换成「回国」组（订阅里需有回国线路，节点名含 回国/CN/中国/上海/北京/🇨🇳）。机场是否提供回国线路未核实；没有的话只能整体走代理。国内 DoH 会经回国节点发出（respect-rules）。',basis:'未核实'});}
  if(net==='campus'){add({key:'note',label:'校园网认证直连',value:'需要填认证域名 / IP 段',why:'认证门户的域名和 IP 必须直连并放在最前；先登录认证再开 TUN，掉线后关 TUN 重新认证；不要开 allow-lan 共享热点（部分校园网检测共享）；无法保证绕过检测。',basis:'经验值'});}
  if(net==='company'){add({key:'note',label:'公司网络',value:'内网域名 / 公司 VPN',why:'公司内网域名用「家庭 / 内网」那组填内网 DNS；公司 VPN 的网段不要走代理（生成器把内网域名放进 fake-ip-filter 和直连）。',basis:'经验值'});}
  if(net==='mobile'||net==='telecom'||net==='unicom'){add({key:'note',label:'光猫 / 路由器域名',value:'可选：填家庭内网域名 + 网关',why:'家宽光猫常带内网域名（用「家庭内网」填写）：直连并从 fake-ip 排除。宽带如果开了 IPv6，务必在客户端关 IPv6，否则 AAAA 绕过代理。',basis:'经验值'});}
  if(net==='telecom')add({key:'note',label:'电信 UDP',value:'UDP 类节点不稳时换 TCP 协议',why:'部分地区电信对境外 UDP（Hysteria2/TUIC/QUIC）有 QoS，不稳时改用 Reality / Trojan 等 TCP 节点。',basis:'经验值'});
  // regions + exit tips
  let regionsOn=['HK','TW','JP','SG','US'];
  const tips:string[]=[];
  tips.push('AI（ChatGPT / Claude 等）：美国 / 日本 / 新加坡；香港节点多数被拒（以服务商政策为准），避免频繁切换。');
  tips.push('流媒体：按目标片库选地区，用机场标注的「解锁」节点，别用自动组随意换地区。');
  tips.push('加密货币 / 银行：账号所在地的合规地区，固定一个手动节点，不要自动测速。');
  tips.push('开发（GitHub / Docker）：香港 / 新加坡 / 日本，延迟低。');
  tips.push('游戏：国服直连；国际服选就近、支持 UDP 的节点。');
  if(loc==='hk'||loc==='tw'||loc==='mo'){tips.push('港澳台：国内域名可直连，不一定需要全局代理；Netflix / Disney 看节点地区。');regionsOn=['HK','TW','JP','SG','US','UK'];}
  if(loc==='overseas'){regionsOn=['US','UK','JP','SG','HK','DE'];}
  return{patch,list,exitTips:tips,regionsOn};
}
