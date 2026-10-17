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
 localPort:{keys:['mixedPort'],fam:['mihomo','singbox','stash'],label:'混合端口'},
 controller:{keys:['apiPort','secret','panelOrigins'],fam:M,label:'控制 API'},
 logLevel:{keys:['logLevel'],fam:['mihomo','singbox','stash'],label:'日志级别'},
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
 icons:{keys:['icons'],fam:['mihomo','stash','surge','loon','qx','egern'],label:'策略组图标'},
 trackers:{keys:['trackers'],fam:ALL,label:'拦截追踪器'},
 lowMemory:{keys:['lowMemory'],fam:MS,label:'低内存模式'},
 keepAlive:{keys:['keepAlive'],fam:M,label:'TCP 保活'},
 testUrl:{keys:['testUrl'],fam:ALL,label:'测速 URL'},
 interval:{keys:['urlTestInterval'],fam:ALL,label:'测速间隔'},
 failover:{keys:['failover'],fam:['mihomo','surge','qx','shadowrocket','loon','stash','egern'],label:'故障转移（故转）'},
 tolerance:{keys:['tolerance'],fam:ALL,label:'切换容差'},
 lbGroup:{keys:['lbGroup'],fam:['mihomo','stash'],label:'负载均衡组'},
 nodeFilter:{keys:['nodeInclude','nodeExclude'],fam:['mihomo','singbox','surge','qx','loon','stash','egern'],label:'节点过滤'},
 campus:{keys:['campusDomain','campusCidr'],fam:ALL,label:'校园网认证'},
 homeDomain:{keys:['homeDomain'],fam:ALL,label:'内网域名'},
 homeHosts:{keys:['lanGateway'],fam:M,label:'内网网关（hosts）'},
 homeDns:{keys:['lanDns'],fam:MS,label:'内网 DNS'},
 wifi:{keys:['wifiCalling','mcc','mnc'],fam:ALL,label:'Wi-Fi 通话'},
 modules:{keys:[],fam:['surge','qx','shadowrocket','loon','stash','egern'],label:'模块与脚本'},
 mitm:{keys:[],fam:['surge','qx','shadowrocket','loon','stash'],label:'MITM 与自定义重写'},
};
export const familyOf=(clientId:string):Family=>CLIENTS.find(c=>c.id===clientId)!.family;
export const has=(clientId:string,f:Feature)=>CAPS[f].fam.includes(familyOf(clientId));
/** Opts 的键 → 所属能力（用于过滤「推荐」列表等） */
export const featureOfKey=(k:string):Feature|null=>{for(const [f,c] of Object.entries(CAPS))if((c.keys as string[]).includes(k))return f as Feature;return null};
export const keySupported=(clientId:string,k:string)=>{const f=featureOfKey(k);return f?has(clientId,f):true};
