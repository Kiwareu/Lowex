import {RESEARCH} from '../data/research';
import {CLIENTS} from '../data/clients';
import {APPS} from '../data/apps';
import {GROUPS,CORE,DIRECT_EXC,REGIONS,GROUP_BY_ID,type RuleGroup,type Region} from '../data/groups';
import type {State,Policy} from './types';
import {parseNodes,type Node} from './nodes';
import {manualToNode,manualIssue} from './manual';

export type Rule=
 |{st?:string}&(
 |{t:'suffix';v:string;p:Policy;via?:string}|{t:'ipcidr';v:string;p:Policy}|{t:'process';v:string;p:Policy}|{t:'package';v:string;p:Policy}
 |{t:'site';name:string;g:RuleGroup;p:Policy}|{t:'ip';name:string;g:RuleGroup;p:Policy}
 |{t:'rset';id:string;name:string;url:string;kind:'domain'|'ip'|'classical';p:Policy}|{t:'quic'}|{t:'stun';p:Policy}|{t:'wifi';domains:string[];p:Policy}|{t:'final';p:Policy}|{t:'comment';v:string});
export const STAGES:{id:string;title:string;desc:string}[]=[
 {id:'special',title:'① 特殊网络（最先）',desc:'校园网认证、家庭/公司内网、局域网、Wi-Fi 通话。这些放最前面，防止被后面的规则误伤。'},
 {id:'custom',title:'② 自定义域名',desc:'你手填的域名和自定义规则集（URL），优先级高于「按 App」和服务分组。'},
 {id:'app',title:'③ 按 App',desc:'Windows 按进程名、Android 按包名；iOS 做不到按 App，会改写到对应服务组。'},
 {id:'builtin',title:'④ 内置保护',desc:'STUN、微信/支付宝等国内常用域名直连、Apple/Steam/微软 的国内节点直连。'},
 {id:'block',title:'⑤ 拦截',desc:'广告与遥测。放在服务分流之前，所以服务异常时先试试关广告拦截。'},
 {id:'service',title:'⑥ 服务分组',desc:'你在「服务分组」里打开的 AI、流媒体、社交、银行、加密货币等，具体的在前，大类在后。'},
 {id:'final',title:'⑦ 兜底',desc:'国内域名与 IP 直连；其余按「未知域名」设置走代理或直连。'},
];

