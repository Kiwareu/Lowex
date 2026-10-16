const plain=/^[A-Za-z_][A-Za-z0-9_./-]*$/;
const reserved=/^(true|false|null|yes|no|on|off|~)$/i;
export function sc(v:any):string{
  if(typeof v==='string'){return plain.test(v)&&!reserved.test(v)?v:JSON.stringify(v)}
  return JSON.stringify(v);
}
export function flow(v:any):string{
  if(Array.isArray(v))return'['+v.map(flow).join(', ')+']';
  if(v&&typeof v==='object')return'{'+Object.entries(v).filter(([,x])=>x!==undefined).map(([k,x])=>`${sc(k)}: ${flow(x)}`).join(', ')+'}';
  return sc(v);
}
export function block(o:Record<string,any>,ind=0):string{
  const pad=' '.repeat(ind);let out='';
  for(const [k,v] of Object.entries(o)){
    if(v===undefined)continue;
    if(Array.isArray(v)){
      if(!v.length){out+=`${pad}${sc(k)}: []\n`;continue}
      out+=`${pad}${sc(k)}:\n`;for(const it of v)out+=`${pad}  - ${flow(it)}\n`;
    }else if(v&&typeof v==='object'){
      if(!Object.keys(v).length){out+=`${pad}${sc(k)}: {}\n`;continue}
      out+=`${pad}${sc(k)}:\n`+block(v,ind+2);
    }else out+=`${pad}${sc(k)}: ${sc(v)}\n`;
  }
  return out;
}
