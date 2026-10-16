/** 一键导出：整份配置 + 仅规则 + 自定义域名规则集 + 每个服务组的独立规则文件 + 规则来源清单 + 方案 */
import type {State} from './types';
import {CLIENTS} from '../data/clients';
import {generate,makePlan} from './index';
import {MC,BM7,STAGES} from './plan';
import {ruleRows} from './tools';
import {exportPlan} from '../store';

export interface OutFile{name:string;text:string;desc:string}
/** 从整份配置里截出「规则」部分（各格式的规则段落不同） */
export function extractRules(text:string,family:string):string{
  const cut=(re:RegExp)=>{const i=text.search(re);return i>=0?text.slice(i):''};
  switch(family){
    case'mihomo':case'stash':return cut(/^rule-providers:/m);
    case'egern':return cut(/^rules:/m);
    case'surge':case'shadowrocket':return cut(/^\[Rule\]/m);
    case'loon':return cut(/^\[Rule\]/m);
    case'qx':{const i=text.search(/^\[filter_remote\]/m);return i>=0?text.slice(i).replace(/\n\[server_local\][\s\S]*?(?=\n\[filter_local\])/,'\n'):''}
    case'singbox':{try{const j=JSON.parse(text);return JSON.stringify({route:j.route},null,2)+'\n'}catch{return''}}
  }
  return'';
}
const domainsOf=(s:State)=>{
  const p=makePlan(s);
  const mine=[...s.customDomains.filter(c=>c.domain.trim()).map(c=>({d:c.domain.trim(),p:p.pname(c.policy)})),...s.apps.filter(a=>a.kind==='domain').map(a=>({d:a.value.trim(),p:p.pname(a.policy)}))];
  return{p,mine};
};
function listFile(family:string,domains:string[],policy:string):{text:string;ext:string}{
  switch(family){
    case'mihomo':case'stash':return{ext:'yaml',text:'payload:\n'+domains.map(d=>`  - '+.${d}'`).join('\n')+'\n'};
    case'singbox':return{ext:'json',text:JSON.stringify({version:3,rules:[{domain_suffix:domains}]},null,2)+'\n'};
    case'qx':return{ext:'list',text:domains.map(d=>`host-suffix, ${d}, ${policy}`).join('\n')+'\n'};
    default:return{ext:'list',text:domains.map(d=>`DOMAIN-SUFFIX,${d}`).join('\n')+'\n'};
  }
}
export function exportFiles(s:State):OutFile[]{
  const c=CLIENTS.find(x=>x.id===s.client)!;const out=generate(s);const {p,mine}=domainsOf(s);const files:OutFile[]=[];
  const fam=c.family;
  files.push({name:out.name,text:out.text,desc:`整份 ${c.name} 配置（直接导入）`});
  const rules=extractRules(out.text,fam);if(rules)files.push({name:`rules-only.${fam==='singbox'?'json':c.ext}`,text:rules,desc:'只含规则部分（规则集引用 + 规则顺序），可贴进你已有的配置'});
  if(mine.length){const l=listFile(fam,[...new Set(mine.map(m=>m.d))],'proxy');files.push({name:`rule-sets/custom-domains.${l.ext}`,text:l.text,desc:'你的自定义域名 / 按 App 的域名规则集（未写出口，出口在配置里指定）'})}
  for(const x of p.services){
    if(!x.g.custom||!x.g.domains?.length)continue;
    const l=listFile(fam,x.g.domains,x.g.name);files.push({name:`rule-sets/${x.g.id}.${l.ext}`,text:l.text,desc:`「${x.g.name}」的域名清单（手写，约 ${x.g.domains.length} 个）`});
  }
  // 规则来源清单：每个服务组 → 上游规则集 URL
  const L:string[]=['# Lowex 规则来源清单','','每个服务组引用的上游规则集（都是公开的开源规则集，由配置里的 rule-provider / RULE-SET 在客户端上自动更新）。','',`客户端：${c.name}　　生成时间：${new Date().toISOString().slice(0,10)}`,''];
  for(const x of p.services){
    L.push(`## ${x.g.name}（出口：${p.pname(x.p)}）`);
    if(x.g.custom)L.push(`- 手写域名 ${x.g.domains?.length||0} 个（见 rule-sets/${x.g.id}.*）`);
    for(const n of x.g.geosite)L.push(`- 域名：${MC.site(n)}`);
    for(const n of x.g.geoip)L.push(`- IP：${MC.ip(n)}`);
    if(x.g.bm7)L.push(`- blackmatrix7（Surge 类客户端用）：${BM7('Surge',x.g.bm7,'list')}`);
    L.push('');
  }
  files.push({name:'rule-sources.md',text:L.join('\n'),desc:'每个服务组对应的上游规则集地址'});
  // 可读的规则顺序
  const R:string[]=['# Lowex 规则顺序（越靠前优先级越高）',''];
  const rows=ruleRows(p);
  for(const st of STAGES){const rs=rows.filter(r=>r.st===st.id);if(!rs.length)continue;R.push(`## ${st.title}`,`${st.desc}`,'');for(const r of rs)R.push(`- ${r.kind}　${r.value}　→　${r.target}${r.group?`（${r.group}）`:''}`);R.push('')}
  files.push({name:'rules-readable.md',text:R.join('\n'),desc:'人能读懂的完整规则顺序'});
  files.push({name:'lowex-plan.json',text:exportPlan(s,false),desc:'你的全部选择（不含订阅、节点、密钥），可在 Lowex 里导入'});
  files.push({name:'README.txt',text:`Lowex 导出包\n客户端：${c.name}\n导入方法：${c.importHint}\n\n文件说明：\n${files.map(f=>`- ${f.name}：${f.desc}`).join('\n')}\n`,desc:'说明'});
  return files;
}
