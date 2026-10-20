import {ICONS} from '../data/icons';
import {resolveIcon} from '../data/icon-audit';
import {GROUPS,CORE} from '../data/groups';
import type {Plan} from './plan';
import {N} from './plan';
import {has} from '../data/caps';

/** 策略组名称 → 图标 URL（只有声明支持图标的客户端才会用到；找不到的组不写图标） */
export function iconMap(p:Plan):Record<string,string>{
  const m:Record<string,string>={};
  const put=(name:string,key:string)=>{const u=resolveIcon(key,ICONS[key]);if(u)m[name]=u};
  put(N.proxy,'s:proxy');put(N.final,'s:final');put(N.update,'s:update');put(N.home,'s:home');put(N.webrtc,'s:final');put('国内直连','s:direct');
  put('全部-自动','s:autoAll');put('全部-手动','s:manAll');put('全部-订阅','s:manAll');put('全部-负载均衡','s:lb');
  for(const r of p.regions)for(const k of ['手动','自动','故转'])put(`${r.name}-${k}`,'r:'+r.id);
  for(const g of [...GROUPS,...Object.values(CORE)])put(g.name,'g:'+g.id);
  return m;
}
export const iconsOn=(p:Plan)=>has(p.state.client,'icons')&&p.state.opts.icons!==false;
/** Surge / Loon / QX：在策略组行末追加图标参数（Surge icon-url，Loon / QX img-url） */
export function iconLines(L:string[],fmt:'surge'|'loon'|'qx',p:Plan):string[]{
  if(!iconsOn(p))return L;
  const m=iconMap(p);let sec='';
  return L.map(l=>{
    const h=/^\[(.+)\]$/.exec(l);if(h){sec=h[1].toLowerCase();return l}
    if(l.startsWith('#')||!l.trim())return l;
    if(fmt==='qx'){if(sec!=='policy')return l;const x=/^(static|available|round-robin|url-latency-benchmark|dynamic)=\s*([^,]+),/.exec(l);const u=x&&m[x[2].trim()];return u?`${l}, img-url=${u}`:l}
    if(sec!=='proxy group')return l;
    const x=/^([^=]+?)\s*=\s*(select|url-test|fallback|load-balance|smart)\b/i.exec(l);const u=x&&m[x[1].trim()];
    return u?(fmt==='surge'?`${l}, icon-url=${u}`:`${l},img-url=${u}`):l});
}
