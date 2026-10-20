/** 规则预览 / 配置对比 / 分享链接 / 预设 / 压缩包（全部在浏览器本地） */
import type {State,Opts} from './types';
import {STAGES,makePlan,type Plan,type Rule} from './plan';
import {GROUPS,REGIONS} from '../data/groups';
import {exportPlan} from '../store';
import {MC,BM7} from './plan';

/* ---------- 规则预览 ---------- */
export interface RuleRow{st:string;kind:string;value:string;target:string;group?:string;url?:string}
export function ruleRows(p:Plan):RuleRow[]{
  const rows:RuleRow[]=[];
  const T=(r:{p:string},g?:{id:string;category:string}):string=>{
    if(g&&g.id!=='cn'&&g.id!=='private'&&g.category!=='direct'){const sv=p.services.find(x=>x.g.id===g.id);if(sv)return sv.g.name}
    return p.pname(r.p);
  };
  for(const r of p.rules as (Rule&{st?:string})[]){
    const st=r.st||'service';
    switch(r.t){
      case'comment':break;
      case'suffix':rows.push({st,kind:'域名后缀',value:r.v,target:r.via?(p.services.find(x=>x.g.id===r.via)?.g.name||p.pname(r.p)):p.pname(r.p),group:r.via});break;
      case'ipcidr':rows.push({st,kind:'IP 段',value:r.v,target:p.pname(r.p)});break;
      case'process':rows.push({st,kind:'进程名',value:r.v,target:p.pname(r.p)});break;
      case'package':rows.push({st,kind:'Android 包名',value:r.v,target:p.pname(r.p)});break;
      case'site':rows.push({st,kind:'域名规则集',value:r.name,target:T(r,r.g),group:r.g.name,url:MC.site(r.name)});break;
      case'ip':rows.push({st,kind:'IP 规则集',value:r.name,target:T(r,r.g),group:r.g.name,url:MC.ip(r.name)});break;
      case'rset':rows.push({st,kind:'自定义规则集',value:r.name,target:p.pname(r.p),url:r.url});break;
      case'quic':rows.push({st,kind:'协议',value:'QUIC（境外）',target:'拦截'});break;
      case'stun':rows.push({st,kind:'协议',value:'STUN',target:p.pname(r.p)});break;
      case'wifi':for(const d of r.domains)rows.push({st,kind:'Wi-Fi 通话',value:d,target:p.pname(r.p)});break;
      case'final':rows.push({st,kind:'兜底',value:'其余全部',target:r.p==='PROXY'?'漏网之鱼':'直连'});break;
    }
  }
  return rows;
}
export function stageSummary(p:Plan){const rows=ruleRows(p);return STAGES.map(s=>({...s,rows:rows.filter(r=>r.st===s.id)}))}

/* ---------- 配置对比（行级 LCS） ---------- */
export interface DiffLine{t:' '|'+'|'-';v:string}
export function diffLines(a:string,b:string):DiffLine[]{
  const A=a.split('\n'),B=b.split('\n');let s=0;while(s<A.length&&s<B.length&&A[s]===B[s])s++;
  let ea=A.length,eb=B.length;while(ea>s&&eb>s&&A[ea-1]===B[eb-1]){ea--;eb--}
  const x=A.slice(s,ea),y=B.slice(s,eb);const out:DiffLine[]=A.slice(0,s).map(v=>({t:' ' as const,v}));
  if(x.length*y.length>4_000_000){x.forEach(v=>out.push({t:'-',v}));y.forEach(v=>out.push({t:'+',v}))}
  else{
    const n=x.length,m=y.length;const L=new Uint32Array((n+1)*(m+1));
    for(let i=n-1;i>=0;i--)for(let j=m-1;j>=0;j--)L[i*(m+1)+j]=x[i]===y[j]?L[(i+1)*(m+1)+j+1]+1:Math.max(L[(i+1)*(m+1)+j],L[i*(m+1)+j+1]);
    let i=0,j=0;while(i<n&&j<m){if(x[i]===y[j]){out.push({t:' ',v:x[i]});i++;j++}else if(L[(i+1)*(m+1)+j]>=L[i*(m+1)+j+1]){out.push({t:'-',v:x[i++]})}else out.push({t:'+',v:y[j++]})}
    while(i<n)out.push({t:'-',v:x[i++]});while(j<m)out.push({t:'+',v:y[j++]});
  }
  for(const v of A.slice(ea))out.push({t:' ',v});
  return out;
}

