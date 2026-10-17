import {makePlan,N,BM7,regionGroup,type Plan,type Rule} from './plan';
import {safeRe} from './mihomo';
import type {State} from './types';
import type {Node} from './nodes';
import {flow,block} from './yaml';
import {iconLines,iconMap,iconsOn} from './icons';

export const SIMPLE_RE:Record<string,string>={HK:'香港|HK|Hong ?Kong|🇭🇰',TW:'台湾|台灣|TW|Taiwan|🇹🇼',JP:'日本|JP|Japan|Tokyo|🇯🇵',SG:'新加坡|SG|Singapore|🇸🇬',KR:'韩国|KR|Korea|Seoul|🇰🇷',US:'美国|US|United States|America|🇺🇸',EU:'欧洲|荷兰|瑞典|芬兰|意大利|西班牙|波兰|Europe|Netherlands|🇪🇺|🇳🇱',UK:'英国|UK|GB|United Kingdom|London|🇬🇧',FR:'法国|France|Paris|🇫🇷',DE:'德国|Germany|Frankfurt|🇩🇪',OT:'其他'};
const HOME_SIMPLE='回国|中国|大陆|China|上海|北京|广州|深圳|🇨🇳';
const nm=(s:string)=>s.replace(/[,=]/g,' ').trim();
const stripOi=(r:string)=>r;
type Fmt='surge'|'loon'|'qx'|'shadowrocket';
const listExt:Record<Fmt,[string,string]>={surge:['Surge','list'],loon:['Loon','list'],qx:['QuantumultX','list'],shadowrocket:['Shadowrocket','list']};
function regionFilter(p:Plan,r:{id:string;regex?:string}){return SIMPLE_RE[r.id]||(r.regex||r.id).replace(/^\(\?i\)/,'')}
function matches(p:Plan,r:{id:string;regex:string}){const re=safeRe(r.regex);return p.nodes.filter(n=>re.test(n.name)).map(n=>nm(n.name))}
/** 把各区/服务组 / 规则展开成通用结构，各格式分别渲染 */
function common(p:Plan,fmt:Fmt){
  const s=p.state;const o=s.opts;
  const fo=o.failover!==false; // 默认开故障转移（故转）
  const regionsUsed=p.regions.filter(r=>!p.nodes.length||p.subs.length||matches(p,r).length);
  const regionNames=regionsUsed.map(r=>regionGroup(r,fo?'故转':'自动'));
  const svcOrder=(first:string)=>{const base=[N.proxy,...regionsUsed.map(r=>regionGroup(r,fo?'故转':'自动')),'DIRECT'];return[first,...base.filter(x=>x!==first)]};
  const polName=(pol:string)=>{const n=p.pname(pol);const m=n.match(/^(.*)-故转$/);if(m){const r=regionsUsed.find(x=>x.name===m[1]);if(!r)return N.proxy;return fo?regionGroup(r,'故转'):regionGroup(r,'自动')}return n};
  const lists:{key:string;url:string;policy:string;comment?:string}[]=[];
  const skipped:string[]=[];
  const seen=new Set<string>();
  const [dir,ext]=listExt[fmt];
  const tgt=(pol:string)=>pol==='DIRECT'?'DIRECT':pol==='REJECT'?'REJECT':polName(pol);
  const svcT=(g:any,pol:string)=>{if(pol==='REJECT')return'REJECT';const x=p.services.find(y=>y.g.id===g.id);return x?x.g.name:tgt(pol)};
  const items:({k:'rule';t:Rule}|{k:'set';url:string;name:string;policy:string;comment?:string})[]=[];
  for(const r of p.rules){
    if(r.t==='site'){
      const g=r.g;let bm=g.bm7;
      if(g.id==='ads')bm=o.ads==='full'?'Advertising':'AdvertisingLite';
      if(r.name==='private')bm='Lan';
      if(!bm){ if(!seen.has('skip'+g.id)){seen.add('skip'+g.id);skipped.push(g.name+(g.id==='apple-cn'||/-cn$|@cn|win-update/.test(g.id)?'':''))}continue}
      if(seen.has('b'+bm))continue;seen.add('b'+bm);
      const pol=(g.id==='cn'||g.id==='private'||g.category==='direct')?tgt(r.p):svcT(g,r.p);
      items.push({k:'set',url:BM7(dir as any,bm,ext),name:bm,policy:pol});
    }else if(r.t==='ip'){ /* bm7 列表已含 IP 段 */ }
    else if(r.t==='rset'){items.push({k:'set',url:r.url,name:'cs_'+r.id.replace(/[^A-Za-z0-9]/g,''),policy:tgt(r.p)})}
    else items.push({k:'rule',t:r});
  }
  return{regionsUsed,regionNames,svcOrder,polName,tgt,items,skipped,fo};
}
function svcGroupLines(p:Plan,c:ReturnType<typeof common>,sep:string){
  const l:string[]=[];
  for(const x of p.services){const f=c.tgt(x.p);l.push(`${x.g.name} = select${sep}${c.svcOrder(f).join(sep)}`)}
  return l;
}
export function nodeLine(n:Node,fmt:Fmt):string|null{
  const name=nm(n.name);
  if(n.type==='socks5'||n.type==='http'){
    const u=n.username||'',pw=n.password||'';const auth=u||pw;
    if(fmt==='surge'||fmt==='shadowrocket'){
      const proto=n.type==='socks5'?(n.tls?'socks5-tls':'socks5'):(n.tls?'https':'http');
      return`${name} = ${proto}, ${n.server}, ${n.port}${auth?`, ${u}, ${pw}`:''}`;
    }
    if(fmt==='loon'){
      if(n.type==='socks5'&&n.tls)return null;
      const proto=n.type==='socks5'?'socks5':(n.tls?'https':'http');
      return`${name} = ${proto},${n.server},${n.port}${auth?`,"${u}","${pw}"`:''}${n.type==='socks5'?',udp=true':''}`;
    }
    if(fmt==='qx'){
      return`${n.type}=${n.server}:${n.port}${u?`, username=${u}`:''}${pw?`, password=${pw}`:''}${n.tls?', over-tls=true, tls-verification=true':''}${n.type==='socks5'?', udp-relay=true':''}, fast-open=false, tag=${name}`;
    }
  }
  if(fmt==='surge'){
    if(n.type==='ss')return`${name} = ss, ${n.server}, ${n.port}, encrypt-method=${n.cipher}, password=${n.password}, udp-relay=true`;
    if(n.type==='trojan')return`${name} = trojan, ${n.server}, ${n.port}, password=${n.password}${n.sni?`, sni=${n.sni}`:''}${n.insecure?', skip-cert-verify=true':''}${n.network==='ws'?`, ws=true, ws-path=${n.path||'/'}${n.host?`, ws-headers=Host:${n.host}`:''}`:''}`;
    if(n.type==='vmess'&&(n.network==='tcp'||n.network==='ws'||!n.network))return`${name} = vmess, ${n.server}, ${n.port}, username=${n.uuid}${n.tls?', tls=true':''}${n.sni?`, sni=${n.sni}`:''}${n.network==='ws'?`, ws=true, ws-path=${n.path||'/'}${n.host?`, ws-headers=Host:${n.host}`:''}`:''}, vmess-aead=true${n.insecure?', skip-cert-verify=true':''}`;
    if(n.type==='hysteria2')return`${name} = hysteria2, ${n.server}, ${n.port}, password=${n.password}${n.sni?`, sni=${n.sni}`:''}${n.insecure?', skip-cert-verify=true':''}`;
    if(n.type==='tuic')return`${name} = tuic-v5, ${n.server}, ${n.port}, password=${n.password}, uuid=${n.uuid}${n.sni?`, sni=${n.sni}`:''}, alpn="${(n.alpn||['h3']).join(',')}"`;
    return null;
  }
  if(fmt==='loon'){
    if(n.type==='ss')return`${name} = Shadowsocks,${n.server},${n.port},${n.cipher},"${n.password}",fast-open=false,udp=true`;
    if(n.type==='trojan')return`${name} = trojan,${n.server},${n.port},"${n.password}"${n.sni?`,sni=${n.sni}`:''},skip-cert-verify=${!!n.insecure}${n.network==='ws'?`,transport=ws,path=${n.path||'/'}${n.host?`,host=${n.host}`:''}`:''},udp=true`;
    if(n.type==='vmess'&&(n.network==='tcp'||n.network==='ws'||!n.network))return`${name} = vmess,${n.server},${n.port},${n.cipher&&n.cipher!=='auto'?n.cipher:'auto'},"${n.uuid}",transport=${n.network==='ws'?'ws':'tcp'}${n.network==='ws'?`,path=${n.path||'/'}${n.host?`,host=${n.host}`:''}`:''},over-tls=${!!n.tls}${n.sni?`,sni=${n.sni}`:''},skip-cert-verify=${!!n.insecure},udp=true`;
    if(n.type==='vless'&&(n.network==='tcp'||n.network==='ws'||!n.network))return`${name} = VLESS,${n.server},${n.port},"${n.uuid}",transport=${n.network==='ws'?'ws':'tcp'}${n.network==='ws'?`,path=${n.path||'/'}${n.host?`,host=${n.host}`:''}`:''},over-tls=${!!n.tls}${n.sni?`,sni=${n.sni}`:''}${n.flow?`,flow=${n.flow}`:''}${n.pbk?`,public-key="${n.pbk}",short-id=${n.sid||''}`:''},udp=true`;
    if(n.type==='hysteria2')return`${name} = Hysteria2,${n.server},${n.port},"${n.password}"${n.sni?`,sni=${n.sni}`:''}${n.obfs?`,salamander-password=${n.obfsPassword||''}`:''},skip-cert-verify=${!!n.insecure},udp=true`;
    return null;
  }
  if(fmt==='qx'){
    if(n.type==='ss')return`shadowsocks=${n.server}:${n.port}, method=${n.cipher}, password=${n.password}, fast-open=false, udp-relay=true, tag=${name}`;
    if(n.type==='trojan')return`trojan=${n.server}:${n.port}, password=${n.password}, ${n.network==='ws'?`obfs=wss, obfs-host=${n.host||n.sni||n.server}, obfs-uri=${n.path||'/'}, `:'over-tls=true, '}${n.network!=='ws'&&n.sni?`tls-host=${n.sni}, `:''}tls-verification=${!n.insecure}, fast-open=false, udp-relay=true, tag=${name}`;
    if(n.type==='vmess'&&(n.network==='tcp'||n.network==='ws'||!n.network))return`vmess=${n.server}:${n.port}, method=${n.cipher&&n.cipher!=='auto'?n.cipher:'chacha20-ietf-poly1305'}, password=${n.uuid}, ${n.network==='ws'?`obfs=${n.tls?'wss':'ws'}, obfs-host=${n.host||n.sni||n.server}, obfs-uri=${n.path||'/'}, `:(n.tls?'obfs=over-tls, ':'')}${n.tls?`tls-verification=${!n.insecure}, `:''}fast-open=false, udp-relay=true, tag=${name}`;
    if(n.type==='vless'&&(n.network==='tcp'||n.network==='ws'||!n.network))return`vless=${n.server}:${n.port}, method=none, password=${n.uuid}, ${n.network==='ws'?`obfs=${n.tls?'wss':'ws'}, obfs-host=${n.host||n.sni||n.server}, obfs-uri=${n.path||'/'}, `:(n.tls?`obfs=over-tls, obfs-host=${n.sni||n.server}, `:'')}${n.pbk?`reality-base64-pubkey=${n.pbk}, reality-hex-shortid=${n.sid||''}, `:''}${n.flow?`vless-flow=${n.flow}, `:''}udp-relay=true, tag=${name}`;
    if(n.type==='anytls')return`anytls=${n.server}:${n.port}, password=${n.password}, over-tls=true${n.sni?`, tls-host=${n.sni}`:''}, udp-relay=true, tag=${name}`;
    return null;
  }
  return null;
}
/** 只保留该格式写得出来的节点：策略组成员不能引用被跳过的节点 */
function sup(p:Plan,fmt:Fmt):Plan{return{...p,nodes:p.nodes.filter(n=>nodeLine(n,fmt))}}
const REAL_IP='localhost,*.local,*.lan,*.in-addr.arpa,*.ip6.arpa,captive.apple.com,*.msftncsi.com,*.msftconnecttest.com,time.*.apple.com,time.*.com,ntp.*.com,*.pool.ntp.org,*.push.apple.com,localhost.ptlogin2.qq.com';
const HARD_DNS='8.8.8.8:53,8.8.4.4:53,1.1.1.1:53,1.0.0.1:53,9.9.9.9:53,208.67.222.222:53,208.67.220.220:53,223.5.5.5:53,223.6.6.6:53,119.29.29.29:53,114.114.114.114:53';
const COMMON_SKIP='127.0.0.1, 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12, 100.64.0.0/10, localhost, *.local, captive.apple.com';
export function genSurge(s:State,plan?:Plan):string{
  const P=plan||makePlan(s);const p=sup(P,'surge');const o=s.opts;const c=common(p,'surge');
  const L:string[]=[`# Lowex 生成 · Surge（已对照官方手册 manual.nssurge.com 逐项核对，未用真机导入）· ${new Date().toISOString().slice(0,10)}`,'# 全部在浏览器本地生成，未上传任何内容。',''];
  L.push('[General]',`ipv6 = ${o.ipv6}`,'loglevel = notify','dns-server = system',`encrypted-dns-server = ${o.dnsCn.join(', ')}`,...(o.ipv6?[]:['ipv6-vif = disabled']),'hijack-dns = *:53',`always-real-ip = ${REAL_IP}`,`skip-proxy = ${COMMON_SKIP}`,`proxy-test-url = ${o.testUrl}`,'test-timeout = 5',`allow-wifi-access = ${o.allowLan}`,'');
  L.push('[Proxy]','DIRECT = direct');let skippedN=0;
  for(const n of P.nodes){const l=nodeLine(n,'surge');if(l)L.push(l);else skippedN++}
  if(skippedN)L.push(`# 已跳过 ${skippedN} 个 Surge 不支持的节点（如 VLESS/Reality）`);
  L.push('','[Proxy Group]');
  // 官方手册（policy-groups/policy-including）：policy-path 是外部节点列表；policy-regex-filter 只作用于外部来源；
  // 多个订阅 → 每个订阅一个隐藏 select 组（policy-path），再用 include-other-group 汇总（iOS 4.12+/Mac 4.5+）。
  // 组行上的 url= 在当前版本无效，测速地址用 [General] 的 proxy-test-url。
  const subs=p.subs;const subG=subs.map((_,i)=>`订阅${i+1}`);
  subs.forEach((x,i)=>L.push(`${subG[i]} = select, policy-path=${x.url}, update-interval=86400, hidden=true`));
  const incl=`include-other-group="${subG.join(',')}"`;
  const allNodes=p.nodes.map(n=>nm(n.name));
  const mem=(names:string[],extra:string)=>{const a=[...(names.length?names:(subs.length?[]:['DIRECT']))];if(subs.length)a.push(incl);if(extra)a.push(extra);return a.join(', ')};
  for(const r of c.regionsUsed){
    const names=matches(p,r);
    const reg=regionFilter(p,r);
    const f=subs.length?`policy-regex-filter=(?i)${reg}`:'';
    L.push(`${regionGroup(r,'自动')} = url-test, ${mem(names,f)}, interval=${o.urlTestInterval}, tolerance=${o.tolerance}`);
    L.push(`${regionGroup(r,'手动')} = select, ${mem(names,f)}`);
    if(c.fo)L.push(`${regionGroup(r,'故转')} = fallback, ${regionGroup(r,'手动')}, ${regionGroup(r,'自动')}, interval=${o.urlTestInterval}`);
  }
  L.push(`全部-自动 = url-test, ${mem(allNodes,'')}, interval=${o.urlTestInterval}, tolerance=${o.tolerance}`);
  L.push(`${N.proxy} = select, ${[...c.regionNames,...c.regionsUsed.map(r=>regionGroup(r,'手动')),'全部-自动','DIRECT'].join(', ')}`);
  if(p.overseas)L.push(`${N.home} = select, ${['DIRECT',subs.length?incl:'',subs.length?`policy-regex-filter=(?i)${HOME_SIMPLE}`:''].filter(Boolean).join(', ')}`);
  L.push(...svcGroupLines(p,c,', '));
  L.push(`${N.final} = select, ${o.unknown==='proxy'?N.proxy:'DIRECT'}, ${N.proxy}, DIRECT`,'');
  L.push('[Rule]');
  for(const it of c.items){
    if(it.k==='set'){L.push(`RULE-SET,${it.url},${it.policy}`);continue}
    const r=it.t;
    switch(r.t){
      case'comment':L.push('// '+r.v);break;
      case'suffix':L.push(`DOMAIN-SUFFIX,${r.v},${r.via&&r.p!=='REJECT'?p.services.find(x=>x.g.id===r.via)?.g.name||c.tgt(r.p):c.tgt(r.p)}`);break;
      case'ipcidr':L.push(`IP-CIDR,${r.v},${c.tgt(r.p)},no-resolve`);break;
      case'quic':L.push('AND,((PROTOCOL,QUIC),(NOT,((GEOIP,CN)))),REJECT-NO-DROP');break;
      case'stun':L.push(`PROTOCOL,STUN,${c.tgt(r.p)}`);break;
      case'wifi':for(const d of r.domains)L.push(`DOMAIN-SUFFIX,${d},${c.tgt(r.p)}`);break;
      case'final':L.push(`GEOIP,CN,${p.overseas?N.home:'DIRECT'}`,`FINAL,${r.p==='PROXY'?N.final:'DIRECT'}`);break;
    }
  }
  if(c.skipped.length)L.push('',`// 以下分组没有可用的 Surge 规则集，已跳过：${c.skipped.join('、')}`);
  return iconLines(L,'surge',P).join('\n')+'\n';
}
export function genLoon(s:State,plan?:Plan):string{
  const P=plan||makePlan(s);const p=sup(P,'loon');const o=s.opts;const c=common(p,'loon');
  const L:string[]=[`# Lowex 生成 · Loon（已对照官方文档 nsloon.app 与 LoonExampleConfig 核对，未用真机导入）· ${new Date().toISOString().slice(0,10)}`,'# 全部在浏览器本地生成，未上传任何内容。',''];
  L.push('[General]',`ip-mode = ${o.ipv6?'dual':'ipv4-only'}`,`skip-proxy = ${COMMON_SKIP}`,'bypass-tun = 10.0.0.0/8,100.64.0.0/10,127.0.0.0/8,169.254.0.0/16,172.16.0.0/12,192.168.0.0/16,224.0.0.0/4,255.255.255.255/32',`doh-server = ${o.dnsCn.join(',')}`,'dns-server = system','sni-sniffing = true',...(o.stun==='reject'?['disable-stun = true']:[]),`allow-wifi-access = ${o.allowLan}`,`proxy-test-url = ${o.testUrl}`,'test-timeout = 5',...(o.stun==='reject'?['disable-stun = true']:[]),'');
  L.push('[Proxy]');let sk=0;for(const n of P.nodes){const l=nodeLine(n,'loon');if(l)L.push(l);else sk++}if(sk)L.push(`# 已跳过 ${sk} 个 Loon 不支持的节点`);
  L.push('','[Remote Proxy]');
  if(p.subs.length)p.subs.forEach((x,i)=>L.push(`${nm(x.name)||'订阅'+(i+1)} = ${x.url}`));else if(!p.nodes.length)L.push('订阅1 = {{SUB_URL_1}}');
  L.push('','[Remote Filter]');
  const subList=p.subs.length?p.subs.map((x,i)=>nm(x.name)||'订阅'+(i+1)):(p.nodes.length?[]:['订阅1']);const subNames=subList.join(',');
  // 官方示例：名称 = NameRegex,订阅别名...,FilterKey = 正则（必须列出订阅别名）
  if(subNames){for(const r of c.regionsUsed)L.push(`${r.id}节点 = NameRegex,${subNames},FilterKey = "(?i)${regionFilter(p,r)}"`);
    if(p.overseas)L.push(`回国节点 = NameRegex,${subNames},FilterKey = "(?i)${HOME_SIMPLE}"`)}
  L.push('','[Proxy Group]');
  const rmem=(r:{id:string;regex:string})=>{const a=[...matches(p,r)];if(subNames)a.push(`${r.id}节点`);return a.length?a.join(','):'DIRECT'};
  for(const r of c.regionsUsed){L.push(`${regionGroup(r,'自动')} = url-test,${rmem(r)},url=${o.testUrl},interval=${o.urlTestInterval},tolerance=${o.tolerance}`);L.push(`${regionGroup(r,'手动')} = select,${rmem(r)}`);if(c.fo)L.push(`${regionGroup(r,'故转')} = fallback,${rmem(r)},url=${o.testUrl},interval=${o.urlTestInterval},max-timeout=3000`)}
  L.push(`全部-自动 = url-test,${[...p.nodes.map(n=>nm(n.name)),...subList].join(',')||'DIRECT'},url=${o.testUrl},interval=${o.urlTestInterval},tolerance=${o.tolerance}`);
  L.push(`${N.proxy} = select,${[...c.regionNames,...c.regionsUsed.map(r=>regionGroup(r,'手动')),'全部-自动','DIRECT'].join(',')}`);
  if(p.overseas)L.push(`${N.home} = select,${subNames?'回国节点,':''}DIRECT`);
  L.push(...svcGroupLines(p,c,','));
  L.push(`${N.final} = select,${o.unknown==='proxy'?N.proxy:'DIRECT'},${N.proxy},DIRECT`,'');
  const rule:string[]=[],remote:string[]=[];
  for(const it of c.items){
    if(it.k==='set'){remote.push(`${it.url}, policy=${it.policy}, tag=${it.name}, enabled=true`);continue}
    const r=it.t;
    switch(r.t){
      case'comment':rule.push('# '+r.v);break;
      case'suffix':rule.push(`DOMAIN-SUFFIX,${r.v},${r.via&&r.p!=='REJECT'?p.services.find(x=>x.g.id===r.via)?.g.name||c.tgt(r.p):c.tgt(r.p)}`);break;
      case'ipcidr':rule.push(`IP-CIDR,${r.v},${c.tgt(r.p)},no-resolve`);break;
      case'quic':rule.push('AND,((PROTOCOL,QUIC),(NOT,((GEOIP,CN)))),REJECT');break;
      case'stun':rule.push(`PROTOCOL,STUN,${c.tgt(r.p)}`);break;
      case'wifi':for(const d of r.domains)rule.push(`DOMAIN-SUFFIX,${d},${c.tgt(r.p)}`);break;
      case'final':rule.push(`GEOIP,CN,${p.overseas?N.home:'DIRECT'}`,`FINAL,${r.p==='PROXY'?N.final:'DIRECT'}`);break;
    }
  }
  L.push('[Rule]',...rule,'','[Remote Rule]',...remote);
  if(c.skipped.length)L.push('',`# 以下分组没有可用的 Loon 规则集，已跳过：${c.skipped.join('、')}`);
  return iconLines(L,'loon',P).join('\n')+'\n';
}
export function genQX(s:State,plan?:Plan):string{
  const p=plan||makePlan(s);const o=s.opts;const c=common(p,'qx');
  const lc=(x:string)=>x==='DIRECT'?'direct':x==='REJECT'?'reject':x;
  const L:string[]=[`# Lowex 生成 · Quantumult X（已对照官方 sample.conf 逐项核对，未用真机导入）· ${new Date().toISOString().slice(0,10)}`,'# 全部在浏览器本地生成，未上传任何内容。',''];
  const drop=[...(o.blockQuic==='foreign'?['QUIC']:[]),...(o.stun==='reject'?['STUN']:[])];
  L.push('[general]',`server_check_url=${o.testUrl}`,'dns_exclusion_list=*.lan, *.local, captive.apple.com',...(drop.length?[`udp_drop_list=${drop.join(', ')}`]:[]),'','[dns]','no-system',`doh-server=${o.dnsCn.join(', ')}`,`${o.ipv6?'':'no-ipv6'}`,'');
  L.push('[policy]');
  for(const r of c.regionsUsed){const rg=regionFilter(p,r);L.push(`url-latency-benchmark=${regionGroup(r,'自动')}, server-tag-regex=(?i)${rg}, check-interval=${o.urlTestInterval}, tolerance=${o.tolerance}, alive-checking=false`);L.push(`static=${regionGroup(r,'手动')}, server-tag-regex=(?i)${rg}`);if(c.fo)L.push(`available=${regionGroup(r,'故转')}, server-tag-regex=(?i)${rg}`)}
  L.push(`url-latency-benchmark=全部-自动, server-tag-regex=.*, check-interval=${o.urlTestInterval}, tolerance=${o.tolerance}, alive-checking=false`);
  L.push(`static=${N.proxy}, ${[...c.regionNames,...c.regionsUsed.map(r=>regionGroup(r,'手动')),'全部-自动','direct'].join(', ')}`);
  if(p.overseas)L.push(`static=${N.home}, direct, server-tag-regex=(?i)${HOME_SIMPLE}`);
  for(const x of p.services){const f=c.tgt(x.p);L.push(`static=${x.g.name}, ${c.svcOrder(f).map(lc).join(', ')}`)}
  L.push(`static=${N.final}, ${lc(o.unknown==='proxy'?N.proxy:'DIRECT')}, ${N.proxy}, direct`,'');
  L.push('[server_remote]');
  if(p.subs.length)p.subs.forEach((x,i)=>L.push(`${x.url}, tag=${nm(x.name)||'订阅'+(i+1)}, update-interval=86400, opt-parser=false, enabled=true`));else if(!p.nodes.length&&!p.appMode)L.push('{{SUB_URL_1}}, tag=订阅1, update-interval=86400, opt-parser=false, enabled=true');
  L.push('','[filter_remote]');
  const fl:string[]=[];
  for(const it of c.items){
    if(it.k==='set'){L.push(`${it.url}, tag=${it.name}, force-policy=${lc(it.policy)}, enabled=true`);continue}
    const r=it.t;
    switch(r.t){
      case'comment':fl.push('; '+r.v);break;
      case'suffix':fl.push(`host-suffix, ${r.v}, ${lc(r.via&&r.p!=='REJECT'?p.services.find(x=>x.g.id===r.via)?.g.name||c.tgt(r.p):c.tgt(r.p))}`);break;
      case'ipcidr':fl.push(`ip-cidr, ${r.v}, ${lc(c.tgt(r.p))}, no-resolve`);break;
      case'quic':fl.push('; QUIC 通过 [general] 的 udp_drop_list 丢弃（官方示例）：会连国内 QUIC 一起丢，浏览器自动回落 TCP');break;
      case'stun':fl.push(r.p==='REJECT'?'; STUN 通过 udp_drop_list 丢弃':'; STUN 走代理：QX 无按端口的官方规则写法，保持默认');break;
      case'wifi':for(const d of r.domains)fl.push(`host-suffix, ${d}, ${lc(c.tgt(r.p))}`);break;
      case'final':fl.push(`geoip, cn, ${p.overseas?N.home:'direct'}`,`final, ${lc(r.p==='PROXY'?N.final:'DIRECT')}`);break;
    }
  }
  L.push('','[server_local]');let sk=0;for(const n of p.nodes){const l=nodeLine(n,'qx');if(l)L.push(l);else sk++}if(sk)L.push(`; 已跳过 ${sk} 个 QX 不支持的节点`);
  L.push('','[filter_local]',...fl);
  if(c.skipped.length)L.push('',`; 以下分组没有可用的 QX 规则集，已跳过：${c.skipped.join('、')}`);
  return iconLines(L,'qx',p).join('\n')+'\n';
}
export function genShadowrocket(s:State,plan?:Plan):string{
  const p=plan||makePlan(s);const o=s.opts;const c=common(p,'shadowrocket');
  const L:string[]=[`# Lowex 生成 · Shadowrocket（已对照社区手册 LOWERTOP/Shadowrocket 与配置样例核对，未用真机导入）· ${new Date().toISOString().slice(0,10)}`,'# 节点/订阅请在 App 首页里添加；下面的分组用正则自动收纳节点。全部在浏览器本地生成。','','[General]',
   `skip-proxy = ${COMMON_SKIP}`,'tun-excluded-routes = 10.0.0.0/8, 127.0.0.0/8, 169.254.0.0/16, 172.16.0.0/12, 192.168.0.0/16, 224.0.0.0/4, 255.255.255.255/32',
   `dns-server = ${o.dnsCn.join(', ')}`,'fallback-dns-server = https://dns.alidns.com/dns-query, https://doh.pub/dns-query',`ipv6 = ${o.ipv6}`,'dns-fallback-system = false','dns-direct-system = false','prefer-ipv6 = false','private-ip-answer = true','dns-direct-fallback-proxy = true','icmp-auto-reply = true',`hijack-dns = ${HARD_DNS}`,`always-real-ip = ${REAL_IP}`,...(o.stun==='reject'?['stun-response-ip = 1.1.1.1']:[]),'udp-policy-not-supported-behaviour = REJECT',
   `block-quic = ${o.blockQuic==='foreign'?'all-proxy':'always-allow'}`,'',...(()=>{const ml=p.nodes.filter(n=>n.manual).map(n=>nodeLine(n,'shadowrocket')).filter(Boolean) as string[];return ml.length?['[Proxy]',...ml,'']:[]})(),'[Proxy Group]'];
  for(const r of c.regionsUsed){L.push(`${regionGroup(r,'自动')} = url-test,url=${o.testUrl},interval=${o.urlTestInterval},timeout=5,tolerance=${o.tolerance},policy-regex-filter=${regionFilter(p,r)}`);L.push(`${regionGroup(r,'手动')} = select,policy-regex-filter=${regionFilter(p,r)}`);if(c.fo)L.push(`${regionGroup(r,'故转')} = fallback,url=${o.testUrl},interval=${o.urlTestInterval},timeout=5,policy-regex-filter=${regionFilter(p,r)}`)}
  L.push(`全部-自动 = url-test,url=${o.testUrl},interval=${o.urlTestInterval},timeout=5,tolerance=${o.tolerance},policy-regex-filter=.*`);
  L.push(`${N.proxy} = select,${[...c.regionNames,...c.regionsUsed.map(r=>regionGroup(r,'手动')),'全部-自动','DIRECT'].join(',')}`);
  if(p.overseas)L.push(`${N.home} = select,DIRECT,policy-regex-filter=${HOME_SIMPLE}`);
  L.push(...svcGroupLines(p,c,','));
  L.push(`${N.final} = select,${o.unknown==='proxy'?N.proxy:'DIRECT'},${N.proxy},DIRECT`,'','[Rule]');
  for(const it of c.items){
    if(it.k==='set'){L.push(`RULE-SET,${it.url},${it.policy}`);continue}
    const r=it.t;
    switch(r.t){
      case'comment':L.push('# '+r.v);break;
      case'suffix':L.push(`DOMAIN-SUFFIX,${r.v},${r.via&&r.p!=='REJECT'?p.services.find(x=>x.g.id===r.via)?.g.name||c.tgt(r.p):c.tgt(r.p)}`);break;
      case'ipcidr':L.push(`IP-CIDR,${r.v},${c.tgt(r.p)},no-resolve`);break;
      case'quic':break;
      case'stun':L.push(`AND,((PROTOCOL,UDP),(OR,((DST-PORT,3478),(DST-PORT,3479),(DST-PORT,5349)))),${c.tgt(r.p)}`);break;
      case'wifi':for(const d of r.domains)L.push(`DOMAIN-SUFFIX,${d},${c.tgt(r.p)}`);break;
      case'final':L.push(`GEOIP,CN,${p.overseas?N.home:'DIRECT'}`,`FINAL,${r.p==='PROXY'?N.final:'DIRECT'}`);break;
    }
  }
  if(c.skipped.length)L.push('',`# 以下分组没有可用的 Shadowrocket 规则集，已跳过：${c.skipped.join('、')}`);
  if(p.nodes.some(n=>!n.manual)||p.subs.length)L.unshift('# 提示：已填的节点链接/订阅不会写进 Shadowrocket 配置，请在 App 里单独添加（手动添加的 SOCKS5/HTTP 节点会写在 [Proxy]）。');
  return L.join('\n')+'\n';
}
/** Egern 节点 → 官方配置示例（egernapp.com/docs/configuration/example）里的写法；文档没写的传输（reality/grpc 等）跳过 */
export function egernProxy(n:Node):Record<string,any>|null{
  const base={name:n.name,server:n.server,port:n.port};
  const tr=()=>{if(n.network==='ws')return n.tls?{wss:{path:n.path||'/',sni:n.sni||n.host||n.server}}:{ws:{path:n.path||'/'}};return undefined};
  switch(n.type){
    case'socks5':if(n.tls)return null;return{socks5:{...base,...(n.username?{username:n.username}:{}),...(n.password?{password:n.password}:{}),udp_relay:true}};
    case'http':return{[n.tls?'https':'http']:{...base,...(n.username?{username:n.username}:{}),...(n.password?{password:n.password}:{}),...(n.tls?{sni:n.server}:{})}};
    case'ss':if(n.plugin)return null;return{shadowsocks:{...base,method:n.cipher,password:n.password,udp_relay:true}};
    case'trojan':if(n.network&&n.network!=='tcp')return null;return{trojan:{...base,password:n.password,sni:n.sni,...(n.insecure?{skip_tls_verify:true}:{}),udp_relay:true}};
    case'vmess':{if(n.network&&n.network!=='tcp'&&n.network!=='ws')return null;const t=tr();return{vmess:{...base,user_id:n.uuid,security:n.cipher||'auto',legacy:!!n.alterId,...(t?{transport:t}:{}),udp_relay:true}}}
    case'vless':{if(n.pbk||(n.network&&n.network!=='tcp'&&n.network!=='ws'))return null;if(n.tls&&n.network!=='ws')return null;const t=tr();return{vless:{...base,user_id:n.uuid,...(t?{transport:t}:{}),udp_relay:true}}}
    case'hysteria2':return{hysteria2:{...base,auth:n.password,sni:n.sni,...(n.obfs?{obfs:n.obfs,obfs_password:n.obfsPassword}:{}),skip_tls_verify:!!n.insecure}};
    case'tuic':return{tuic:{...base,uuid:n.uuid,password:n.password,udp_relay_mode:n.udpRelay||'native',alpn:n.alpn||['h3'],sni:n.sni}};
  }
  return null;
}
export function genEgern(s:State,plan?:Plan):string{
  const p=plan||makePlan(s);const o=s.opts;const c=common(p,'surge');
  const hdr=`# Lowex 生成 · Egern（已对照官方文档 egernapp.com 的配置示例与规则文档核对，未用真机导入）· ${new Date().toISOString().slice(0,10)}\n# 订阅用「外部资源策略组」（external）按正则收纳节点；规则集直接引用 Surge 格式 .list（Egern FAQ 说明支持）。\n`;
  const proxies:any[]=[];let skipped=0;for(const n of p.nodes){const e=egernProxy(n);if(e)proxies.push(e);else skipped++}
  const okNames=new Set(proxies.map(x=>Object.values(x)[0] as any).map((x:any)=>x.name));
  const regionsUsed=p.regions.filter(r=>p.subs.length||proxies.some(px=>safeRe(r.regex).test((Object.values(px)[0] as any).name)));
  const pg:any[]=[];
  const pol0=(x:string)=>x;
  const subUrls=p.subs.map(x=>x.url);
  const allMan=[...okNames];
  const manNames:string[]=[],autoNames:string[]=[],foNames:string[]=[];
  const useFo=o.failover!==false;
  for(const r of regionsUsed){
    const man=regionGroup(r,'手动'),au=regionGroup(r,'自动'),fo=regionGroup(r,'故转');
    const local=[...okNames].filter(n=>safeRe(r.regex).test(n));
    if(subUrls.length){pg.push({external:{name:man,type:'select',urls:subUrls,filter:r.regex.replace(/^\(\?i\)/,''),interval:600,update_interval:86400}});manNames.push(man)}
    if(local.length){pg.push({auto_test:{name:au,policies:local,interval:o.urlTestInterval,tolerance:o.tolerance,timeout:5}});autoNames.push(au);if(!subUrls.length){pg.push({select:{name:man,policies:local}});manNames.push(man)}}
    if(useFo&&(manNames.includes(man)||autoNames.includes(au))){const pols=[manNames.includes(man)?man:null,autoNames.includes(au)?au:null].filter(Boolean) as string[];if(pols.length){pg.push({fallback:{name:fo,policies:pols,interval:o.urlTestInterval,timeout:5}});foNames.push(fo)}}
  }
  if(!subUrls.length&&!manNames.length&&!autoNames.length&&!okNames.size)pg.push({select:{name:'全部-手动',policies:['DIRECT']}}),manNames.push('全部-手动');
  if(allMan.length){pg.push({auto_test:{name:'全部-自动',policies:allMan,interval:o.urlTestInterval,tolerance:o.tolerance,timeout:5}});autoNames.push('全部-自动')}
  if(subUrls.length){pg.push({external:{name:'全部-订阅',type:'select',urls:subUrls,filter:'.*',interval:600,update_interval:86400}});manNames.push('全部-订阅')}
  const proxyOpts=[...(useFo?foNames:[]),...autoNames,...manNames,'DIRECT'];
  pg.unshift({select:{name:N.proxy,policies:proxyOpts}});
  if(p.overseas)pg.push(subUrls.length?{external:{name:N.home,type:'select',urls:subUrls,filter:'回国|中国|大陆|China|上海|北京|广州|深圳|🇨🇳',interval:600,update_interval:86400}}:{select:{name:N.home,policies:['DIRECT']}});
  const known=new Set<string>([N.proxy,N.final,N.home,'DIRECT','REJECT',...autoNames,...manNames,...foNames,...p.services.map(x=>x.g.name)]);
  const pol=(x:string)=>{if(known.has(x))return x;const m=/^(.*)-(自动|故转)$/.exec(x);if(m){const fo=m[1]+'-故转';if(known.has(fo))return fo;const man=m[1]+'-手动';if(known.has(man))return man}return N.proxy};
  const polName=(x:string)=>pol(c.tgt(x));
  const opts=(first:string)=>{const base=[N.proxy,...(useFo?foNames:[]),...autoNames,...manNames,'DIRECT',...(p.overseas?[N.home]:[])];return[first,...base.filter(v=>v!==first)]};
  for(const x of p.services){const f=polName(x.p);pg.push({select:{name:x.g.name,policies:opts(f==='REJECT'?N.proxy:f)}})}
  pg.push({select:{name:N.final,policies:[o.unknown==='proxy'?N.proxy:'DIRECT',N.proxy,'DIRECT']}});
  // 规则
  const rules:string[]=[];
  const R=(k:string,m:Record<string,any>)=>rules.push(`  - ${k}: ${flow(m)}`);
  for(const it of c.items){
    if(it.k==='set'){R('rule_set',{match:it.url,policy:pol(it.policy),update_interval:86400});continue}
    const r=it.t;
    switch(r.t){
      case'comment':rules.push('  # '+r.v);break;
      case'suffix':R('domain_suffix',{match:r.v,policy:pol(r.via&&r.p!=='REJECT'?p.services.find(x=>x.g.id===r.via)?.g.name||c.tgt(r.p):c.tgt(r.p))});break;
      case'ipcidr':R('ip_cidr',{match:r.v,policy:pol(c.tgt(r.p)),no_resolve:true});break;
      case'quic':R('and',{match:[{protocol:{match:'quic'}},{not:{match:{geoip:{match:'CN'}}}}],policy:'REJECT'});break;
      case'stun':R('protocol',{match:'stun',policy:pol(c.tgt(r.p))});break;
      case'wifi':for(const d of r.domains)R('domain_suffix',{match:d,policy:pol(c.tgt(r.p))});break;
      case'final':R('geoip',{match:'CN',policy:p.overseas?N.home:'DIRECT',no_resolve:true});R('default',{policy:r.p==='PROXY'?N.final:'DIRECT'});break;
    }
  }
  const dns={bootstrap:(o.dnsBootstrap&&o.dnsBootstrap.length?o.dnsBootstrap:['223.5.5.5']),upstreams:{cn:o.dnsCn,remote:o.dnsRemote},
    forward:[{domain_suffix:{match:'cn',value:'cn'}},{proxy_rule_set:{match:BM7('Surge','China','list'),value:'cn'}},{wildcard:{match:'*',value:'remote'}}]};
  const top:Record<string,any>={ipv6:o.ipv6,allow_external_connections:o.allowLan,proxy_latency_test_url:o.testUrl,dns};
  let text=hdr+block(top);
  if(skipped)text+=`# 已跳过 ${skipped} 个 Egern 文档里没有对应写法的节点（如 Reality / gRPC / 插件）\n`;
  if(proxies.length)text+='proxies:\n'+proxies.map(x=>`  - ${flow(x)}`).join('\n')+'\n';
  if(iconsOn(p)){const im=iconMap(p);for(const g of pg){const b=Object.values(g)[0] as any;const u=b&&im[b.name];if(u)b.icon=u}}
  text+='policy_groups:\n'+pg.map(x=>`  - ${flow(x)}`).join('\n')+'\n';
  text+='rules:\n'+rules.join('\n')+'\n';
  return text;
}
void stripOi;
