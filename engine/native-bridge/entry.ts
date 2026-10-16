// 原生 SwiftUI 版用：把生成引擎打成单个 IIFE，由 JavaScriptCore 加载。界面全部是原生 SwiftUI，引擎沿用网页版（同一份逻辑，不重写）。
import {generate} from '../src/engine';
import {manualMatrix,manualIssue} from '../src/engine/manual';
import {defaultOpts,recommend} from '../src/engine/recommend';
import {CLIENTS,PLATFORMS} from '../src/data/clients';
import {GROUPS,REGIONS,CATS} from '../src/data/groups';
import {ICONS} from '../src/data/icons';
import {APPDB} from '../src/data/appdb';
import {SHARED} from '../src/data/shared';
import {RESEARCH} from '../src/data/research';
import {VERSION} from '../src/version';
import {has,CAPS} from '../src/data/caps';
import {makePlan} from '../src/engine/plan';
import {leakChecklist,leakScore,STATUS_TEXT} from '../src/engine/leak';
import {CARRIERS} from '../src/data/carriers';
import {parseModule,safety,KIND_NAME,supportsModules} from '../src/engine/modules';
import {PRESETS} from '../src/engine/tools';
import {CLIENTS as CL2} from '../src/data/clients';
const J=(x:unknown)=>JSON.stringify(x);
(globalThis as any).Lowex={
  version:VERSION,
  /** 初始方案（JSON 字符串） */
  initial:(client:string,platform:string)=>J({client,platform,location:'cn',network:'other',subs:[],nodesText:'',regions:['HK','TW','JP','SG','US'],groups:{},apps:[],customDomains:[],opts:defaultOpts()}),
  manualMatrix:()=>J(manualMatrix()),
  manualIssue:(client:string,json:string)=>{try{return J({issue:manualIssue(client,JSON.parse(json))})}catch(e:any){return J({issue:String(e)})}},
  catalog:()=>J({clients:CLIENTS.map(c=>({id:c.id,name:c.name,family:c.family,platforms:c.platforms,blurb:c.blurb,ext:c.ext,subInConfig:c.subInConfig,processRules:c.processRules,importHint:c.importHint,placement:RESEARCH[c.id]?.placement||'config',howConfig:RESEARCH[c.id]?.howConfig||'',howApp:RESEARCH[c.id]?.howApp||'',inApp:RESEARCH[c.id]?.inApp||[],conf:RESEARCH[c.id]?.conf||'low',verified:RESEARCH[c.id]?.verified||false,caps:(Object.keys(CAPS) as any[]).filter(f=>has(c.id,f))})),platforms:PLATFORMS,capList:Object.entries(CAPS).map(([k,v])=>({id:k,label:(v as any).label})),
    groups:GROUPS.map(g=>({id:g.id,name:g.name,cat:g.cat,def:g.def,defOn:g.defOn,risk:g.risk,notes:g.notes,icon:ICONS['g:'+g.id]||null})),
    regions:REGIONS.map(r=>({id:r.id,name:r.name,icon:ICONS['r:'+r.id]||null})),cats:CATS,
    apps:APPDB.map(a=>({n:a.n,en:a.en||null,pkg:a.pkg||null,exe:a.exe||null,bid:a.bid||null,dom:a.dom||[],g:a.g||null})),
    shared:SHARED}),
  leak:(sj:string)=>{try{const s=JSON.parse(sj);let text='';try{text=generate(s).text||''}catch(e){}const items=leakChecklist(s,text);return J({items,status:STATUS_TEXT,score:leakScore(items)})}catch(e:any){return J({items:[],status:{}})}},
  carriers:()=>J(CARRIERS),
  sharedList:()=>J(SHARED),
  modInfo:(name:string,url:string,content:string)=>{try{const P=content.trim()?parseModule(content):null;const S=safety({name,url,content},P);return J({fmt:P?P.fmt:'unknown',name:P?P.name:'',rw:P?P.rewrites.length:0,sc:P?P.scripts.length:0,blocked:S.blocked,warns:S.warns})}catch(e:any){return J({error:String(e)})}},
  supportsModules:(client:string)=>{const c=CL2.find(x=>x.id===client);return !!c&&supportsModules(c.family)},
  recommend:(net:string,loc:string,platform:string)=>J(recommend(net as any,loc as any,platform)),
  supports:(client:string,feat:string)=>has(client,feat as any),
  presets:()=>J(PRESETS.map(p=>({id:p.id,name:p.name,desc:p.desc}))),
  applyPreset:(id:string,stateJson:string)=>{try{const s=JSON.parse(stateJson);const pr=PRESETS.find(x=>x.id===id);if(!pr)return J({error:'unknown preset'});const patch=pr.apply(s);return J({...s,...patch,opts:{...s.opts,...(patch.opts||{})},groups:{...s.groups,...(patch.groups||{})}})}catch(e:any){return J({error:String(e&&e.message||e)})}},
  /** 入参：方案 JSON；返回 {text,ext,mime,name,warnings} 或 {error} */
  generate:(stateJson:string)=>{try{const s=JSON.parse(stateJson);const r=generate(s);return J({...r,warnings:makePlan(s).warnings})}catch(e:any){return J({error:String(e&&e.message||e)})}},
};