/* ---------- 预设模板 ---------- */
export interface Preset{id:string;name:string;desc:string;apply:(s:State)=>Partial<State>}
const only=(on:string[],pol:Record<string,string>={})=>{const g:State['groups']={};for(const x of GROUPS)g[x.id]={on:on.includes(x.id),policy:pol[x.id]||x.def};return g};
/** 9.8+ 各预设共用安全基线（差异只在定位，不降低标准）：
 *  未知域名走代理、IPv6 关、fake-ip + TUN 开、境外 QUIC 拦、STUN 走代理、
 *  广告 Lite + 追踪/遥测拦截、故障转移开、测速间隔 600 秒、容差 50、
 *  负载均衡关（防流量分散到多节点）、局域网关。 */
const hardOpts=(s:State,extra:Partial<Opts>={}):Opts=>({...s.opts,unknown:'proxy',ipv6:false,fakeIp:true,tun:true,blockQuic:'foreign',stun:'proxy',ads:'lite',telemetry:true,trackers:true,failover:true,urlTestInterval:600,tolerance:50,lbGroup:false,allowLan:false,...extra});
/** 预设分组：除定位组外，广告 / 遥测 / 追踪器拦截默认开（REJECT）。
 *  注意：only() 会枚举全部 GROUPS 把未列出的组关掉；之前多数预设没列这三组，
 *  等于悄悄关了拦截，而 opts.ads='lite' 成了死配置。onlyB 保证两者一致。 */
