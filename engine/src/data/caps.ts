/** 能力矩阵：每个客户端家族到底支持哪些「可选项」。界面只显示支持的；scripts/caps-test.ts 用「改这个选项 → 生成物是否变化」逐项验证这张表。 */
import type {Family} from './clients';
import {CLIENTS} from './clients';
import type {Opts} from '../engine/types';
export type Feature='tun'|'failover'|'mtu'|'tunStack'|'fakeIp'|'ipv6'|'localPort'|'controller'|'logLevel'|'allowLan'|'dnsCn'|'dnsRemote'|'dnsBootstrap'|'cnDnsMode'|'quic'|'stun'|'unknown'|'ads'|'telemetry'|'trackers'|'icons'|'lowMemory'|'keepAlive'|'testUrl'|'interval'|'tolerance'|'lbGroup'|'nodeFilter'|'campus'|'homeDomain'|'homeHosts'|'homeDns'|'wifi'|'modules'|'mitm';
const ALL:Family[]=['mihomo','singbox','surge','qx','shadowrocket','loon','stash','egern'];
const M:Family[]=['mihomo'],MS:Family[]=['mihomo','singbox'];
export const CAPS:Record<Feature,{keys:(keyof Opts)[];fam:Family[];label:string}>={
 tun:{keys:['tun'],fam:MS,label:'TUN 虚拟网卡'},
 mtu:{keys:['mtu'],fam:MS,label:'TUN MTU'},
 tunStack:{keys:['tunStack'],fam:M,label:'TUN 协议栈'},
 fakeIp:{keys:['fakeIp'],fam:MS,label:'DNS fake-ip'},
 ipv6:{keys:['ipv6'],fam:ALL,label:'IPv6'},
 localPort:{keys:['mixedPort'],fam:['mihomo','singbox','stash'],label:'混合端口'}, // sing-box 移动端不生成 mixed 入站，该选项在移动端无实际作用（待平台维度 gating）
 controller:{keys:['apiPort','secret','panelOrigins'],fam:M,label:'控制 API'},
 logLevel:{keys:['logLevel'],fam:['mihomo','singbox','stash'],label:'日志级别'}, // Surge 的 loglevel 在生成器里写死 notify，不跟随本选项
 allowLan:{keys:['allowLan'],fam:['mihomo','singbox','surge','loon','stash','egern'],label:'允许局域网连接'},
 dnsCn:{keys:['dnsCn','dnsPreset'],fam:ALL,label:'国内 DNS'},
 dnsBootstrap:{keys:['dnsBootstrap'],fam:['mihomo','singbox','stash','egern'],label:'Bootstrap DNS'},
 cnDnsMode:{keys:['cnDnsMode'],fam:MS,label:'国内域名用系统 DNS'},
 dnsRemote:{keys:['dnsRemote'],fam:['mihomo','singbox','stash','egern'],label:'境外 DNS'},
 quic:{keys:['blockQuic'],fam:ALL,label:'拦截境外 QUIC'},
 stun:{keys:['stun'],fam:['mihomo','singbox','surge','qx','shadowrocket','loon','stash','egern'],label:'STUN / WebRTC'},
 unknown:{keys:['unknown'],fam:ALL,label:'未知域名'},
 ads:{keys:['ads'],fam:ALL,label:'广告拦截'},
 telemetry:{keys:['telemetry'],fam:ALL,label:'拦截遥测'},
 icons:{keys:['icons'],fam:['mihomo','stash','surge','loon','qx'],label:'策略组图标'}, // Egern 图标未核实：已移除，iconsOn 会自动停发 Egern 图标
 trackers:{keys:['trackers'],fam:ALL,label:'拦截追踪器'},
 lowMemory:{keys:['lowMemory'],fam:MS,label:'低内存模式'},
 keepAlive:{keys:['keepAlive'],fam:M,label:'TCP 保活'},
 testUrl:{keys:['testUrl'],fam:ALL,label:'测速 URL'},
 interval:{keys:['urlTestInterval'],fam:ALL,label:'测速间隔'},
 failover:{keys:['failover'],fam:['mihomo','surge','qx','shadowrocket','loon','stash','egern'],label:'故障转移（故转）'}, // sing-box 无原生 fallback，用 urltest（选延迟最低的健康节点，挂了自动换）代替，不生成假 fallback 组
 tolerance:{keys:['tolerance'],fam:ALL,label:'切换容差'}, // 仅对 url-test 组有意义；fallback 组按顺序取第一个可用，不比较延迟，故不设 tolerance
 lbGroup:{keys:['lbGroup'],fam:['mihomo','stash'],label:'负载均衡组'},
 nodeFilter:{keys:['nodeInclude','nodeExclude'],fam:['mihomo','singbox','surge','qx','loon','stash','egern'],label:'节点过滤'}, // 两级：粘贴节点在 plan 层全家族过滤；订阅级 filter/exclude-filter 只在 Mihomo/Stash 生效（plan.ts 已警告）
 campus:{keys:['campusDomain','campusCidr'],fam:ALL,label:'校园网认证'},
 homeDomain:{keys:['homeDomain'],fam:ALL,label:'内网域名'},
 homeHosts:{keys:['lanGateway'],fam:M,label:'内网网关（hosts）'},
 homeDns:{keys:['lanDns'],fam:MS,label:'内网 DNS'},
 wifi:{keys:['wifiCalling','mcc','mnc'],fam:ALL,label:'Wi-Fi 通话'},
 modules:{keys:[],fam:['surge','qx','shadowrocket','loon','stash','egern'],label:'模块与脚本'},
 mitm:{keys:[],fam:['surge','qx','shadowrocket','loon','stash'],label:'MITM 与自定义重写'},
};
/** QUIC 三档（9.8+，不把三档混为一个“支持”）：
 *  precise = 精确拦境外（AND + NOT CN，境内 QUIC 不受影响）；
 *  global-drop = 只能全局丢（连国内 QUIC 一起丢，浏览器回落 TCP）；
 *  not-generated = 规则层不生成（Shadowrocket 只有 [General] 的 block-quic 开关，其 all-proxy 语义按社区手册，未真机核实）。 */
export const QUIC_TIERS:Record<Family,'precise'|'global-drop'|'not-generated'>={mihomo:'precise',singbox:'precise',surge:'precise',loon:'precise',stash:'precise',egern:'precise',qx:'global-drop',shadowrocket:'not-generated'};
/** STUN 三档（9.8+）：
 *  port = 按 UDP 端口 OR 逐端口（3478/3479/5349/19302-19309）；
 *  protocol = 按 PROTOCOL,STUN（全端口）；
 *  drop-only = 无按端口规则写法，reject 时只能经 udp_drop_list 按协议名丢。 */
export const STUN_TIERS:Record<Family,'port'|'protocol'|'drop-only'>={mihomo:'port',singbox:'port',shadowrocket:'port',surge:'protocol',loon:'protocol',stash:'protocol',egern:'protocol',qx:'drop-only'};
export const familyOf=(clientId:string):Family=>CLIENTS.find(c=>c.id===clientId)!.family;
export const has=(clientId:string,f:Feature)=>CAPS[f].fam.includes(familyOf(clientId));
/** Opts 的键 → 所属能力（用于过滤「推荐」列表等） */
export const featureOfKey=(k:string):Feature|null=>{for(const [f,c] of Object.entries(CAPS))if((c.keys as string[]).includes(k))return f as Feature;return null};
export const keySupported=(clientId:string,k:string)=>{const f=featureOfKey(k);return f?has(clientId,f):true};
