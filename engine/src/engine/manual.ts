import type {Node} from './nodes';
import {CLIENTS} from '../data/clients';
/** 手动添加的静态代理（住宅 / 家宽代理包常用：SOCKS5、HTTP、HTTPS） */
export interface ManualNode{id:string;name:string;kind:'socks5'|'http';tls:boolean;host:string;port:number;user?:string;pass?:string;on?:boolean}
export function manualToNode(m:ManualNode):Node{
  return{type:m.kind,name:m.name.trim(),server:m.host.trim(),port:m.port,tls:!!m.tls,username:m.user||undefined,password:m.pass||undefined,manual:true};
}
/** 基础校验：返回错误文字，null = 通过 */
export function manualValidate(m:ManualNode):string|null{
  if(!m.name||!m.name.trim())return'名称不能为空';
  if(/[\r\n]/.test(m.name))return'名称不能换行';
  const h=(m.host||'').trim();
  if(!h)return'服务器地址不能为空';
  if(/[\s,"'\\\/]/.test(h))return'服务器地址含有非法字符（空格、逗号、引号、斜杠）';
  if(!Number.isInteger(m.port)||m.port<1||m.port>65535)return'端口须为 1–65535';
  if(/[\r\n]/.test((m.user||'')+(m.pass||'')))return'用户名 / 密码不能换行';
  return null;
}
/** 该客户端写不出这个手动节点的原因；null = 可以写 */
export function manualIssue(clientId:string,m:ManualNode):string|null{
  const c=CLIENTS.find(x=>x.id===clientId);if(!c)return'未知客户端';
  const bad=manualValidate(m);if(bad)return bad;
  const f=c.family;const tlsSocks=m.kind==='socks5'&&m.tls;
  const cred=(m.user||'')+'\u0000'+(m.pass||'');
  if(f==='loon'&&tlsSocks)return'Loon 官方文档没有 SOCKS5 over TLS 写法';
  if(f==='egern'&&tlsSocks)return'Egern 配置里 SOCKS5 over TLS 的字段未核实，已跳过';
  if(f==='singbox'&&tlsSocks)return'sing-box 的 socks 出站不支持 TLS';
  if(['surge','loon','qx','shadowrocket'].includes(f)){
    if(/"/.test(cred))return'用户名 / 密码含双引号，该客户端的文本配置无法安全转义';
    if(f!=='loon'&&/,/.test(cred))return'用户名 / 密码含英文逗号，该客户端的文本配置无法安全转义';
    if(f==='qx'&&/[=]/.test(cred.replace('\u0000','')))return'用户名 / 密码含「=」，Quantumult X 配置无法安全转义';
    if(/^\s|\s$/.test(m.user||'')||/^\s|\s$/.test(m.pass||''))return'用户名 / 密码首尾有空格，文本配置会丢失空格';
  }
  return null;
}
/** 各客户端支持矩阵（给界面展示） */
export function manualMatrix(){
  const sample=(kind:'socks5'|'http',tls:boolean):ManualNode=>({id:'x',name:'x',kind,tls,host:'example.com',port:1080,user:'u',pass:'p'});
  return CLIENTS.map(c=>({id:c.id,socks5:!manualIssue(c.id,sample('socks5',false)),socks5tls:!manualIssue(c.id,sample('socks5',true)),http:!manualIssue(c.id,sample('http',false)),https:!manualIssue(c.id,sample('http',true))}));
}