const onlyB=(on:string[],pol:Record<string,string>={})=>only([...on,'ads','telemetry','trackers'],{...pol,ads:'REJECT',telemetry:'REJECT',trackers:'REJECT'});
export const PRESETS:Preset[]=[
 {id:'balanced',name:'日常均衡',desc:'默认（平衡/完美）：与全新方案默认开启的分组一致——AI、流媒体、社交、GitHub、Google/微软/Apple、PayPal、加密货币、B 站、金融科技、国内银行直连；故障转移 + 防泄漏基线全开。',apply:s=>({groups:onlyB(['ai','ai-more','ai-agent','ai-cn','youtube','netflix','disney','spotify','telegram','twitter','meta','discord','github','google','microsoft','apple','paypal','crypto','bilibili','games-cn','pt','bank-overseas','fintech','cn-bank-direct','steam']),opts:hardOpts(s,{keepAlive:false})})},
 {id:'min',name:'极简',desc:'只开最常用的：AI、Google、Telegram、X、YouTube、GitHub；广告 Lite + 拦截全开（规则仍精简），低内存模式，iPhone 更省内存。',apply:s=>({groups:onlyB(['ai','google','telegram','twitter','youtube','github','bilibili','apple','microsoft'],{apple:'DIRECT',microsoft:'DIRECT'}),opts:hardOpts(s,{lowMemory:true})})},
 {id:'stream',name:'流媒体',desc:'YouTube、Netflix、Disney+、Prime Video、Spotify、Twitch、TikTok + 更多影音（Hulu / Crunchyroll 等）全开；流媒体组建议在规则页选「某地区-手动」固定片库防跳区；保活开、测速 600 秒。',apply:s=>({groups:onlyB(['youtube','netflix','disney','primevideo','spotify','twitch','tiktok','media-more','google','telegram','ai','github','bilibili','apple','microsoft'],{apple:'DIRECT',microsoft:'DIRECT'}),opts:hardOpts(s,{keepAlive:true})})},
 {id:'dev',name:'开发者',desc:'GitHub、GitLab、Docker、npm、Cloudflare、云平台（AWS / Azure / GCP / Vercel 等）、Google、微软、AI（含更多）、学术；保活开，低延迟地区优先。',apply:s=>({groups:onlyB(['github','gitlab','docker','npm','cloudflare','cloud-dev','google','microsoft','onedrive','ai','ai-more','ai-agent','ai-cn','scholar','telegram','apple','twitter','reddit','bilibili'],{apple:'DIRECT',microsoft:'DIRECT',onedrive:'DIRECT','ai-cn':'DIRECT'}),opts:hardOpts(s,{keepAlive:true})})},
 {id:'ai',name:'AI 重度',desc:'AI、「AI 更多」与智能体走美国手动节点（固定 IP，防 AI 风控换 IP 触发验证），不是自动测速；国内 AI 直连，Google、GitHub、学术一起开。',apply:s=>{const us=s.regions.includes('US')?'R:US/m':'PROXY';return{groups:onlyB(['ai','ai-more','ai-agent','ai-cn','google','github','scholar','telegram','twitter','bilibili','apple','microsoft'],{ai:us,'ai-more':us,'ai-agent':us,'ai-cn':'DIRECT',apple:'DIRECT',microsoft:'DIRECT'}),opts:hardOpts(s,{keepAlive:true})}}},
 {id:'safe',name:'加密货币 / 银行（稳）',desc:'交易所、钱包、海外银行券商：固定地区手动出口，避免 IP 乱跳触发风控；负载均衡关、局域网关、保活开。',apply:s=>{const r=s.regions.includes('SG')?'R:SG/m':s.regions.includes('HK')?'R:HK/m':'PROXY';return{groups:onlyB(['crypto','crypto-more','bank-overseas','paypal','fintech','google','telegram','twitter','ai','bilibili','apple','microsoft','onedrive'],{crypto:r,'crypto-more':r,'bank-overseas':r,paypal:r,fintech:r,apple:'DIRECT',microsoft:'DIRECT',onedrive:'DIRECT'}),opts:hardOpts(s,{keepAlive:true})}}},
 {id:'nomad',name:'数字游民',desc:'对齐作者自用结构：Bunq / SumUp / Maya / Blackcat + Wise/Revolut 等金融科技 + PayPal；微软/Apple/OneDrive 直连；故障转移与防泄漏全开。出口默认德国「手动」固定 IP。',apply:s=>{const r='R:DE/m'; // 预设本身会开启 DE 地区；用输入 state 的 regions 判断会误取 SG（输入 state 通常没开 DE）。
   const ids=['ai','youtube','google','github','steam','tiktok','twitter','telegram','netflix','disney','spotify','paypal','meta','whatsapp','fintech','bank-overseas','bank-eu','bunq','sumup','maya','blackcat','cn-bank-direct','onedrive','microsoft','apple'];
   const pol:Record<string,string>={bunq:r,sumup:r,maya:r,blackcat:r,fintech:r,'bank-overseas':r,'bank-eu':r,paypal:r,onedrive:'DIRECT',microsoft:'DIRECT',apple:'DIRECT','cn-bank-direct':'DIRECT'};
   return{groups:onlyB(ids,pol),regions:['HK','TW','JP','SG','KR','US','EU','UK','FR','DE','OT'],opts:hardOpts(s,{mtu:1420,keepAlive:true,icons:true})}}},
 {id:'crypto-pack',name:'加密货币',desc:'Binance / Bybit / Bybit EU / OKX / MEXC / Kraken / Krak / Bitget Wallet + 通用加密规则集；固定新加坡或香港手动节点；负载均衡关、保活开、防泄漏基线全开。',apply:s=>{const r=s.regions.includes('SG')?'R:SG/m':s.regions.includes('HK')?'R:HK/m':s.regions.includes('JP')?'R:JP/m':'PROXY';
   const ids=['crypto','crypto-more','bybit-eu','mexc','krak','bitget-wallet','paypal','google','telegram','twitter','ai','github','apple','microsoft'];
   const pol:Record<string,string>={crypto:r,'crypto-more':r,'bybit-eu':r,mexc:r,krak:r,'bitget-wallet':r,paypal:r,apple:'DIRECT',microsoft:'DIRECT'};
   return{groups:onlyB(ids,pol),opts:hardOpts(s,{keepAlive:true})}}},
 {id:'antileak',name:'通用防泄漏',desc:'IPv6 关、境外 QUIC 拦、STUN 走代理、fake-ip + 广告/追踪/遥测拦截、故障转移开、局域网关、负载均衡关；保留常用服务组。对齐作者 DNS/防泄漏模板（无私人信息）。',apply:s=>({opts:hardOpts(s,{mtu:1420,keepAlive:true,icons:true}),
   groups:onlyB(['ai','youtube','netflix','disney','spotify','telegram','twitter','meta','discord','github','google','microsoft','apple','paypal','crypto','bilibili','steam','tiktok','onedrive','cn-bank-direct'],{onedrive:'DIRECT',microsoft:'DIRECT',apple:'DIRECT','cn-bank-direct':'DIRECT'})})},
 {id:'cn',name:'直连优先（省流量）',desc:'未知域名直连，只有需要代理的服务走代理：适合流量有限的套餐；保活关、拦截仍开（挡广告本身省流量）。',apply:s=>({groups:onlyB(['ai','google','telegram','twitter','youtube','github','apple','microsoft','bilibili'],{apple:'DIRECT',microsoft:'DIRECT'}),opts:hardOpts(s,{unknown:'direct',keepAlive:false})})},
 {id:'all',name:'全开（不推荐）',desc:'把所有服务分组都打开，规则最多，仅用于测试；日常请切回「日常均衡」。',apply:s=>({groups:{...Object.fromEntries(GROUPS.filter(g=>g.category!=='reject'&&g.id!=='games-cn'&&g.id!=='pt'&&g.id!=='p2p-private').map(g=>[g.id,{on:true,policy:g.def}])),ads:{on:true,policy:'REJECT'},telemetry:{on:true,policy:'REJECT'},trackers:{on:true,policy:'REJECT'}},opts:hardOpts(s)})},
];

