/** 模块与脚本：解析（Surge/Shadowrocket .sgmodule、Loon .plugin、QX .snippet/.conf、Stash .stoverride）→ 中间结构 → 各客户端语法 */
import YAML from 'yaml';
import type {State,ModItem,ModKind} from './types';
import {CLIENTS,type Family} from '../data/clients';

export type RwAction='reject'|'reject-200'|'reject-img'|'reject-dict'|'reject-array'|'302'|'307';
export interface RW{pattern:string;action:RwAction;target?:string}
export interface SC{name:string;type:'request'|'response'|'cron';pattern?:string;cron?:string;path:string;body:boolean;binary?:boolean;timeout?:number}
export interface Parsed{fmt:'surge'|'loon'|'qx'|'stash'|'unknown';name:string;desc:string;rewrites:RW[];scripts:SC[];hosts:string[];rules:string[];ignored:string[]}
export const KIND_NAME:Record<ModKind,string>={adblock:'广告拦截',rewrite:'重写',enhance:'增强',routing:'路由辅助',other:'其他'};
export const MOD_FAMILIES:Family[]=['surge','shadowrocket','loon','qx','stash','egern'];
export const supportsModules=(f:Family)=>MOD_FAMILIES.includes(f);
const REJ=['reject','reject-200','reject-img','reject-dict','reject-array'];

