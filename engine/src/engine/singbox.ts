import {setFmt,makePlan,N,MC,regionGroup,HOME_REGEX,type Plan} from './plan';
import {safeRe} from './mihomo';
import type {State} from './types';
import type {Node} from './nodes';
export function singboxOut(n:Node):Record<string,any>{
  const tls:any=n.tls||n.type==='trojan'||n.type==='hysteria2'||n.type==='tuic'||n.type==='anytls'?{enabled:true,...(n.sni?{server_name:n.sni}:{}),...(n.insecure?{insecure:true}:{}),...(n.alpn?{alpn:n.alpn}:{}),
    ...(n.fp||n.pbk?{utls:{enabled:true,fingerprint:n.fp||'chrome'}}:{}),...(n.pbk?{reality:{enabled:true,public_key:n.pbk,short_id:n.sid||''}}:{})}:undefined;
  let transport:any;
  if(n.network&&n.network!=='tcp'){
    if(n.network==='ws')transport={type:'ws',path:n.path||'/',...(n.host?{headers:{Host:n.host}}:{})};
    else if(n.network==='grpc')transport={type:'grpc',service_name:n.service||n.path||''};
    else if(n.network==='h2')transport={type:'http',path:n.path||'/',...(n.host?{host:[n.host]}:{})};
    else if(n.network==='httpupgrade')transport={type:'httpupgrade',path:n.path||'/',...(n.host?{host:n.host}:{})};
  }
  const base:any={tag:n.name,server:n.server,server_port:n.port};
  switch(n.type){
    case'ss':return{type:'shadowsocks',...base,method:n.cipher,password:n.password,...(n.plugin?{plugin:n.plugin==='obfs'?'obfs-local':n.plugin,plugin_opts:Object.entries(n.pluginOpts||{}).map(([k,v])=>`${k}=${v}`).join(';')}:{})};
    case'vmess':return{type:'vmess',...base,uuid:n.uuid,security:n.cipher||'auto',alter_id:n.alterId||0,...(tls?{tls}:{}),...(transport?{transport}:{})};
    case'vless':return{type:'vless',...base,uuid:n.uuid,...(n.flow?{flow:n.flow}:{}),...(tls?{tls}:{}),...(transport?{transport}:{})};
    case'trojan':return{type:'trojan',...base,password:n.password,tls,...(transport?{transport}:{})};
    case'hysteria2':return{type:'hysteria2',...base,password:n.password,tls,...(n.obfs?{obfs:{type:n.obfs,password:n.obfsPassword}}:{}),...(n.up?{up_mbps:parseInt(n.up)||undefined}:{}),...(n.down?{down_mbps:parseInt(n.down)||undefined}:{})};
    case'tuic':return{type:'tuic',...base,uuid:n.uuid,password:n.password,congestion_control:n.congestion,udp_relay_mode:n.udpRelay,tls};
    case'anytls':return{type:'anytls',...base,password:n.password,tls};
  }
}
const tag=(s:string)=>s.replace(/[^A-Za-z0-9]+/g,'-').replace(/^-|-$/g,'');
export function genSingbox(s:State,plan?:Plan):string{
  const p=plan||makePlan(s);const o=s.opts;
  const mobile=s.platform==='ios'||s.platform==='android';
  const nodes=p.nodes;const placeholder=!nodes.length;
  const outs:any[]=[{type:'direct',tag:'direct'}];
  const nodeTags=placeholder?['NODE-PLACEHOLDER']:nodes.map(n=>n.name);
  if(placeholder)outs.push({type:'direct',tag:'NODE-PLACEHOLDER'});else for(const n of nodes)outs.push(singboxOut(n));
  const urltest=(t:string,list:string[])=>({type:'urltest',tag:t,outbounds:list,url:o.testUrl,interval:Math.round(o.urlTestInterval/60)+'m',tolerance:o.tolerance});
  const have=new Set<string>(['direct']);
  const regionTags:string[]=[];
  for(const r of p.regions){
    const re=safeRe(r.regex);const list=nodeTags.filter(t=>re.test(t));if(!list.length||placeholder)continue;
    const man=regionGroup(r,'手动'),au=regionGroup(r,'自动'),fo=regionGroup(r,'故转');
    outs.push({type:'selector',tag:man,outbounds:list},urltest(au,list),{type:'selector',tag:fo,outbounds:[man,au],default:man});
    regionTags.push(fo);have.add(fo);
  }
  outs.push(urltest('全部-自动',nodeTags),{type:'selector',tag:'全部-手动',outbounds:nodeTags});
  outs.push({type:'selector',tag:N.proxy,outbounds:[...regionTags,'全部-自动','全部-手动','direct'],default:regionTags[0]||'全部-自动'});
  have.add(N.proxy);
  if(p.overseas){const re=safeRe(HOME_REGEX);const l=nodeTags.filter(t=>re.test(t)&&!placeholder);outs.push({type:'selector',tag:N.home,outbounds:[...l,'direct'],default:l[0]||'direct'});have.add(N.home)}
  const tg=(pol:string)=>{if(pol==='DIRECT')return'direct';if(pol==='REJECT')return'REJECT';const n=p.pname(pol);return have.has(n)?n:N.proxy};
  const opts=[N.proxy,...regionTags,'direct'];
  for(const x of p.services){const f=tg(x.p);outs.push({type:'selector',tag:x.g.name,outbounds:[f,...opts.filter(y=>y!==f),...(p.overseas&&f!==N.home?[N.home]:[])],default:f});have.add(x.g.name)}
  outs.push({type:'selector',tag:N.final,outbounds:[o.unknown==='proxy'?N.proxy:'direct',N.proxy,'direct'],default:o.unknown==='proxy'?N.proxy:'direct'});
  // rules
  const rs:Record<string,any>={};const rules:any[]=[{action:'sniff'},{protocol:'dns',action:'hijack-dns'}];
  const rsAdd=(kind:'site'|'ip',name:string)=>{const t=(kind==='site'?'gs-':'gi-')+tag(name);if(!rs[t])rs[t]={type:'remote',tag:t,format:'binary',url:kind==='site'?MC.ssite(name):MC.sip(name),update_interval:o.lowMemory?'3d':'1d'};return t};
  const act=(t:string)=>t==='REJECT'?{action:'reject'}:{action:'route',outbound:t};
  const outbound=(t:string)=>t==='REJECT'?{action:'reject'}:{outbound:t};
  const svc=(g:any,pol:string)=>{if(pol==='REJECT')return'REJECT';const x=p.services.find(y=>y.g.id===g.id);return x?x.g.name:tg(pol)};
  for(const r of p.rules){
    switch(r.t){
      case'comment':break;
      case'suffix':rules.push({domain_suffix:[r.v],...outbound(r.via&&r.p!=='REJECT'?(p.services.find(x=>x.g.id===r.via)?.g.name||tg(r.p)):tg(r.p))});break;
      case'ipcidr':rules.push({ip_cidr:[r.v],...outbound(tg(r.p))});break;
      case'process':rules.push({process_name:[r.v],...outbound(tg(r.p))});break;
      case'package':rules.push({package_name:[r.v],...outbound(tg(r.p))});break;
      case'rset':{const t='cs-'+tag(r.id);rs[t]={type:'remote',tag:t,format:setFmt(r.url)==='srs'?'binary':'source',url:r.url,update_interval:o.lowMemory?'3d':'1d'};rules.push({rule_set:[t],...outbound(tg(r.p))});break}
      case'quic':rules.push({type:'logical',mode:'and',rules:[{network:'udp'},{port:443},{rule_set:[rsAdd('site','cn'),rsAdd('ip','cn')],invert:true}],action:'reject'});break;
      case'stun':rules.push({network:'udp',port:[3478,3479,5349],port_range:['19302:19309'],...outbound(tg(r.p))});break;
      case'wifi':rules.push({type:'logical',mode:'and',rules:[{network:'udp'},{port:[500,4500]},{domain_suffix:r.domains}],...outbound(tg(r.p))});rules.push({domain_suffix:r.domains,...outbound(tg(r.p))});break;
      case'final':break;
      case'site':{
        if(r.name==='private'){rules.push({ip_is_private:true,outbound:'direct'});rules.push({rule_set:[rsAdd('site','private')],outbound:'direct'});break}
        const direct=r.g.id==='cn'||r.g.category==='direct';rules.push({rule_set:[rsAdd('site',r.name)],...outbound(direct?tg(r.p):svc(r.g,r.p))});break}
      case'ip':{if(r.name==='private')break;const direct=r.g.id==='cn';rules.push({rule_set:[rsAdd('ip',r.name)],...outbound(direct?tg(r.p):svc(r.g,r.p))});break}
    }
  }
  const dnsServers:any[]=[...o.dnsCn.map((u,i)=>dohServer('dns-cn'+(i||''),u)),...o.dnsRemote.map((u,i)=>({...dohServer('dns-remote'+(i||''),u),detour:N.proxy})),
    ...(o.fakeIp?[{type:'fakeip',tag:'dns-fakeip',inet4_range:'198.18.0.0/15'}]:[]),{type:'local',tag:'dns-local'}];
  const dnsRules:any[]=[];
  if(o.homeDomain&&o.lanDns)dnsRules.push({domain_suffix:[o.homeDomain],action:'route',server:'dns-lan'});
  if(o.homeDomain&&o.lanDns)dnsServers.push({type:'udp',tag:'dns-lan',server:o.lanDns});
  dnsRules.push({rule_set:[rsAdd('site','cn')],action:'route',server:'dns-cn'});
  dnsRules.push({rule_set:[rsAdd('site','private')],action:'route',server:'dns-local'});
  if(o.fakeIp)dnsRules.push({query_type:['A'],action:'route',server:'dns-fakeip'});
  const tunAddr=['172.19.0.1/30',...(o.ipv6?['fdfe:dcba:9876::1/126']:[])];
  const cfg:any={
    log:{level:o.logLevel==='warning'?'warn':o.logLevel},
    dns:{servers:dnsServers,rules:dnsRules,final:'dns-remote',...(o.ipv6?{}:{strategy:'ipv4_only'})},
    inbounds:[...(o.tun?[{type:'tun',tag:'tun-in',address:tunAddr,mtu:o.mtu,auto_route:true,strict_route:true}]:[]),...(mobile?[]:[{type:'mixed',tag:'mixed-in',listen:o.allowLan?'0.0.0.0':'127.0.0.1',listen_port:o.mixedPort}])],
    outbounds:outs,
    route:{rules,rule_set:Object.values(rs),final:N.final,default_domain_resolver:'dns-cn',auto_detect_interface:true,default_http_client:'dl',...(p.rules.some(r=>r.t==='process'||r.t==='package')?{find_process:true}:{})},
    http_clients:[{tag:'dl',detour:'direct'}],
    experimental:{cache_file:{enabled:true,...(o.fakeIp?{store_fakeip:true}:{})}},
  };
  const hdr=`// Lowex 生成 · sing-box 1.14 · ${new Date().toISOString().slice(0,10)}\n`;
  void hdr;
  return JSON.stringify(cfg,null,2);
}
function dohServer(tag:string,u:string):any{
  try{const x=new URL(u);if(x.protocol==='tls:')return{type:'tls',tag,server:x.hostname};return{type:'https',tag,server:x.hostname,path:x.pathname||'/dns-query'}}catch{return{type:'udp',tag,server:u}}
}