/* ---------- 分享链接（方案进 URL，不含订阅 / 节点 / 密钥） ---------- */
const b64u=(u:Uint8Array)=>btoa(String.fromCharCode(...u)).replace(/\+/g,'-').replace(/\//g,'_').replace(/=+$/,'');
const unb64u=(s:string)=>{s=s.replace(/-/g,'+').replace(/_/g,'/');while(s.length%4)s+='=';return Uint8Array.from(atob(s),c=>c.charCodeAt(0))};
async function pipe(data:any,T:any):Promise<Uint8Array>{const st=new Blob([data as BlobPart]).stream().pipeThrough(T);return new Uint8Array(await new Response(st).arrayBuffer())}
export async function sharePlanUrl(s:State):Promise<string>{
  const json=new TextEncoder().encode(JSON.stringify(JSON.parse(exportPlan(s,false))));
  let tag="r",data:Uint8Array<any>=json;
  try{if(typeof (globalThis as any).CompressionStream==='function'){data=await pipe(json as any,new (globalThis as any).CompressionStream('deflate-raw'));tag='z'}}catch{}
  return `${location.origin}${location.pathname}#p=${tag}.${b64u(data)}`;
}
export async function readSharedPlan():Promise<string|null>{
  const m=/#p=([rz])\.([A-Za-z0-9_-]+)/.exec(location.hash);if(!m)return null;
  try{let d:Uint8Array<any>=unb64u(m[2]);if(m[1]==='z')d=await pipe(d as any,new (globalThis as any).DecompressionStream('deflate-raw'));return new TextDecoder().decode(d)}catch{return null}
}

/* ---------- 压缩包（store 方式，无依赖） ---------- */
const CRC=(()=>{const t=new Uint32Array(256);for(let n=0;n<256;n++){let c=n;for(let k=0;k<8;k++)c=c&1?0xedb88320^(c>>>1):c>>>1;t[n]=c>>>0}return t})();
const crc32=(b:Uint8Array)=>{let c=0xffffffff;for(let i=0;i<b.length;i++)c=CRC[(c^b[i])&255]^(c>>>8);return(c^0xffffffff)>>>0};
export function zip(files:{name:string;text:string}[]):Uint8Array{
  const enc=new TextEncoder();const parts:Uint8Array[]=[];const cen:Uint8Array[]=[];let off=0;
  const u16=(v:number)=>[v&255,(v>>8)&255],u32=(v:number)=>[v&255,(v>>8)&255,(v>>16)&255,(v>>>24)&255];
  for(const f of files){
    const nm=enc.encode(f.name),d=enc.encode(f.text),c=crc32(d);
    const lh=new Uint8Array([0x50,0x4b,3,4,...u16(20),...u16(0x0800),...u16(0),...u16(0),...u16(0x21),...u32(c),...u32(d.length),...u32(d.length),...u16(nm.length),...u16(0)]);
    parts.push(lh,nm,d);
    cen.push(new Uint8Array([0x50,0x4b,1,2,...u16(20),...u16(20),...u16(0x0800),...u16(0),...u16(0),...u16(0x21),...u32(c),...u32(d.length),...u32(d.length),...u16(nm.length),...u16(0),...u16(0),...u16(0),...u16(0),...u32(0),...u32(off)]),nm);
    off+=lh.length+nm.length+d.length;
  }
  const cl=cen.reduce((a,b)=>a+b.length,0);
  const end=new Uint8Array([0x50,0x4b,5,6,...u16(0),...u16(0),...u16(files.length),...u16(files.length),...u32(cl),...u32(off),...u16(0)]);
  const all=[...parts,...cen,end];const out=new Uint8Array(all.reduce((a,b)=>a+b.length,0));let o=0;for(const a of all){out.set(a,o);o+=a.length}return out;
}
void REGIONS;void makePlan;void BM7;

/* ---------- 从已有配置导入自定义域名（Clash / Surge / Loon / QX / sing-box 的 rules 行都能读） ---------- */
export interface Imported{domain:string;policy:'PROXY'|'DIRECT'|'REJECT';from:string}
export function importRules(text:string):{items:Imported[];ignored:number}{
  const items:Imported[]=[];let ignored=0;const seen=new Set<string>();
  const pol=(x:string):Imported['policy']=>{const u=x.trim().toUpperCase();return u==='DIRECT'?'DIRECT':u.startsWith('REJECT')?'REJECT':'PROXY'};
  for(let line of text.split(/\r?\n/)){
    line=line.trim().replace(/^-\s*/,'').replace(/^['"]|['"]$/g,'');
    if(!line||/^(#|;|\/\/)/.test(line)){continue}
    // QX：host-suffix, a.com, proxy
    const m=/^(DOMAIN-SUFFIX|DOMAIN|host-suffix|host)\s*,\s*([^,\s]+)\s*,\s*([^,]+)/i.exec(line);
    if(m){const d=m[2].toLowerCase();if(!/^[a-z0-9.-]+\.[a-z]{2,}$|^[a-z0-9-]+$/.test(d)){ignored++;continue}
      if(seen.has(d))continue;seen.add(d);items.push({domain:d,policy:pol(m[3]),from:m[1].toUpperCase()});continue}
    if(/^[A-Z-]+,/.test(line)||/^(host|ip-cidr|geoip|final|ip6-cidr)/i.test(line))ignored++;
  }
  return{items,ignored};
}
