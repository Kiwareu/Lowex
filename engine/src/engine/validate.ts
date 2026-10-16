/** 浏览器内「测试配置」：不联网、不上传。检查结构与引用关系，并按各客户端官方文档核对键名。 */
import {parse as yamlParse} from 'yaml';
import type {Family} from '../data/clients';
export interface Issue{level:'error'|'warn';msg:string;line?:number}
const BUILTIN=new Set(['DIRECT','REJECT','REJECT-DROP','REJECT-TINYGIF','REJECT-NO-DROP','direct','reject','proxy','PROXY','GLOBAL','COMPATIBLE']);

/* ---- Mihomo / Stash（YAML） ---- */
function vMihomo(text:string,stash:boolean):Issue[]{
  const I:Issue[]=[];let y:any;
  try{y=yamlParse(text)}catch(e:any){return[{level:'error',msg:'YAML 解析失败：'+e.message}]}
  if(!y||typeof y!=='object')return[{level:'error',msg:'内容为空或不是 YAML 映射'}];
  const proxies=(y.proxies||[]).map((p:any)=>p.name);const groups:any[]=y['proxy-groups']||[];const gn=groups.map(g=>g.name);
  const dup=(a:string[],what:string)=>{const s=new Set<string>();for(const n of a){if(s.has(n))I.push({level:'error',msg:`${what}重名：${n}`});s.add(n)}};
  dup(proxies,'节点');dup(gn,'策略组');
  const providers=Object.keys(y['proxy-providers']||{});const rps=Object.keys(y['rule-providers']||{});
  const known=new Set([...proxies,...gn,...BUILTIN]);
  for(const g of groups){
    if(!['select','url-test','fallback','load-balance','relay'].includes(g.type))I.push({level:'error',msg:`策略组「${g.name}」类型 ${g.type} 不被支持`});
    for(const m of g.proxies||[])if(!known.has(m))I.push({level:'error',msg:`策略组「${g.name}」引用了不存在的「${m}」`});
    for(const u of g.use||[])if(!providers.includes(u))I.push({level:'error',msg:`策略组「${g.name}」use 了不存在的订阅 ${u}`});
    if(!(g.proxies?.length)&&!(g.use?.length)&&!g['include-all']&&!stash)I.push({level:'warn',msg:`策略组「${g.name}」没有成员`});
    if(g.filter){try{new RegExp(String(g.filter).replace(/^\(\?i\)/,''))}catch{I.push({level:'error',msg:`策略组「${g.name}」的 filter 不是合法正则`})}}
  }
  const rules:string[]=y.rules||[];
  rules.forEach((r,i)=>{
    const parts=String(r).split(',');const t=parts[0];
    if(t==='MATCH'){if(i!==rules.length-1)I.push({level:'error',msg:'MATCH 必须是最后一条规则（后面的规则永远不会生效）'});const tg=parts[1];if(!known.has(tg))I.push({level:'error',msg:`MATCH 指向不存在的「${tg}」`});return}
    if(t==='RULE-SET'){if(!rps.includes(parts[1]))I.push({level:'error',msg:`规则 ${i+1}：规则集 ${parts[1]} 没有在 rule-providers 里声明`});if(!known.has(parts[2]))I.push({level:'error',msg:`规则 ${i+1}：策略「${parts[2]}」不存在`});return}
    if(/^(AND|OR|NOT)$/.test(t))return;
    const tg=parts[2];if(tg&&!known.has(tg)&&!/^\d/.test(tg))I.push({level:'error',msg:`规则 ${i+1}（${t}）：策略「${tg}」不存在`});
  });
  if(!rules.length||!String(rules[rules.length-1]).startsWith('MATCH'))I.push({level:'error',msg:'缺少最后的 MATCH 兜底规则'});
  for(const [k,v] of Object.entries<any>(y['rule-providers']||{})){if(!v.url&&!v.path&&v.type!=='inline')I.push({level:'error',msg:`规则集 ${k} 没有 url`});if(stash&&v.format==='mrs'&&!['domain','ipcidr'].includes(v.behavior))I.push({level:'error',msg:`规则集 ${k}：Stash 的 mrs 只支持 domain / ipcidr`})}
  if(!stash&&y.dns?.['nameserver-policy']){for(const k of Object.keys(y.dns['nameserver-policy']))if(k.startsWith('rule-set:')&&!rps.includes(k.slice(9)))I.push({level:'error',msg:`dns.nameserver-policy 引用了不存在的规则集 ${k}`})}
  const plc=(y.proxies||[]).filter((p:any)=>/\{\{/.test(JSON.stringify(p)));if(plc.length)I.push({level:'warn',msg:'节点里还有占位符 {{…}}'});
  if(/\{\{SUB_URL_\d+\}\}/.test(text))I.push({level:'warn',msg:'配置里还有订阅占位符 {{SUB_URL_1}}，导入前请替换成真实订阅链接'});
  return I;
}
/* ---- sing-box（JSON） ---- */
function vSingbox(text:string):Issue[]{
  const I:Issue[]=[];let j:any;try{j=JSON.parse(text)}catch(e:any){return[{level:'error',msg:'JSON 解析失败：'+e.message}]}
  const outs:any[]=j.outbounds||[];const tags=new Set(outs.map(o=>o.tag));const seen=new Set<string>();
  for(const o of outs){if(seen.has(o.tag))I.push({level:'error',msg:`出站重名：${o.tag}`});seen.add(o.tag);
    for(const m of o.outbounds||[])if(!tags.has(m))I.push({level:'error',msg:`出站「${o.tag}」引用了不存在的「${m}」`});
    if(o.default&&!(o.outbounds||[]).includes(o.default))I.push({level:'error',msg:`出站「${o.tag}」的 default「${o.default}」不在成员里`})}
  const rs=new Set((j.route?.rule_set||[]).map((r:any)=>r.tag));
  for(const r of j.route?.rules||[]){if(r.outbound&&!tags.has(r.outbound))I.push({level:'error',msg:`路由规则指向不存在的出站「${r.outbound}」`});for(const t of [].concat(r.rule_set||[]))if(!rs.has(t))I.push({level:'error',msg:`路由规则用了未声明的规则集 ${t}`})}
  if(j.route?.final&&!tags.has(j.route.final))I.push({level:'error',msg:`route.final「${j.route.final}」不存在`});
  if(!j.route?.final)I.push({level:'warn',msg:'没有 route.final'});
  return I;
}
/* ---- Surge 类（INI）：按官方手册 / 样例整理的键与类型白名单 ---- */
const SECTIONS:Record<string,string[]>={
  surge:['General','Proxy','Proxy Group','Rule'],
  loon:['General','Proxy','Remote Proxy','Remote Filter','Proxy Group','Rule','Remote Rule'],
  shadowrocket:['General','Proxy Group','Rule'],
  qx:['general','dns','policy','server_remote','filter_remote','server_local','filter_local'],
};
const GENERAL_KEYS:Record<string,string[]>={
  surge:['ipv6','loglevel','dns-server','encrypted-dns-server','skip-proxy','proxy-test-url','test-timeout','allow-wifi-access','internet-test-url'],
  loon:['ip-mode','skip-proxy','bypass-tun','doh-server','dns-server','allow-wifi-access','proxy-test-url','test-timeout','disable-stun','internet-test-url'],
  shadowrocket:['skip-proxy','tun-excluded-routes','dns-server','fallback-dns-server','ipv6','private-ip-answer','dns-direct-fallback-proxy','udp-policy-not-supported-behaviour','block-quic'],
  qx:['server_check_url','dns_exclusion_list','udp_drop_list','fallback_udp_policy','network_check_url'],
};
const GROUP_TYPES:Record<string,string[]>={surge:['select','url-test','fallback','load-balance','smart','subnet'],loon:['select','url-test','fallback','load-balance','ssid'],shadowrocket:['select','url-test','fallback','load-balance','random']};
const RULE_TYPES=new Set(['DOMAIN','DOMAIN-SUFFIX','DOMAIN-KEYWORD','DOMAIN-WILDCARD','IP-CIDR','IP-CIDR6','GEOIP','IP-ASN','RULE-SET','DOMAIN-SET','PROTOCOL','DEST-PORT','DST-PORT','AND','OR','NOT','PROCESS-NAME','FINAL','USER-AGENT','URL-REGEX','SRC-IP']);
const RULE_BY:Record<string,Set<string>>={surge:new Set([...RULE_TYPES].filter(x=>x!=='DST-PORT')),loon:new Set([...RULE_TYPES].filter(x=>x!=='DST-PORT'&&x!=='DOMAIN-SET')),shadowrocket:new Set([...RULE_TYPES].filter(x=>x!=='DEST-PORT'&&x!=='PROTOCOL'&&x!=='IP-ASN'&&x!=='DOMAIN-WILDCARD'))};
function sections(text:string){const m=new Map<string,{n:number;t:string}[]>();let cur='';text.split('\n').forEach((raw,i)=>{const t=raw.trim();const h=/^\[(.+)\]$/.exec(t);if(h){cur=h[1];if(!m.has(cur))m.set(cur,[]);return}if(!t||t.startsWith('#')||t.startsWith('//')||t.startsWith(';'))return;if(cur)m.get(cur)!.push({n:i+1,t})});return m}
const splitTop=(s:string)=>{const out:string[]=[];let d=0,q=false,cur='';for(const ch of s){if(ch==='"')q=!q;if(!q){if(ch==='(')d++;if(ch===')')d--}if(ch===','&&d===0&&!q){out.push(cur.trim());cur=''}else cur+=ch}out.push(cur.trim());return out};
function vIni(text:string,fam:'surge'|'loon'|'shadowrocket'):Issue[]{
  const I:Issue[]=[];const sec=sections(text);
  for(const k of sec.keys())if(!SECTIONS[fam].includes(k))I.push({level:'warn',msg:`未知段落 [${k}]（不在 ${fam} 文档列出的段落里）`});
  for(const e of sec.get('General')||[]){const k=e.t.split('=')[0].trim();if(!GENERAL_KEYS[fam].includes(k))I.push({level:'warn',msg:`[General] 键 ${k} 不在已核对的官方文档里`,line:e.n})}
  const names=new Set<string>(['DIRECT','REJECT','REJECT-NO-DROP','REJECT-DROP','REJECT-TINYGIF','direct','reject']);
  const filters=new Set<string>();
  for(const e of sec.get('Proxy')||[]){const n=e.t.split('=')[0].trim();if(n)names.add(n)}
  for(const e of sec.get('Remote Proxy')||[]){const n=e.t.split('=')[0].trim();if(n)names.add(n)}
  for(const e of sec.get('Remote Filter')||[]){const n=e.t.split('=')[0].trim();filters.add(n);names.add(n);const f=splitTop(e.t.slice(e.t.indexOf('=')+1));if(!/^(NameRegex|NameKeyword|NodeSelect)$/.test(f[0]))I.push({level:'error',msg:`Remote Filter「${n}」类型 ${f[0]} 不对`,line:e.n});if(f[0]==='NameRegex'&&!f.slice(1).some(x=>!/^FilterKey/.test(x)))I.push({level:'error',msg:`Remote Filter「${n}」没有列出订阅别名（官方示例：NameRegex,订阅别名,FilterKey = …）`,line:e.n})}
  const groupLines=sec.get('Proxy Group')||[];const gnames=new Set<string>();
  for(const e of groupLines){const n=e.t.split('=')[0].trim();if(gnames.has(n))I.push({level:'error',msg:`策略组重名：${n}`,line:e.n});gnames.add(n);names.add(n)}
  for(const e of groupLines){
    const eq=e.t.indexOf('=');const n=e.t.slice(0,eq).trim();const parts=splitTop(e.t.slice(eq+1));const type=parts[0];
    if(!GROUP_TYPES[fam].includes(type))I.push({level:'error',msg:`策略组「${n}」类型 ${type} 不被 ${fam} 支持`,line:e.n});
    if(fam==='surge'&&/(^|,)\s*url\s*=/.test(e.t))I.push({level:'warn',msg:`策略组「${n}」的 url= 在 Surge 当前版本无效（官方手册）`,line:e.n});
    for(const m of parts.slice(1)){if(/^[\w-]+\s*=/.test(m)||m.startsWith('"'))continue;if(!names.has(m)&&!(fam==='shadowrocket'&&m===''))I.push({level:'error',msg:`策略组「${n}」引用了不存在的「${m}」`,line:e.n})}
    if(fam==='shadowrocket'&&/policy-regex-filter=/.test(e.t)&&parts.slice(1).some(m=>!/=/.test(m)))I.push({level:'error',msg:`策略组「${n}」同时有成员和 policy-regex-filter（Shadowrocket 手册：二者不能同时存在）`,line:e.n});
    if(fam==='surge'){const inc=/include-other-group="([^"]*)"/.exec(e.t);if(inc)for(const g of inc[1].split(','))if(!gnames.has(g))I.push({level:'error',msg:`策略组「${n}」include-other-group 引用了不存在的「${g}」`,line:e.n})}
    if(fam==='loon'&&type!=='select'&&type!=='ssid'&&!/url\s*=/.test(e.t))I.push({level:'warn',msg:`策略组「${n}」没有 url=`,line:e.n});
  }
  const ruleLines=sec.get('Rule')||[];let sawFinal=false;
  for(const e of ruleLines){
    const parts=splitTop(e.t);const t=parts[0].toUpperCase();
    if(!RULE_BY[fam].has(t))I.push({level:'error',msg:`规则类型 ${parts[0]} 不在 ${fam} 文档里`,line:e.n});
    if(sawFinal)I.push({level:'warn',msg:'FINAL 之后的规则不会生效',line:e.n});
    if(t==='FINAL'){sawFinal=true;const tg=parts[1];if(!names.has(tg))I.push({level:'error',msg:`FINAL 指向不存在的「${tg}」`,line:e.n});continue}
    if(['AND','OR','NOT'].includes(t)){const tg=parts[parts.length-1];if(!names.has(tg)&&!/no-resolve|extended-matching/.test(tg))I.push({level:'error',msg:`逻辑规则指向不存在的「${tg}」`,line:e.n});continue}
    const tg=parts[2];if(tg&&!names.has(tg))I.push({level:'error',msg:`规则指向不存在的「${tg}」`,line:e.n});
    if(t==='PROTOCOL'&&fam==='shadowrocket')I.push({level:'error',msg:'Shadowrocket 的 PROTOCOL 只能嵌在逻辑规则里',line:e.n});
  }
  if(fam==='loon'){const gr=new Set(groupLines.map(e=>e.t.split('=')[0].trim()));for(const e of sec.get('Remote Rule')||[]){const m=/policy=([^,]+)/.exec(e.t);if(m&&!names.has(m[1].trim()))I.push({level:'error',msg:`Remote Rule 指向不存在的「${m[1]}」`,line:e.n});if(!/^https?:\/\//.test(e.t))I.push({level:'error',msg:'Remote Rule 必须以 URL 开头',line:e.n})}void gr;if(!ruleLines.some(e=>/^FINAL,/i.test(e.t)))I.push({level:'error',msg:'缺少 FINAL'})}
  else if(!sawFinal)I.push({level:'error',msg:'缺少 FINAL 兜底'});
  if(/\{\{SUB_URL_\d+\}\}/.test(text))I.push({level:'warn',msg:'还有订阅占位符 {{SUB_URL_1}}'});
  return I;
}
function vQx(text:string):Issue[]{
  const I:Issue[]=[];const sec=sections(text);
  for(const k of sec.keys())if(!SECTIONS.qx.includes(k))I.push({level:'warn',msg:`未知段落 [${k}]`});
  const names=new Set<string>(['direct','reject','proxy']);
  for(const e of sec.get('server_local')||[]){const m=/tag=([^,]+)/.exec(e.t);if(!m)I.push({level:'error',msg:'节点没有 tag=',line:e.n});else names.add(m[1].trim())}
  for(const e of sec.get('server_remote')||[]){const m=/tag=([^,]+)/.exec(e.t);if(m)names.add(m[1].trim())}
  const pol=sec.get('policy')||[];const kinds=['static','available','round-robin','url-latency-benchmark','dest-hash','ssid'];
  for(const e of pol){names.add(e.t.slice(e.t.indexOf('=')+1).split(',')[0].trim());const k=e.t.split('=')[0].trim();if(!kinds.includes(k))I.push({level:'error',msg:`策略类型 ${k} 不在官方 sample.conf 里`,line:e.n})}
  for(const e of pol){const parts=e.t.slice(e.t.indexOf('=')+1).split(',').map(x=>x.trim());for(const m of parts.slice(1)){if(/=/.test(m))continue;if(!names.has(m))I.push({level:'error',msg:`策略「${parts[0]}」引用了不存在的「${m}」`,line:e.n})}}
  for(const e of sec.get('general')||[]){const k=e.t.split('=')[0].trim();if(!GENERAL_KEYS.qx.includes(k))I.push({level:'warn',msg:`[general] 键 ${k} 不在已核对的 sample.conf 里`,line:e.n})}
  const ft=['host','host-suffix','host-keyword','host-wildcard','ip-cidr','ip6-cidr','geoip','ip-asn','user-agent','final'];
  let fin=false;for(const e of sec.get('filter_local')||[]){const p=e.t.split(',').map(x=>x.trim());if(!ft.includes(p[0]))I.push({level:'error',msg:`filter_local 类型 ${p[0]} 不在官方 sample.conf 里`,line:e.n});if(p[0]==='final')fin=true;const tg=p[0]==='final'?p[1]:p[2];if(tg&&!names.has(tg))I.push({level:'error',msg:`规则指向不存在的「${tg}」`,line:e.n})}
  if(!fin)I.push({level:'error',msg:'缺少 final'});
  for(const e of sec.get('filter_remote')||[]){const m=/force-policy=([^,]+)/.exec(e.t);if(m&&!names.has(m[1].trim()))I.push({level:'error',msg:`filter_remote 的 force-policy「${m[1]}」不存在`,line:e.n})}
  if(/\{\{SUB_URL_\d+\}\}/.test(text))I.push({level:'warn',msg:'还有订阅占位符 {{SUB_URL_1}}'});
  return I;
}
/* ---- Egern（YAML，键名取自官方示例） ---- */
const EGERN_TOP=['ipv6','http_port','socks_port','allow_external_connections','block_quic','proxy_latency_test_url','dns','proxies','policy_groups','rules','auto_update','bypass_tunnel_proxy','real_ip_domains','hijack_dns'];
const EGERN_RULES=['domain','domain_keyword','domain_suffix','domain_regex','domain_wildcard','geoip','ip_cidr','ip_cidr6','asn','url_regex','user_agent','dest_port','protocol','rule_set','ssid','bssid','cellular','and','or','not','default'];
const EGERN_PROXY=['shadowsocks','trojan','vless','vmess','hysteria2','tuic','socks5','http','wireguard'];
const EGERN_GROUP=['select','auto_test','fallback','load_balance','external','conditional'];
function vEgern(text:string):Issue[]{
  const I:Issue[]=[];let y:any;try{y=yamlParse(text)}catch(e:any){return[{level:'error',msg:'YAML 解析失败：'+e.message}]}
  for(const k of Object.keys(y||{}))if(!EGERN_TOP.includes(k))I.push({level:'warn',msg:`顶层键 ${k} 不在官方示例里`});
  const names=new Set<string>(['DIRECT','REJECT']);
  for(const p of y.proxies||[]){const k=Object.keys(p)[0];if(!EGERN_PROXY.includes(k))I.push({level:'error',msg:`节点类型 ${k} 不在官方示例里`});names.add(p[k].name)}
  const gs=(y.policy_groups||[]).map((g:any)=>({k:Object.keys(g)[0],v:g[Object.keys(g)[0]]}));for(const g of gs){if(!EGERN_GROUP.includes(g.k))I.push({level:'error',msg:`策略组类型 ${g.k} 不在官方示例里`});names.add(g.v.name)}
  for(const g of gs)for(const m of g.v.policies||[])if(!names.has(m))I.push({level:'error',msg:`策略组「${g.v.name}」引用了不存在的「${m}」`});
  let def=false;(y.rules||[]).forEach((r:any,i:number)=>{const k=Object.keys(r)[0];if(!EGERN_RULES.includes(k))I.push({level:'error',msg:`规则 ${i+1} 类型 ${k} 不在官方文档里`});const pol=r[k]?.policy;if(pol&&!names.has(pol))I.push({level:'error',msg:`规则 ${i+1}：策略「${pol}」不存在`});if(k==='default'){def=true;if(i!==y.rules.length-1)I.push({level:'warn',msg:'default 之后的规则不会生效'})}});
  if(!def)I.push({level:'error',msg:'缺少 default 兜底规则'});
  if(y.dns){for(const f of y.dns.forward||[]){const k=Object.keys(f)[0];if(!['domain','domain_suffix','wildcard','regex','proxy_rule_set','domain_keyword'].includes(k))I.push({level:'warn',msg:`dns.forward 类型 ${k} 不在官方示例里`});const v=f[k].value;if(v&&!['bootstrap','reject',...Object.keys(y.dns.upstreams||{})].includes(v))I.push({level:'error',msg:`dns.forward 指向不存在的上游「${v}」`})}}
  return I;
}
export function validate(family:Family,text:string):Issue[]{
  switch(family){
    case'mihomo':return vMihomo(text,false);case'stash':return vMihomo(text,true);
    case'singbox':return vSingbox(text);
    case'surge':case'loon':case'shadowrocket':return vIni(text,family);
    case'qx':return vQx(text);
    case'egern':return vEgern(text);
  }
}
