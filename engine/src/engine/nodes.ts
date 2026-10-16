export interface Node{
  type:'ss'|'vmess'|'vless'|'trojan'|'hysteria2'|'tuic'|'anytls';
  name:string;server:string;port:number;
  uuid?:string;password?:string;cipher?:string;alterId?:number;
  tls?:boolean;sni?:string;alpn?:string[];insecure?:boolean;fp?:string;
  network?:'tcp'|'ws'|'grpc'|'h2'|'httpupgrade';path?:string;host?:string;service?:string;
  flow?:string;pbk?:string;sid?:string;
  obfs?:string;obfsPassword?:string;up?:string;down?:string;
  congestion?:string;udpRelay?:string;plugin?:string;pluginOpts?:Record<string,string>;
  ports?:string;
}
const b64d=(s:string)=>{s=s.trim().replace(/-/g,'+').replace(/_/g,'/');while(s.length%4)s+='=';try{return decodeURIComponent(escape(atob(s)))}catch{try{return atob(s)}catch{return''}}};
const dec=(s:string)=>{try{return decodeURIComponent(s)}catch{return s}};
const q=(u:URL,k:string)=>u.searchParams.get(k)||undefined;
function net(t?:string):Node['network']{t=(t||'tcp').toLowerCase();return t==='ws'?'ws':t==='grpc'?'grpc':t==='h2'||t==='http'?'h2':t==='httpupgrade'?'httpupgrade':'tcp'}
export function parseNode(line:string):Node|null{
  line=line.trim();if(!line||line.startsWith('#'))return null;
  try{
    if(line.startsWith('vmess://')){
      const j=JSON.parse(b64d(line.slice(8)));
      return{type:'vmess',name:j.ps||j.add,server:j.add,port:+j.port,uuid:j.id,alterId:+j.aid||0,cipher:j.scy||'auto',tls:j.tls==='tls'||j.tls===true,sni:j.sni||j.host||undefined,network:net(j.net),path:j.path||undefined,host:j.host||undefined,service:j.path||undefined,alpn:j.alpn?String(j.alpn).split(','):undefined,fp:j.fp||undefined};
    }
    if(line.startsWith('ss://')){
      let rest=line.slice(5);let name='';const h=rest.indexOf('#');if(h>=0){name=dec(rest.slice(h+1));rest=rest.slice(0,h)}
      let plugin:string|undefined;const qi=rest.indexOf('?');let query='';if(qi>=0){query=rest.slice(qi+1);rest=rest.slice(0,qi)}
      let cred:string,hp:string;
      if(rest.includes('@')){const at=rest.lastIndexOf('@');cred=rest.slice(0,at);hp=rest.slice(at+1);if(!cred.includes(':'))cred=b64d(cred);else cred=dec(cred)}
      else{const d=b64d(rest);const at=d.lastIndexOf('@');cred=d.slice(0,at);hp=d.slice(at+1)}
      const ci=cred.indexOf(':');const cipher=cred.slice(0,ci),password=cred.slice(ci+1);
      const m=hp.replace(/\/$/,'').match(/^\[?([^\]]+?)\]?:(\d+)$/);if(!m)return null;
      const n:Node={type:'ss',name:name||m[1],server:m[1],port:+m[2],cipher,password};
      if(query){const p=new URLSearchParams(query).get('plugin');if(p){const [pn,...opts]=dec(p).split(';');plugin=pn;n.plugin=pn==='simple-obfs'?'obfs':pn;n.pluginOpts={};for(const o of opts){const [k,v]=o.split('=');n.pluginOpts[k]=v??'true'}}}
      return n;
    }
    const u=new URL(line);const name=dec(u.hash.replace(/^#/,''))||u.hostname;const port=+u.port||443;
    if(u.protocol==='vless:'){
      const sec=q(u,'security');
      return{type:'vless',name,server:u.hostname,port,uuid:dec(u.username),tls:sec==='tls'||sec==='reality',sni:q(u,'sni')||q(u,'peer'),fp:q(u,'fp'),flow:q(u,'flow'),network:net(q(u,'type')),path:q(u,'path'),host:q(u,'host'),service:q(u,'serviceName'),pbk:sec==='reality'?q(u,'pbk'):undefined,sid:q(u,'sid'),alpn:q(u,'alpn')?.split(','),insecure:q(u,'allowInsecure')==='1'};
    }
    if(u.protocol==='trojan:'){
      return{type:'trojan',name,server:u.hostname,port,password:dec(u.username),tls:true,sni:q(u,'sni')||q(u,'peer'),network:net(q(u,'type')),path:q(u,'path'),host:q(u,'host'),service:q(u,'serviceName'),alpn:q(u,'alpn')?.split(','),insecure:q(u,'allowInsecure')==='1',fp:q(u,'fp')};
    }
    if(u.protocol==='hysteria2:'||u.protocol==='hy2:'){
      return{type:'hysteria2',name,server:u.hostname,port,password:dec(u.username+(u.password?':'+u.password:'')),tls:true,sni:q(u,'sni'),insecure:q(u,'insecure')==='1',obfs:q(u,'obfs'),obfsPassword:q(u,'obfs-password'),alpn:q(u,'alpn')?.split(','),up:q(u,'up'),down:q(u,'down'),ports:q(u,'mport')};
    }
    if(u.protocol==='tuic:'){
      return{type:'tuic',name,server:u.hostname,port,uuid:dec(u.username),password:dec(u.password),tls:true,sni:q(u,'sni'),insecure:q(u,'allow_insecure')==='1'||q(u,'insecure')==='1',alpn:q(u,'alpn')?.split(','),congestion:q(u,'congestion_control')||'bbr',udpRelay:q(u,'udp_relay_mode')||'native'};
    }
    if(u.protocol==='anytls:'){
      return{type:'anytls',name,server:u.hostname,port,password:dec(u.username),tls:true,sni:q(u,'sni'),insecure:q(u,'insecure')==='1',alpn:q(u,'alpn')?.split(',')};
    }
  }catch{}
  return null;
}
/** 解析粘贴文本：每行一个节点链接，或整段 base64 订阅 */
export function parseNodes(text:string):{nodes:Node[];bad:number}{
  let t=text.trim();if(!t)return{nodes:[],bad:0};
  if(!/:\/\//.test(t.split('\n')[0])){const d=b64d(t.replace(/\s+/g,''));if(/:\/\//.test(d))t=d}
  const nodes:Node[]=[];let bad=0;const seen=new Map<string,number>();
  for(const l of t.split(/\r?\n/)){if(!l.trim()||l.trim().startsWith('#'))continue;const n=parseNode(l);if(!n||!n.server||!n.port){bad++;continue}
    const c=seen.get(n.name)||0;seen.set(n.name,c+1);if(c)n.name=`${n.name} ${c+1}`;nodes.push(n)}
  return{nodes,bad};
}
