import {useEffect,useState,useCallback} from 'react';
import type {State,Opts} from './engine/types';
import {defaultOpts} from './engine/recommend';
const KEY='lowex:v1',SECRET_KEY='lowex:secrets';
export function initial():State{
  return{client:'verge',platform:'windows',location:'cn',network:'other',subs:[],nodesText:'',regions:['HK','TW','JP','SG','US'],groups:{},apps:[],customDomains:[],opts:defaultOpts()};
}
export function load():{s:State;remember:boolean}{
  const base=initial();
  try{
    const j=JSON.parse(localStorage.getItem(KEY)||'null');
    const sec=JSON.parse(localStorage.getItem(SECRET_KEY)||'null');
    if(j){const s={...base,...j.s,opts:{...base.opts,...(j.s?.opts||{})}} as State;if(sec){s.subs=sec.subs||[];s.nodesText=sec.nodesText||''}return{s,remember:!!sec}}
  }catch{}
  const ua=navigator.userAgent;
  if(/iPhone|iPad/.test(ua)){base.platform='ios';base.client='shadowrocket'}
  else if(/Android/.test(ua)){base.platform='android';base.client='flclash'}
  else if(/Mac/.test(ua)){base.platform='macos'}
  return{s:base,remember:false};
}
export function useStore(){
  const [init]=useState(load);
  const [s,setS]=useState<State>(init.s);
  const [remember,setRemember]=useState(init.remember);
  useEffect(()=>{
    const {subs,nodesText,...rest}=s;
    try{localStorage.setItem(KEY,JSON.stringify({s:{...rest,subs:[],nodesText:''}}));
      if(remember)localStorage.setItem(SECRET_KEY,JSON.stringify({subs,nodesText}));else localStorage.removeItem(SECRET_KEY)}catch{}
  },[s,remember]);
  const set=useCallback((p:Partial<State>|((s:State)=>Partial<State>))=>setS(o=>({...o,...(typeof p==='function'?p(o):p)})),[]);
  const setOpts=useCallback((p:Partial<Opts>)=>setS(o=>({...o,opts:{...o.opts,...p}})),[]);
  return{s,set,setOpts,setS,remember,setRemember};
}
/** 导出方案（默认不含订阅与节点；secret 也不导出） */
export function exportPlan(s:State,withSecrets:boolean){
  const {subs,nodesText,opts,modules,mitmHosts,...rest0}=s;const rest:any=rest0;const {secret,...o}=opts;
  return JSON.stringify({lowex:1,...rest,opts:o,...(withSecrets?{modules,mitmHosts}:{}),...(withSecrets?{subs,nodesText,secret}:{})},null,1);
}
export function importPlan(text:string,cur:State):State{
  const j=JSON.parse(text);if(!j||j.lowex!==1)throw new Error('不是 Lowex 方案文件');
  const {lowex,subs,nodesText,opts,...rest}=j;
  return{...cur,...rest,opts:{...cur.opts,...(opts||{}),...(j.secret?{secret:j.secret}:{})},subs:subs||cur.subs,nodesText:nodesText??cur.nodesText};
}