export type SetFmt='mrs'|'yaml'|'text'|'srs'|'json'|'unknown';
export function setFmt(url:string):SetFmt{const u=url.split(/[?#]/)[0].toLowerCase();
  if(u.endsWith('.mrs'))return'mrs';if(u.endsWith('.yaml')||u.endsWith('.yml'))return'yaml';if(u.endsWith('.srs'))return'srs';if(u.endsWith('.json'))return'json';
  if(u.endsWith('.list')||u.endsWith('.txt')||u.endsWith('.conf'))return'text';return'unknown'}
/** 某个客户端家族能不能直接引用这种格式的远程规则集；不能时返回原因 */
export function setProblem(fam:string,url:string,kind:string):string|null{
  const f=setFmt(url);
  if(!/^https:\/\//i.test(url))return'必须是 https:// 开头的链接';
  if(fam==='mihomo'){if(f==='srs'||f==='json')return'Mihomo 不支持 sing-box 的 .srs/.json 规则集';if(f==='mrs'&&kind==='classical')return'.mrs 只能是「域名」或「IP」类型';if(f==='unknown')return'无法从扩展名判断格式（支持 .mrs / .yaml / .list / .txt）';return null}
  if(fam==='stash'){if(f==='mrs'||f==='srs'||f==='json')return'Stash 不支持 .mrs/.srs/.json 规则集，请用 .yaml 或 .list';if(f==='unknown')return'无法从扩展名判断格式';return null}
  if(fam==='singbox'){if(f==='srs'||f==='json')return null;return'sing-box 只能直接引用 .srs（二进制）或 .json（源码）规则集；.list/.yaml/.mrs 需要先用 sing-box rule-set convert 转换'}
  if(f==='text')return null;return'这个客户端只能引用 .list / .txt 文本规则集（每行如 DOMAIN-SUFFIX,example.com）'}
export interface Conflict{level:'info'|'warn';text:string}
export interface Plan{
  state:State;regions:Region[];services:{g:RuleGroup;p:Policy}[];rules:Rule[];warnings:string[];
  nodes:Node[];appMode:boolean;badNodes:number;subs:{name:string;url:string}[];overseas:boolean;
  pname:(p:Policy)=>string;conflicts:Conflict[];
}
export const N={proxy:'一键代理',direct:'DIRECT',reject:'REJECT',home:'回国',update:'资源更新',final:'漏网之鱼'};
export const regionGroup=(r:Region,kind:'手动'|'自动'|'故转')=>`${r.name}-${kind}`;
/** 分层预设 A/B（9.8+）：A = 有故障转移（服务组 → 地区-故转 → 自动/手动 → 节点）；
 *  B = 无故障转移（服务组 → 地区-自动 → 手动/自动 → 节点）。
 *  由 opts.failover 控制（默认 true = A）。sing-box 无原生 fallback，A 在
 *  sing-box 下自动降级为地区-自动（见 singbox.ts 的 -故转 → -自动映射）。 */
export const presetMode=(s:State):'A'|'B'=>s.opts.failover===false?'B':'A';
export const HOME_REGEX='(?i)(回国|中国|大陆|(?<![a-zA-Z])cn(?![a-zA-Z])|china|上海|北京|广州|深圳|🇨🇳)';
import {CARRIERS} from '../data/carriers';
/** 3GPP TS 23.003：ePDG = epdg.epc.mnc<3位MNC>.mcc<MCC>.pub.3gppnetwork.org；IMS = ims.mnc<3位MNC>.mcc<MCC>.3gppnetwork.org */
export const wifiDomainsOf=(mcc:string,mnc:string)=>{const m=mnc.trim().padStart(3,'0');return[`epdg.epc.mnc${m}.mcc${mcc.trim()}.pub.3gppnetwork.org`,`ims.mnc${m}.mcc${mcc.trim()}.3gppnetwork.org`]};
export function wifiAllDomains(s:State):string[]{
  const o=s.opts;if(!o.wifiCalling)return[];const set=new Set<string>();
  for(const id of s.wifi?.ids||[]){const c=CARRIERS.find(x=>x.mcc+'-'+x.mnc===id);if(c){wifiDomainsOf(c.mcc,c.mnc).forEach(d=>set.add(d));c.extra.forEach(d=>set.add(d))}}
  for(const c of s.wifi?.custom||[])if(/^\d{3}$/.test(c.mcc.trim())&&/^\d{2,3}$/.test(c.mnc.trim()))wifiDomainsOf(c.mcc,c.mnc).forEach(d=>set.add(d));
  if(/^\d{3}$/.test((o.mcc||'').trim())&&/^\d{1,3}$/.test((o.mnc||'').trim()))wifiDomainsOf(o.mcc,o.mnc).forEach(d=>set.add(d));
  for(const d of (s.wifi?.extra||'').split(/[\s,]+/).map(x=>x.trim().toLowerCase()).filter(x=>/^[a-z0-9.-]+\.[a-z]{2,}$/.test(x)))set.add(d);
  return[...set];
}
const SAFE_DIRECT=['weixin.qq.com','wx.qq.com','wechat.com','alipay.com','alipayobjects.com','tenpay.com','unionpay.com','95516.com'];
export const allRegions=(s:State):Region[]=>[...REGIONS,...(s.customRegions||[]).filter(r=>r.id&&r.regex)];
export function makePlan(s:State):Plan{
  const client=CLIENTS.find(c=>c.id===s.client)!;
  const o=s.opts;const warnings:string[]=[];
  const overseas=s.location==='overseas'||s.network==='overseas';
  const regions=allRegions(s).filter(r=>s.regions.includes(r.id));
  const regIds=new Set(regions.map(r=>r.id));
  const parsed0=parseNodes(s.nodesText);const bad=parsed0.bad;
  const reOf=(x:string)=>{try{return x.trim()?new RegExp(x.trim(),'i'):null}catch{return null}};
  const inc=reOf(o.nodeInclude||''),exc=reOf(o.nodeExclude||'');
  // 「在客户端 App 内自己添加」：只有订阅 / 节点能在 App 里全局生效、配置靠名称正则收纳的客户端（QX、Shadowrocket）支持
  const appMode=s.nodeMode==='app'&&RESEARCH[client.id]?.placement==='both';
  const parsedOk=parsed0.nodes.filter(n=>(!inc||inc.test(n.name))&&(!exc||!exc.test(n.name)));
  // 手动节点：不受包含 / 排除过滤；客户端写不出的会被剔除并给出原因
  const manualWarn:string[]=[];const taken=new Set(parsedOk.map(n=>n.name));const manualNodes:Node[]=[];
  for(const m of (appMode?[]:(s.manualNodes||[]))){
    if(m.on===false)continue;
    const why=manualIssue(s.client,m);
    if(why){manualWarn.push(`手动节点「${m.name||m.host}」未写入：${why}。`);continue}
    const nn=manualToNode(m);let base=nn.name,i=1;while(taken.has(nn.name)){i++;nn.name=`${base} ${i}`}taken.add(nn.name);manualNodes.push(nn);
  }
  const nodes=appMode?[]:[...parsedOk,...manualNodes];
  const subs=appMode?[]:s.subs.filter(x=>x.url.trim());
  const fam=CLIENTS.find(c=>c.id===s.client)?.family;
  const norm=(p:Policy):Policy=>{
    if(p.startsWith('R:')&&!regIds.has(p.slice(2).split('/')[0]))return'PROXY';
    if(p==='LB'&&!(o.lbGroup&&(fam==='mihomo'||fam==='stash')))return'PROXY';
    if(p==='HOME'&&!overseas)return'PROXY';
    return p;
  };
  const pname=(p:Policy)=>{p=norm(p);if(p==='PROXY')return N.proxy;if(p==='DIRECT')return N.direct;if(p==='REJECT')return N.reject;if(p==='HOME')return N.home;
    if(p==='ALL/a')return'全部-自动';
    if(p==='ALL/m')return['mihomo','stash','singbox','egern'].includes(fam||'')?'全部-手动':'全部-自动';
    if(p==='LB')return'全部-负载均衡';
    const [base,mode]=p.split('/');const r=regions.find(r=>'R:'+r.id===base);return r?regionGroup(r,mode==='a'?'自动':mode==='m'?'手动':'故转'):N.proxy};
  // 分组
  const gs:Record<string,{on:boolean;policy:Policy}>={...s.groups};
  const eff=(g:RuleGroup)=>({on:gs[g.id]?.on??g.defOn,p:norm(gs[g.id]?.policy??g.def)});
  // 按 App
  const rules:Rule[]=[];
  const appRules:Rule[]=[];
  const mobileOnly=s.platform==='ios';
  for(const a of s.apps){
    const p=norm(a.policy);
    if(a.kind==='domain'){appRules.push({t:'suffix',v:a.value,p});continue}
    if(a.kind==='package'){ if(client.processRules&&s.platform==='android')appRules.push({t:'package',v:a.value,p});else warnings.push(`「${a.label}」：当前客户端/平台不支持按包名分流，已忽略。`);continue}
    if(a.kind==='process'){ if(client.processRules&&s.platform!=='android'&&s.platform!=='ios')appRules.push({t:'process',v:a.value,p});else warnings.push(`「${a.label}」：当前客户端/平台不支持按进程分流，已忽略。`);continue}
    const def=APPS.find(x=>x.id===a.value);if(!def){continue}
    if(client.processRules&&s.platform==='android'&&def.pkg)appRules.push({t:'package',v:def.pkg,p});
    else if(client.processRules&&(s.platform==='windows'||s.platform==='macos'||s.platform==='linux')&&def.exe)appRules.push({t:'process',v:def.exe,p});
    else if(def.group&&GROUP_BY_ID[def.group]){gs[def.group]={on:true,policy:p};warnings.push(`「${def.name}」：${mobileOnly?'iOS':'该平台/客户端'}无法按 App 分流，已改为把「${GROUP_BY_ID[def.group].name}」服务组的出口设为 ${pname(p)}。`)}
    else warnings.push(`「${def.name}」：${mobileOnly?'iOS':'该平台/客户端'}无法按 App 分流，也没有对应的服务组。请改用「自定义域名」。`);
  }
  const services=GROUPS.map(g=>({g,...eff(g)})).filter(x=>x.on&&x.p!=='REJECT'&&x.g.category!=='reject'&&x.g.id!=='games-cn'&&x.g.id!=='pt'&&x.g.id!=='p2p-private').map(x=>({g:x.g,p:x.p}));
  // 规则
  let stage='special';
  const push=(...r:Rule[])=>{for(const x of r)rules.push({...x,st:stage} as Rule)};
  if(o.campusDomain||o.campusCidr){push({t:'comment',v:'校园网认证：必须最先直连'});
    for(const d of o.campusDomain.split(/[\s,]+/).filter(Boolean))push({t:'suffix',v:d,p:'DIRECT'});
    for(const d of o.campusCidr.split(/[\s,]+/).filter(Boolean))push({t:'ipcidr',v:d,p:'DIRECT'});}
  if(o.homeDomain)push({t:'suffix',v:o.homeDomain,p:'DIRECT'});
  if(o.blockQuic==='foreign')push({t:'quic'});
  push({t:'comment',v:'局域网 / 私有地址'});
  push({t:'site',name:'private',g:CORE.private,p:'DIRECT'},{t:'ip',name:'private',g:CORE.private,p:'DIRECT'});
  {const wd=(s.platform==='ios'||s.platform==='android')?wifiAllDomains(s):[];if(wd.length)push({t:'wifi',domains:wd,p:o.wifiRegion==='DIRECT'?'DIRECT':norm(o.wifiRegion?'R:'+o.wifiRegion:'PROXY')})}
  stage='custom';
  if(s.customDomains.length)push({t:'comment',v:'自定义域名（优先于按 App 与服务分组）'});
  for(const c of s.customDomains)if(c.domain.trim())push({t:'suffix',v:c.domain.trim(),p:norm(c.policy)});
  for(const c of s.customSets||[]){if(!c.url.trim())continue;const why=setProblem(fam||'',c.url.trim(),c.kind);
    if(why){warnings.push(`自定义规则集「${c.name||c.url}」已跳过：${why}。`);continue}
    push({t:'rset',id:c.id,name:c.name||('set'+c.id),url:c.url.trim(),kind:c.kind,p:norm(c.policy)})}
  stage='app';
  if(appRules.length)push({t:'comment',v:'按 App 分流'});
  push(...appRules);
  stage='builtin';
  if(o.stun!=='off')push({t:'stun',p:o.stun==='reject'?'REJECT':'PROXY'});
  push({t:'comment',v:'国内常用域名直连（放在广告拦截之前，防误伤）'});
  for(const d of SAFE_DIRECT)push({t:'suffix',v:d,p:'DIRECT'});
  const onIds=new Set(services.map(x=>x.g.id));
  const exMap:Record<string,string>={'apple-cn':'apple','steam-cn':'steam','google-cn':'google','microsoft-cn':'microsoft','win-update':'microsoft'};
  for(const e of DIRECT_EXC){const need=exMap[e.id];if(!need||onIds.has(need))push({t:'site',name:e.geosite,g:{id:e.id,name:e.id,category:'direct',cat:'direct',geosite:[e.geosite],geoip:[],def:'DIRECT',defOn:true,risk:'',notes:e.note},p:'DIRECT'})}
  for(const id of ['games-cn','pt']){const x=GROUPS.find(g=>g.id===id)!;const e=eff(x);if(e.on)for(const n of x.geosite)push({t:'site',name:n,g:x,p:'DIRECT'})}
  const customDirect=GROUPS.find(g=>g.id==='p2p-private');
  // 拦截
  stage='block';
  const adsG=GROUPS.find(g=>g.id==='ads')!,telG=GROUPS.find(g=>g.id==='telemetry')!;
  if(o.ads!=='off'&&eff(adsG).on!==false){push({t:'comment',v:'广告 / 遥测拦截'});push({t:'site',name:'category-ads-all',g:adsG,p:'REJECT'})}
  if(o.telemetry&&eff(telG).on!==false)push({t:'site',name:'category-telemetry',g:telG,p:'REJECT'});
  {const trk=GROUPS.find(g=>g.id==='trackers');
   if(trk&&o.trackers!==false&&eff(trk).on!==false){push({t:'comment',v:'追踪器 / 分析拦截（只拒绝域名）'});for(const d of trk.domains||[])push({t:'suffix',v:d,p:'REJECT',via:'trackers'})}}
  // 服务（具体的在前）
  stage='service';
  const order=[...services];
  const mi=order.findIndex(x=>x.g.id==='microsoft');
  for(const id of ['onedrive','xbox']){const i=order.findIndex(x=>x.g.id===id);if(i>=0&&mi>=0&&i>mi){const [it]=order.splice(i,1);order.splice(mi,0,it)}}
  const custom=order.filter(x=>x.g.custom),std=order.filter(x=>!x.g.custom);
  push({t:'comment',v:'服务分流'});
  for(const x of [...custom,...std]){
    if(x.g.custom){for(const d of x.g.domains||[])push({t:'suffix',v:d,p:x.p,via:x.g.id});continue}
    for(const n of x.g.geosite)push({t:'site',name:n,g:x.g,p:x.p});
  }
  for(const x of std)for(const n of x.g.geoip)push({t:'ip',name:n,g:x.g,p:x.p});
  // 兜底
  stage='final';
  const cnT:Policy=overseas?'HOME':'DIRECT';
  push({t:'comment',v:overseas?'国内服务 → 回国线路；境外直连':'未知域名与国内'});
  if(o.unknown==='proxy')push({t:'site',name:'geolocation-!cn',g:CORE['proxy-fallback'],p:'PROXY'});
  push({t:'site',name:'cn',g:CORE.cn,p:cnT},{t:'ip',name:'cn',g:CORE.cn,p:cnT});
  push({t:'final',p:o.unknown==='proxy'?'PROXY':'DIRECT'});
  if(overseas&&!subs.length&&!nodes.length)warnings.push('海外模式需要订阅里有「回国」线路节点；没有的话「回国」组只会指向直连。');
  if(client.family==='mihomo'||client.family==='stash')warnings.push('「资源更新」组需要先在客户端的控制面板里手动选中一个具体节点（或「一键代理」），选好之后才会生效；没选之前它默认直连。');
  if(appMode)warnings.push('已选「在客户端 App 内自己添加」：配置不含订阅和节点，请在 '+client.name+' 里自行添加；策略组按节点名称里的地区关键词自动收纳。'+(client.family==='mihomo'?'这份 YAML 是覆写内容：请导入为 '+client.name+' 的覆写/扩展配置，不要当作完整订阅替换。':''));
  if(!appMode&&!subs.length&&!nodes.length&&client.subInConfig)warnings.push('还没有填订阅或节点：配置里使用了占位符 {{SUB_URL_1}}，导入前请替换。');
  warnings.push(...manualWarn);
  if(client.family==='shadowrocket'&&!appMode){
    if(subs.length||parsedOk.length)warnings.push('Shadowrocket：本配置不会写入节点链接或订阅 URL（只会写入手动添加的 SOCKS5/HTTP 节点）。请在 Shadowrocket 首页单独添加节点/订阅；策略组用正则从 App 内节点自动收纳。');
    else warnings.push('Shadowrocket：请先在 App 首页添加节点或订阅，再导入本配置（只含规则与策略组）。');
  }
  if(client.family==='singbox'&&!nodes.length)warnings.push('sing-box / Karing 没有订阅字段：请粘贴节点链接或订阅正文（ss://、vmess://、vless:// 等），单独的订阅 URL 无法写进 JSON。');
  void customDirect;
  const conflicts=findConflicts(s,rules,services,pname,regions);
  if((o.nodeExclude||o.nodeInclude)&&(subs.length)&&!(client.family==='mihomo'||client.family==='stash'))warnings.push('「节点过滤」对订阅里的节点只在 Mihomo 系 / Stash 生效；这个客户端只过滤了你粘贴的节点。');
  return{state:s,regions,services,rules,warnings,nodes,appMode,badNodes:bad,subs,overseas,pname,conflicts};
}
/** MetaCubeX 规则集 URL */
export const MC={site:(n:string)=>`https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/${n}.mrs`,ip:(n:string)=>`https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/${n}.mrs`,
  ssite:(n:string)=>`https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite/${n}.srs`,sip:(n:string)=>`https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geoip/${n}.srs`};
export const BM7=(fmt:'Clash'|'Surge'|'QuantumultX'|'Loon'|'Shadowrocket',n:string,ext:string)=>`https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/${fmt}/${n}/${n}.${ext}`;

/** 冲突 / 优先级提示（给人看的，不影响生成） */
function findConflicts(s:State,rules:Rule[],services:{g:RuleGroup;p:Policy}[],pname:(p:Policy)=>string,regions:Region[]):Conflict[]{
  const out:Conflict[]=[];const o=s.opts;
  const mine=[...s.customDomains.filter(c=>c.domain.trim()).map(c=>({d:c.domain.trim().toLowerCase(),p:c.policy,src:'自定义域名'})),
    ...s.apps.filter(a=>a.kind==='domain').map(a=>({d:a.value.trim().toLowerCase(),p:a.policy,src:`按 App「${a.label}」`}))];
  const seen=new Map<string,{p:string;src:string}>();
  for(const m of mine){const x=seen.get(m.d);if(x){out.push({level:x.p===m.p?'info':'warn',text:`「${m.d}」写了两次（${x.src} / ${m.src}）${x.p===m.p?'，出口一样，可以删一条':'，出口不同：靠前的生效，后面那条不会被用到'}。`})}else seen.set(m.d,{p:m.p,src:m.src})}
  const sfx=(a:string,b:string)=>a===b||a.endsWith('.'+b);
  for(const m of mine){
    for(const x of services){
      if(!x.g.custom)continue;
      const hit=(x.g.domains||[]).find(d=>sfx(m.d,d)||sfx(d,m.d));
      if(hit&&pname(m.p)!==pname(x.p))out.push({level:'info',text:`「${m.d}」也在服务组「${x.g.name}」里（${hit}）。你的自定义规则优先，所以它走「${pname(m.p)}」，不会跟着「${x.g.name}」组的出口「${pname(x.p)}」。`});
    }
    for(const d of [...o.campusDomain.split(/[\s,]+/),o.homeDomain].filter(Boolean))if(sfx(m.d,d))out.push({level:'warn',text:`「${m.d}」属于你填的校园网/内网域名「${d}」：特殊网络规则在最前面，它会直连，你给它选的出口不会生效。`});
    if(m.p==='REJECT'&&/(google|apple|microsoft|cloudflare|github)\.com$/.test(m.d))out.push({level:'warn',text:`拦截「${m.d}」可能让很多服务无法使用，请确认。`});
  }
  for(const x of services){if(x.g.risk==='高'&&(x.p==='PROXY'||x.p==='HOME'))out.push({level:'info',text:`「${x.g.name}」风控较敏感，出口建议选某个固定地区（手动组），不要用自动测速，否则 IP 频繁变动可能触发风控。`})}
  for(const [id,g] of Object.entries(s.groups)){const grp=GROUP_BY_ID[id];if(!grp||!g.on)continue;if(g.policy.startsWith('R:')&&!regions.some(r=>'R:'+r.id===g.policy.split('/')[0]))out.push({level:'warn',text:`「${grp.name}」选的地区没有在「节点」页启用，已改为「一键代理」。`})}
  if(o.ads!=='off')out.push({level:'info',text:'广告拦截排在服务分流之前：某个 App 或网站打不开时，先把「广告拦截」调成 Lite 或关闭试试。'});
  if(s.platform==='ios'&&s.apps.length)out.push({level:'info',text:'iOS 不能按 App 分流：你选的 App 已被换成它对应的服务组（见上方提示）。'});
  const dupRules=new Set<string>();for(const r of rules){if(r.t==='suffix'){const k=r.v;if(dupRules.has(k)&&r.st!=='service')out.push({level:'info',text:`域名 ${k} 在规则里出现了多次，只有第一条生效。`});dupRules.add(k)}}
  return out;
}