export function detect(t:string):Parsed['fmt']{
  if(/^\s*http:\s*$/m.test(t)&&/url-rewrite|script-providers|mitm:/.test(t))return'stash';
  if(/^\s*\[(URL Rewrite|Rewrite|Script|MITM|Rule|Map Local|Host|General|Plugin)\]/mi.test(t)){
    if(/^\s*\[Rewrite\]/mi.test(t)||/^\s*(http-request|http-response)\s+\S+\s+script-path=/mi.test(t)||/^\s*cron\s+"/mi.test(t))return'loon';return'surge'}
  if(/\burl\s+(reject|script-|302|307|request-|response-)/i.test(t)||/^\s*hostname\s*=/mi.test(t))return'qx';
  return'unknown';
}
const splitKV=(s:string)=>{const o:Record<string,string>={};for(const part of s.split(/,(?=\s*[\w-]+\s*=)/)){const i=part.indexOf('=');if(i>0)o[part.slice(0,i).trim().toLowerCase()]=part.slice(i+1).trim().replace(/^"|"$/g,'')}return o};
const hostsOf=(v:string)=>v.replace(/^%(APPEND|INSERT)%/i,'').split(/[,\s]+/).map(x=>x.trim()).filter(x=>x&&!/^%/.test(x));
function rwOf(pattern:string,mid:string,act:string):RW|null{
  act=act.trim().toLowerCase();
  if(REJ.includes(act))return{pattern,action:act as RwAction};
  if(act==='302'||act==='307')return{pattern,action:act,target:mid};
  return null;
}
export function parseModule(text:string):Parsed{
  const fmt=detect(text);const P:Parsed={fmt,name:'',desc:'',rewrites:[],scripts:[],hosts:[],rules:[],ignored:[]};
  const nm=/^#!name\s*=\s*(.+)$/mi.exec(text);if(nm)P.name=nm[1].trim();const ds=/^#!desc\s*=\s*(.+)$/mi.exec(text);if(ds)P.desc=ds[1].trim();
  if(fmt==='stash'){
    try{const y:any=YAML.parse(text)||{};P.name=P.name||y.name||'';P.desc=P.desc||y.desc||'';const h=y.http||{};
      for(const m of h.mitm||[])P.hosts.push(...hostsOf(String(m)));
      for(const r of h['url-rewrite']||[]){const t=String(r).trim().split(/\s+/);if(t.length>=3){const x=rwOf(t[0],t[1],t[t.length-1]);if(x)P.rewrites.push(x);else P.ignored.push(String(r))}}
      const prov=y['script-providers']||{};
      for(const sc of h.script||[]){const url=prov[sc.name]?.url;if(!url){P.ignored.push('script '+sc.name);continue}
        const ty=String(sc.type||'response').includes('request')?'request':String(sc.type).includes('cron')?'cron':'response';
        P.scripts.push({name:sc.name,type:ty as any,pattern:sc.match,cron:sc.cron,path:url,body:!!(sc['require-body']||sc.requires_body),timeout:sc.timeout})}
      for(const r of y.rules||[])P.rules.push(String(r));
    }catch{P.ignored.push('YAML 解析失败')}
    return P;
  }
  let sec='';
  for(let raw of text.split(/\r?\n/)){
    const line=raw.trim();if(!line||line.startsWith('#')||line.startsWith(';')||line.startsWith('//'))continue;
    const m=/^\[(.+)\]$/.exec(line);if(m){sec=m[1].toLowerCase();continue}
    if(fmt==='qx'&&!sec){
      const h=/^hostname\s*=\s*(.+)$/i.exec(line);if(h){P.hosts.push(...hostsOf(h[1]));continue}
      const r=/^(\S+)\s+url\s+(\S+)(?:\s+(.*))?$/i.exec(line);
      if(r){const [,pat,act,rest]=r;
        if(REJ.includes(act.toLowerCase()))P.rewrites.push({pattern:pat,action:act.toLowerCase() as RwAction});
        else if(act==='302'||act==='307')P.rewrites.push({pattern:pat,action:act,target:(rest||'').trim()});
        else if(/^script-(request|response|echo|analyze)/.test(act)){const ty=act.includes('request')?'request':'response';P.scripts.push({name:(rest||'').split('/').pop()||'script',type:ty,pattern:pat,path:(rest||'').trim(),body:/body/.test(act)})}
        else P.ignored.push(line.slice(0,80));continue}
      const c=/^((?:[\d*\/,-]+\s+){4}[\d*\/,-]+)\s+(\S+?)(?:,\s*(.*))?$/.exec(line);
      if(c){const tag=/tag\s*=\s*([^,]+)/.exec(c[3]||'');P.scripts.push({name:tag?tag[1]:c[2].split('/').pop()||'cron',type:'cron',cron:c[1],path:c[2],body:false});continue}
      P.ignored.push(line.slice(0,80));continue;
    }
    if(sec==='mitm'){const h=/^hostname\s*=\s*(.+)$/i.exec(line);if(h)P.hosts.push(...hostsOf(h[1]));continue}
    if(sec==='url rewrite'||sec==='rewrite'){const t=line.split(/\s+/);if(t.length>=2){const act=t[t.length-1];const mid=t.length>=3?t[1]:'';const x=rwOf(t[0],mid,act);if(x){P.rewrites.push(x);continue}}P.ignored.push('['+sec+'] '+line.slice(0,70));continue}
    if(sec==='script'){
      let mm=/^(\S+)\s*=\s*(.+)$/.exec(line);
      if(mm&&/type\s*=/.test(mm[2])){const kv=splitKV(mm[2]);const ty=kv.type==='cron'?'cron':String(kv.type||'').includes('request')?'request':'response';
        if(kv['script-path'])P.scripts.push({name:mm[1],type:ty as any,pattern:kv.pattern,cron:kv.cronexp,path:kv['script-path'],body:/^(1|true)$/i.test(kv['requires-body']||''),binary:/^(1|true)$/i.test(kv['binary-body-mode']||''),timeout:kv.timeout?+kv.timeout:undefined});else P.ignored.push('[Script] '+mm[1]);continue}
      mm=/^(http-request|http-response|cron)\s+(?:"([^"]+)"|(\S+))\s*(.*)$/i.exec(line);
      if(mm){const kv=splitKV(mm[4]);const ty=mm[1]==='cron'?'cron':mm[1].includes('request')?'request':'response';
        if(kv['script-path'])P.scripts.push({name:kv.tag||kv['script-path'].split('/').pop()||'script',type:ty as any,pattern:ty==='cron'?undefined:mm[3],cron:ty==='cron'?mm[2]||mm[3]:undefined,path:kv['script-path'],body:/^(1|true)$/i.test(kv['requires-body']||''),binary:/^(1|true)$/i.test(kv['binary-body-mode']||''),timeout:kv.timeout?+kv.timeout:undefined});continue}
      P.ignored.push('[Script] '+line.slice(0,70));continue}
    if(sec==='rule'){P.rules.push(line);continue}
    if(sec==='map local'||sec==='host'||sec==='general'||sec==='argument')P.ignored.push('['+sec+'] '+line.slice(0,60));
  }
  P.hosts=[...new Set(P.hosts)];
  return P;
}
/* ---------- 安全检查 ---------- */
const PAID=/(revenuecat|unlock|crack|\bvip\b|premium|pro\s?unlock|会员|解锁|破解|去订阅|免费订阅|purchase)/i;
export interface Safety{blocked:string[];warns:string[]}
export function safety(m:{name:string;url:string;content:string},P:Parsed|null):Safety{
  const blocked:string[]=[],warns:string[]=[];
  const hay=[m.name,m.url,P?.name,P?.desc,...(P?.scripts||[]).flatMap(s=>[s.name,s.path,s.pattern||'']),...(P?.rewrites||[]).map(r=>r.pattern)].filter(Boolean).join('\n');
  if(PAID.test(hay))blocked.push('名称或内容里出现「解锁 / 会员 / 破解 / RevenueCat」一类字样。Lowex 不嵌入用于绕过付费或订阅的模块与脚本。');
  if(m.url&&!/^https:\/\//i.test(m.url))warns.push('链接不是 https://，传输过程中可能被篡改。');
  if(P){
    if(P.scripts.length)warns.push(`含 ${P.scripts.length} 个脚本：脚本会在 MITM 解密后读取并可修改对应网站的请求与响应（包括登录信息）。只使用你信任来源、并且读过内容的脚本。`);
    for(const s of P.scripts)if(!/^https:\/\//i.test(s.path))warns.push(`脚本「${s.name}」的地址不是 https://。`);
    if(P.hosts.includes('*')||P.hosts.some(h=>h==='*.*'))warns.push('MITM 主机名里有通配符「*」：会解密所有 HTTPS 流量，风险很大。');
    else if(P.hosts.length>40)warns.push(`MITM 主机名多达 ${P.hosts.length} 个，范围很广。`);
    const bank=P.hosts.filter(h=>/(bank|alipay|icbc|ccb|abchina|pay\.|paypal|wechat|weixin|gov\.cn)/i.test(h));
    if(bank.length)warns.push('MITM 主机名里包含支付 / 银行 / 微信等敏感域名：'+bank.slice(0,4).join('、')+'。');
    if(P.rules.length)warns.push(`含 ${P.rules.length} 条 [Rule]：Lowex 不会把它们合并进主规则（顺序会被打乱），请在客户端里以模块方式安装。`);
    if(P.ignored.length)warns.push(`有 ${P.ignored.length} 行无法转换而被忽略（如 Map Local、Host、参数模板）。`);
    if(/\{\{\{[^}]+\}\}\}/.test(m.content))warns.push('文件里有 {{{参数}}} 模板：只有 Surge 在安装模块时才会替换，其他客户端直接用会出错。');
  }
  return{blocked,warns};
}
/* ---------- 文件扩展名与客户端的对应 ---------- */
export const extOf=(u:string)=>{const m=/\.([a-z0-9]+)(?:[?#]|$)/i.exec(u.split('/').pop()||'');return m?m[1].toLowerCase():''};
export const NATIVE_EXT:Record<string,string[]>={surge:['sgmodule'],shadowrocket:['sgmodule','module'],loon:['plugin','lpx'],qx:['snippet','conf','list'],stash:['stoverride'],egern:['yaml','yml']};
export function compat(fam:Family,url:string):'native'|'maybe'|'no'{
  const e=extOf(url);if(!e)return'maybe';if((NATIVE_EXT[fam]||[]).includes(e))return'native';
  if(e==='js')return'no';
  if(fam==='shadowrocket'&&['sgmodule','module','plugin','conf','snippet'].includes(e))return'maybe';
  if(fam==='loon'&&['sgmodule','module','conf'].includes(e))return'maybe';
  return'no';
}
export const INSTALL_HINT:Record<string,string>={
  surge:'Surge：设置 → 模块 → 安装新模块（粘贴链接）。模块是 App 内的功能，配置文件里不能引用。',
  shadowrocket:'Shadowrocket：配置 → 模块 → 右上角 + → 粘贴链接。模块列表属于 App，配置文件里不写。',
  loon:'Loon：配置 → 插件 → 右上角 + → 粘贴链接；也可以写进配置的 [Plugin] 段（本站已生成）。',
  qx:'Quantumult X：设置 → 重写 → 引用 → 添加（粘贴 .snippet 链接）；本站已生成 [rewrite_remote]。',
  stash:'Stash：覆写 → 添加 → 粘贴 .stoverride 链接。覆写属于 App，配置文件里不能引用。',
  egern:'Egern：模块 → 添加（粘贴链接）。语法未核实，本站只生成安装清单。'};
/* ---------- 渲染 ---------- */
const q=(s:string)=>s.replace(/[\r\n]/g,' ');
export interface Active{item:ModItem;P:Parsed|null;S:Safety}
export function activeItems(s:State):Active[]{
  return (s.modules||[]).filter(m=>m.on).map(item=>{const P=item.content.trim()?parseModule(item.content):null;return{item,P,S:safety(item,P)}});
}
export function renderModules(s:State):{text:string;notes:string[]}{
  const fam=CLIENTS.find(c=>c.id===s.client)!.family;const notes:string[]=[];
  if(!supportsModules(fam))return{text:'',notes};
  const act=activeItems(s);
  const rw:RW[]=[],sc:SC[]=[];const hosts=new Set<string>();const remote:{name:string;url:string}[]=[];const rules:string[]=[];
  for(const a of act){
    if(a.S.blocked.length){notes.push(`「${a.item.name}」未嵌入：${a.S.blocked[0]}`);continue}
    if(a.P){rw.push(...a.P.rewrites);sc.push(...a.P.scripts);a.P.hosts.forEach(h=>hosts.add(h));rules.push(...a.P.rules)}
    else if(a.item.url.trim())remote.push({name:a.item.name||a.item.url,url:a.item.url.trim()});
  }
  const mitmOk=fam!=='egern';
  for(const r of mitmOk?(s.rewrites||[]):[])if(r.on&&r.pattern.trim())rw.push({pattern:r.pattern.trim(),action:r.action,target:r.target});
  for(const h of (mitmOk?(s.mitmHosts||''):'').split(/[,\s]+/).filter(Boolean))hosts.add(h);
  const L:string[]=[];const cm=fam==='qx'?';':fam==='egern'||fam==='stash'?'#':'#';
  if(!mitmOk){if(!remote.length){if(rw.length||sc.length||hosts.size)notes.push('Egern：粘贴的模块内容没有写进配置（语法未核实），请在 App 的模块功能里添加。');return{text:'',notes}}}
  else if(!act.length&&!(s.rewrites||[]).some(r=>r.on)&&!(s.mitmHosts||'').trim())return{text:'',notes};
  L.push('',`${cm} ===== Lowex：模块与脚本 =====`,`${cm} 脚本与 MITM 会解密并可改写你的 HTTPS 流量，只使用你信任并读过的来源；需要在客户端里安装并信任 MITM 证书。`);
  const hl=[...hosts];
  const rwSurge=(r:RW)=>REJ.includes(r.action)?`${r.pattern} - ${r.action}`:`${r.pattern} ${r.target} ${r.action}`;
  const rwLoon=(r:RW)=>REJ.includes(r.action)?`${r.pattern} ${r.action}`:`${r.pattern} ${r.target} ${r.action}`;
  const rwQX=(r:RW)=>REJ.includes(r.action)?`${r.pattern} url ${r.action}`:`${r.pattern} url ${r.action} ${r.target}`;
  if(fam==='surge'||fam==='shadowrocket'){
    if(rw.length)L.push('','[URL Rewrite]',...rw.map(rwSurge));
    if(sc.length)L.push('','[Script]',...sc.map(x=>x.type==='cron'?`${q(x.name)} = type=cron,cronexp="${x.cron}",script-path=${x.path}${x.timeout?`,timeout=${x.timeout}`:''}`:`${q(x.name)} = type=http-${x.type},pattern=${x.pattern},script-path=${x.path}${x.body?',requires-body=1':''}${x.binary?',binary-body-mode=1':''}${x.timeout?`,timeout=${x.timeout}`:''}`));
    if(hl.length)L.push('','[MITM]',`hostname = %APPEND% ${hl.join(', ')}`);
    if(remote.length)L.push('',...[`// 以下模块请在 App 内安装（配置文件里不能引用）：`,...remote.map(r=>`// ${q(r.name)}: ${r.url}`)]);
    if(fam==='shadowrocket')notes.push('Shadowrocket 的 [URL Rewrite] / [Script] / [MITM] 与 Surge 写法相同；MITM 还要在 App 里生成并信任证书、打开 MITM 开关。');
  }else if(fam==='loon'){
    if(rw.length)L.push('','[Rewrite]',...rw.map(rwLoon));
    if(sc.length)L.push('','[Script]',...sc.map(x=>x.type==='cron'?`cron "${x.cron}" script-path=${x.path}, timeout=${x.timeout||60}, tag=${q(x.name)}`:`http-${x.type} ${x.pattern} script-path=${x.path}, ${x.body?'requires-body=true, ':''}${x.binary?'binary-body-mode=true, ':''}timeout=${x.timeout||60}, tag=${q(x.name)}`));
    if(hl.length)L.push('','[MITM]',`hostname = ${hl.join(', ')}`);
    const pl=remote.filter(r=>compat('loon',r.url)!=='no');
    if(pl.length)L.push('','[Plugin]',...pl.map(r=>`${r.url}, tag=${q(r.name)}, enabled=true`));
    for(const r of remote)if(compat('loon',r.url)==='no')notes.push(`「${r.name}」格式不是 Loon 能直接引用的（.plugin / .lpx），没有写进 [Plugin]。`);
  }else if(fam==='qx'){
    if(rw.length)L.push('','[rewrite_local]',...rw.map(rwQX));
    const rs=sc.filter(x=>x.type!=='cron');
    if(rs.length){const lines=rs.map(x=>`${x.pattern} url script-${x.type}-${x.body?'body':'header'} ${x.path}`);L.push(...(rw.length?[]:['','[rewrite_local]']),...lines)}
    const cr=sc.filter(x=>x.type==='cron');if(cr.length)L.push('','[task_local]',...cr.map(x=>`${x.cron}, ${x.path}, tag=${q(x.name)}, enabled=true`));
    if(hl.length)L.push('','[mitm]',`hostname = ${hl.join(', ')}`);
    const rr=remote.filter(r=>compat('qx',r.url)!=='no');
    if(rr.length)L.push('','[rewrite_remote]',...rr.map(r=>`${r.url}, tag=${q(r.name)}, update-interval=172800, opt-parser=false, enabled=true`));
    for(const r of remote)if(compat('qx',r.url)==='no')notes.push(`「${r.name}」不是 QX 能引用的 .snippet / .conf，没有写进 [rewrite_remote]。`);
    notes.push('QX 的 body 与 header 两种脚本类型无法从 Surge 格式精确区分：requires-body=1 → script-*-body，否则 script-*-header；请核对。');
  }else if(fam==='stash'){
    const y:any={};const h:any={};
    if(hl.length)h.mitm=hl;
    if(rw.length)h['url-rewrite']=rw.map(r=>REJ.includes(r.action)?`${r.pattern} - ${r.action}`:`${r.pattern} ${r.target} ${r.action}`);
    const prov:any={};
    if(sc.length){h.script=sc.map((x,i)=>{const n=(x.name||'s'+i).replace(/[^\w.-]/g,'_');prov[n]={url:x.path,interval:86400};return x.type==='cron'?{name:n,cron:x.cron}:{match:x.pattern,name:n,type:x.type,'require-body':x.body}})}
    if(Object.keys(h).length)y.http=h;if(Object.keys(prov).length)y['script-providers']=prov;
    if(Object.keys(y).length){L.push('# 以下按 Stash 覆写（.stoverride）的 http: 写法生成，没有在真机验证过，导入后请核对。');L.push(YAML.stringify(y).trimEnd())}
    if(remote.length)L.push('# 以下覆写请在 App 内安装：',...remote.map(r=>`# ${q(r.name)}: ${r.url}`));
  }else if(fam==='egern'){
    if(remote.length)L.push('# 以下模块请在 App 内安装（Egern 的模块语法本站未核实，所以不写进配置）：',...remote.map(r=>`# ${q(r.name)}: ${r.url}`));
    if(rw.length||sc.length||hl.length)notes.push('Egern：粘贴的模块内容 / 自定义重写没有写进配置（语法未核实），请在 App 的模块功能里添加。');
  }
  if(rules.length)notes.push(`模块里共有 ${rules.length} 条 [Rule] 没有合并（顺序会被打乱）。`);
  return{text:L.join('\n')+'\n',notes};
}
