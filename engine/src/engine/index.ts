import type {State} from './types';
import {CLIENTS} from '../data/clients';
import {genMihomo} from './mihomo';
import {genSingbox} from './singbox';
import {genSurge,genLoon,genQX,genShadowrocket,genEgern} from './ini';
import {renderModules} from './modules';
export {makePlan} from './plan';
export function generate(s:State):{text:string;ext:string;mime:string;name:string}{
  const c=CLIENTS.find(x=>x.id===s.client)!;
  let text='';
  switch(c.family){
    case'mihomo':text=genMihomo(s);break;
    case'singbox':text=genSingbox(s);break;
    case'surge':text=genSurge(s);break;
    case'loon':text=genLoon(s);break;
    case'qx':text=genQX(s);break;
    case'shadowrocket':text=genShadowrocket(s);break;
    case'egern':text=genEgern(s);break;
    case'stash':text=genMihomo(s,undefined,true);break;
  }
  if(['surge','loon','qx','shadowrocket','stash','egern'].includes(c.family))text=text.replace(/\n*$/,'\n')+renderModules(s).text;
  return{text,ext:c.ext,mime:c.mime,name:`lowex-${c.id}.${c.ext}`};
}
