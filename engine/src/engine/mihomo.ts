import {block,flow} from './yaml';
import {setFmt,makePlan,subNames,N,MC,BM7,regionGroup,HOME_REGEX,type Plan} from './plan';
import type {State} from './types';
import type {Node} from './nodes';
import {iconMap,iconsOn} from './icons';

export function mihomoProxy(n:Node):Record<string,any>{
  const o:Record<string,any>={name:n.name,type:n.type,server:n.server,port:n.port};
  const tlsCommon=()=>{if(n.tls)o.tls=true;if(n.sni)o.servername=n.sni;if(n.insecure)o['skip-cert-verify']=true;if(n.fp)o['client-fingerprint']=n.fp;if(n.alpn)o.alpn=n.alpn};
  const trans=()=>{
    if(n.network&&n.network!=='tcp'){o.network=n.network;
      if(n.network==='ws')o['ws-opts']={path:n.path||'/',...(n.host?{headers:{Host:n.host}}:{})};
      if(n.network==='grpc')o['grpc-opts']={'grpc-service-name':n.service||n.path||''};
      if(n.network==='h2')o['h2-opts']={path:n.path||'/',host:n.host?[n.host]:[]};
      if(n.network==='httpupgrade')o['http-opts']={method:'GET',path:[n.path||'/'],...(n.host?{headers:{Host:[n.host]}}:{})};}
  };
  switch(n.type){
    case'socks5':case'http':if(n.username)o.username=n.username;if(n.password)o.password=n.password;if(n.tls)o.tls=true;if(n.type==='socks5')o.udp=true;break;
    case'ss':o.cipher=n.cipher;o.password=n.password;o.udp=true;if(n.plugin){o.plugin=n.plugin;o['plugin-opts']=n.pluginOpts}break;
    case'vmess':o.uuid=n.uuid;o.alterId=n.alterId||0;o.cipher=n.cipher||'auto';o.udp=true;tlsCommon();trans();break;
    case'vless':o.uuid=n.uuid;o.udp=true;if(n.flow)o.flow=n.flow;tlsCommon();trans();if(n.pbk)o['reality-opts']={'public-key':n.pbk,'short-id':n.sid||''};break;
    case'trojan':o.password=n.password;o.udp=true;o.tls=true;if(n.sni)o.sni=n.sni;if(n.insecure)o['skip-cert-verify']=true;if(n.fp)o['client-fingerprint']=n.fp;if(n.alpn)o.alpn=n.alpn;trans();break;
    case'hysteria2':o.password=n.password;if(n.sni)o.sni=n.sni;if(n.insecure)o['skip-cert-verify']=true;if(n.obfs){o.obfs=n.obfs;o['obfs-password']=n.obfsPassword}if(n.alpn)o.alpn=n.alpn;if(n.up)o.up=n.up;if(n.down)o.down=n.down;if(n.ports)o.ports=n.ports;break;
    case'tuic':o.uuid=n.uuid;o.password=n.password;if(n.sni)o.sni=n.sni;if(n.insecure)o['skip-cert-verify']=true;if(n.alpn)o.alpn=n.alpn;o['congestion-controller']=n.congestion;o['udp-relay-mode']=n.udpRelay;break;
    case'anytls':o.password=n.password;if(n.sni)o.sni=n.sni;if(n.insecure)o['skip-cert-verify']=true;if(n.fp)o['client-fingerprint']=n.fp;if(n.alpn)o.alpn=n.alpn;break;
  }
  return o;
}
/** fake-ip-filter 追加项：系统联网检测 / 校时域名。拿到假 IP 会导致「无网络」误判或校时失败。
 *  解析仍走 nameserver-policy / nameserver（respect-rules），不新增泄漏面。
 *  不收 stun/turn 通配、远控/游戏/厂商域名（属偏好，非联网检测）。
 *  依据：https://wiki.metacubex.one/en/config/dns/#fake-ip-filter */
export const FAKEIP_EXTRA=['+.localdomain','+.msftconnecttest.com','+.msftncsi.com','captive.apple.com','connectivitycheck.android.com','detectportal.firefox.com','nmcheck.gnome.org','time.*.gov','time.*.apple.com','+.ntp.org'];
const key=(s:string)=>s.replace(/!/g,'_not_').replace(/[^A-Za-z0-9]+/g,'_').replace(/__+/g,'_').replace(/^_|_$/g,''); // !cn（非中国）保留为 _not_，避免 gs_category_ai_cn 这类误导名
export function genMihomo(s:State,plan?:Plan,stash=false):string{
  const p=plan||makePlan(s);const o=s.opts;
  const mobile=s.platform==='ios'||s.platform==='android';
  const low=o.lowMemory;
  const hdr=`# Lowex 生成 · ${stash?'Stash':'Mihomo'} · ${new Date().toISOString().slice(0,10)}\n${p.appMode?'# 覆写模式：不含订阅/节点；请先在客户端 App 内添加订阅，再把本文件作为覆写/扩展配置导入。\n':''}# 全部在浏览器本地生成，未上传任何内容。订阅链接/密钥属于敏感信息，分享前请删除。\n`;
  const top:Record<string,any>={
    'mixed-port':o.mixedPort,'allow-lan':o.allowLan,'bind-address':o.allowLan?'*':'127.0.0.1',mode:'rule',ipv6:o.ipv6,'log-level':o.logLevel,
    'unified-delay':true,'tcp-concurrent':true,...(stash?{}:{'find-process-mode':s.platform==='ios'?'off':(p.rules.some(r=>r.t==='process')?'always':'strict')}),
    ...(stash?{}:{'geo-auto-update':false,'etag-support':true,'global-ua':'clash.meta'}),
    ...(o.keepAlive&&!stash?{'keep-alive-idle':600,'keep-alive-interval':30}:{}),
    ...(stash?{}:{profile:{'store-selected':true,'store-fake-ip':true}}),
    ...(stash?{}:{'external-controller':`127.0.0.1:${o.apiPort}`,secret:o.secret,
      'external-controller-cors':{'allow-origins':['http://127.0.0.1:*','http://localhost:*','tauri://localhost',...o.panelOrigins],'allow-private-network':true}}),
  };
  const dnsCnDoh=o.dnsCn;
  const cnNs=(o.cnDnsMode==='system'&&!stash)?['system']:o.dnsCn;
  const boot=(o.dnsBootstrap&&o.dnsBootstrap.length)?o.dnsBootstrap:['223.5.5.5','119.29.29.29'];
  const homeDom=o.homeDomain?[o.homeDomain]:[];
  const dnsPolicy:Record<string,any>={};
  if(!stash){dnsPolicy['rule-set:private_domain']='system';dnsPolicy['rule-set:cn_domain']=cnNs}
  if(o.homeDomain&&o.lanDns)dnsPolicy[`+.${o.homeDomain}`]=o.lanDns;
  if(o.campusDomain&&o.lanDns)for(const d of o.campusDomain.split(/[\s,]+/).filter(Boolean))dnsPolicy[`+.${d}`]=o.lanDns;
  const dns:Record<string,any>=stash?{enable:true,ipv6:o.ipv6,'enhanced-mode':'fake-ip','fake-ip-range':'198.18.0.1/16','default-nameserver':boot,nameserver:dnsCnDoh,fallback:o.dnsRemote,'fake-ip-filter':['+.lan','+.local','time.*.com','ntp.*.com','+.pool.ntp.org','+.connectivitycheck.gstatic.com',...FAKEIP_EXTRA,...homeDom.map(d=>'+.'+d)]}:{
    enable:true,ipv6:o.ipv6,'prefer-h3':false,'enhanced-mode':o.fakeIp?'fake-ip':'redir-host','cache-algorithm':low||mobile?'lru':'arc',
    ...(o.fakeIp?{'fake-ip-range':'198.18.0.1/16','fake-ip-filter-mode':'blacklist','fake-ip-filter':['+.lan','+.local','+.arpa','time.*.com','ntp.*.com','+.pool.ntp.org','+.connectivitycheck.gstatic.com',...FAKEIP_EXTRA,'rule-set:cn_domain','rule-set:private_domain',...homeDom.map(d=>'+.'+d),...(o.campusDomain?o.campusDomain.split(/[\s,]+/).filter(Boolean).map(d=>'+.'+d):[])]}:{}),
    'respect-rules':true,'use-hosts':true,'use-system-hosts':false,
    'default-nameserver':boot,
    'proxy-server-nameserver':dnsCnDoh,'direct-nameserver':cnNs,'direct-nameserver-follow-policy':false,
    'nameserver-policy':dnsPolicy,
    nameserver:[...o.dnsRemote,...(stash?[]:['tls://8.8.4.4'])],
    // 不再输出 fallback / fallback-filter：nameserver（境外加密 DNS + respect-rules）与
    // nameserver-policy / proxy-server-nameserver / direct-nameserver 已覆盖国内外分流。
    // wiki：nameserver-policy 优先于 nameserver/fallback 查询；境外 DoH 经
    // respect-rules 走代理加密，fallback 的并发重查不再必要（官方 DNS 文档）。
    // Stash 分支保留 fallback：无 nameserver-policy，仍依赖 fallback。
  };
  if(p.overseas&&!stash){dns['nameserver-policy']={...dnsPolicy,'rule-set:cn_domain':cnNs}}
  const tun:Record<string,any>={enable:o.tun,stack:o.tunStack,'dns-hijack':['any:53','tcp://any:53'],'auto-route':true,'auto-detect-interface':true,'strict-route':true,mtu:o.mtu,'udp-timeout':300};
  const sniffer={enable:true,'parse-pure-ip':true,'force-dns-mapping':true,'override-destination':false,sniff:{QUIC:{ports:[443]},TLS:{ports:[443,8443]},HTTP:{ports:[80,'8080-8880'],'override-destination':true}},
    'force-domain':['+.netflix.com','+.nflxvideo.net','+.amazonaws.com','+.media.dssott.com','+.tiktok.com','+.binance.com','+.bybit.com','+.okx.com','+.kraken.com','+.payward.com','+.mexc.com','+.mexcservices.com','+.krak.io','+.whatsapp.com','+.line.me','+.bunq.com','+.sumup.com'],
    'skip-domain':['+.push.apple.com','dlg.io.mi.com','+.mi.com','+.xiaomi.com','+.miwifi.com','+.oray.com','+.sunlogin.net',...homeDom.map(d=>'+.'+d)]};
  // proxies / providers
  const proxies=p.nodes.map(mihomoProxy);
  const providers:Record<string,any>={};
  const subs=p.appMode?[]:(p.subs.length?p.subs:(p.nodes.length?[]:[{name:'',url:'{{SUB_URL_1}}'}]));
  const subKeys=subNames(subs,i=>'sub'+(i+1));
  subs.forEach((x,i)=>{providers[subKeys[i]]={type:'http',url:x.url,interval:86400,...(o.nodeInclude?.trim()?{filter:o.nodeInclude.trim()}:{}),...(o.nodeExclude?.trim()?{'exclude-filter':o.nodeExclude.trim()}:{}),...(stash?{}:{proxy:N.update,'health-check':{enable:true,interval:600,url:o.testUrl},
    override:{...(x.name?{'additional-prefix':`[${x.name}] `}:{}),'override-expr':['(select(.type == "vless" or .type == "vmess" or .type == "trojan" or .type == "anytls" or .tls == true) | ."client-fingerprint") |= (. // "chrome")']}})}});
  // groups
  const pg:any[]=[];
  const regionNames:string[]=[];
  const inc:any=stash?{use:Object.keys(providers)}:{'include-all':true};
  const stashProxies=stash&&p.nodes.length?{proxies:p.nodes.map(n=>n.name)}:{};
  void stashProxies;
  pg.push({name:N.update,type:'select',proxies:[N.proxy,'DIRECT']}); // 默认走代理：国内订阅与规则集直连多半刷不出，走代理还隐藏 SNI
  const reg=p.regions;
  const allNodes=()=>p.nodes.map(n=>n.name);
  const regionHas=(r:{regex:string})=>{if(!p.nodes.length||p.subs.length)return true;const re=safeRe(r.regex);return p.nodes.some(n=>re.test(n.name))};
  const usable=reg.filter(regionHas);
  const mk=(name:string,type:string,extra:any)=>({name,type,...(stash?{use:Object.keys(providers).length?Object.keys(providers):undefined,...(p.nodes.length?{}:{})}:{'include-all':true}),...extra});
  const lazy:any={url:o.testUrl,interval:Math.min(o.urlTestInterval,600),lazy:true,timeout:3000,'max-failed-times':2,tolerance:o.tolerance};
  const useFo=o.failover!==false;
  for(const r of usable){
    const man=regionGroup(r,'手动'),au=regionGroup(r,'自动'),fo=regionGroup(r,'故转');
    const f=r.regex;
    pg.push(stash?{name:man,type:'select',...(Object.keys(providers).length?{use:Object.keys(providers)}:{}),filter:stripFlags(f)}:{name:man,type:'select','include-all':true,filter:f,'empty-fallback':'REJECT'});
    pg.push(stash?{name:au,type:'url-test',...(Object.keys(providers).length?{use:Object.keys(providers)}:{}),filter:stripFlags(f),url:o.testUrl,interval:o.urlTestInterval,tolerance:o.tolerance}:{name:au,type:'url-test','include-all':true,filter:f,...lazy,'empty-fallback':'REJECT'});
    // 精确 fallback：lazy:false 才能后台持续探测，节点变红/超时才自动跳转；间隔钳到 ≤600 秒
    if(useFo){pg.push({name:fo,type:'fallback',proxies:[man,au],url:o.testUrl,interval:Math.min(o.urlTestInterval,600),lazy:false,timeout:3000,'max-failed-times':2,'empty-fallback':'REJECT'});regionNames.push(fo)} // 不 hidden：用户要在客户端点进故障转移组
    else regionNames.push(au);
  }
  const autoAll={name:'全部-自动',type:'url-test',...(stash?(Object.keys(providers).length?{use:Object.keys(providers)}:{}):{'include-all':true}),url:o.testUrl,interval:Math.min(o.urlTestInterval,600),tolerance:o.tolerance,...(stash?{}:{lazy:true,timeout:3000,'max-failed-times':2})};
  const manAll={name:'全部-手动',type:'select',...(stash?(Object.keys(providers).length?{use:Object.keys(providers)}:{}):{'include-all':true})};
  if(stash&&p.nodes.length){(autoAll as any).proxies=allNodes();(manAll as any).proxies=allNodes()}
  const lb:any={name:'全部-负载均衡',type:'load-balance',strategy:'consistent-hashing',...(stash?(Object.keys(providers).length?{use:Object.keys(providers)}:{}):{'include-all':true}),url:o.testUrl,interval:Math.min(o.urlTestInterval,600),...(stash?{}:{lazy:true})};
  if(stash&&p.nodes.length)lb.proxies=allNodes();
  pg.push({name:'国内直连',type:'select',proxies:['DIRECT'],hidden:true});
  const manNames=usable.map(r=>regionGroup(r,'手动'));
  const autoNames=usable.map(r=>regionGroup(r,'自动'));
  // 对齐作者模板：故转 → 自动 → 手动 → 全部-* → 国内直连；无故转时不重复列出自动
  const proxyMembers=useFo
    ?[...regionNames,...autoNames,...manNames,'全部-自动','全部-手动',...(o.lbGroup?['全部-负载均衡']:[]),'国内直连']
    :[...regionNames,...manNames,'全部-自动','全部-手动',...(o.lbGroup?['全部-负载均衡']:[]),'国内直连'];
  pg.splice(1,0,{name:N.proxy,type:'select',proxies:proxyMembers});
  pg.push(autoAll,manAll);if(o.lbGroup)pg.push(lb);
  if(p.overseas)pg.push(stash?{name:N.home,type:'select',...(Object.keys(providers).length?{use:Object.keys(providers)}:{}),filter:stripFlags(HOME_REGEX),proxies:['DIRECT']}:{name:N.home,type:'select','include-all':true,filter:HOME_REGEX,proxies:['DIRECT']});
  const pn=(pol:string)=>{const n=p.pname(pol);return n.endsWith('-故转')&&!regionNames.includes(n)?N.proxy:n};
  // 服务组：含每地区的 故障转移/自动/手动 三种模式，点进服务组可直接切换（与一键代理对齐）
  const svcModes=useFo?[...regionNames,...autoNames,...manNames]:[...regionNames,...manNames];
  const opts=[N.proxy,...svcModes,'DIRECT'];
  const polAll=(first:string)=>{const f=first;return [f,...opts.filter(x=>x!==f),...(p.overseas&&f!==N.home?[N.home]:[])]};
  for(const x of p.services){pg.push({name:x.g.name,type:'select',proxies:polAll(pn(x.p))})}
  {const base=useFo?[...regionNames,...autoNames,...manNames]:[...regionNames,...manNames];
const all=[N.proxy,...base,'全部-自动','全部-手动',...(o.lbGroup?['全部-负载均衡']:[]),'DIRECT',...(p.overseas?[N.home]:[])];
const ff=o.unknown==='proxy'?N.proxy:'DIRECT';pg.push({name:N.final,type:'select',proxies:[ff,...all.filter(x=>x!==ff)]});}
  // WebRTC 组（仅 Mihomo；Stash 用 PROTOCOL,STUN 固定出口）：默认跟 opts.stun；不放 DIRECT（直连=把真实 IP 交给 STUN）。
  // 规则依据：https://wiki.metacubex.one/en/config/rules/ DST-PORT 不限 NETWORK → TCP+UDP；OR 组合端口。
  if(!stash&&p.rules.some(r=>r.t==='stun')){const st=p.rules.find(r=>r.t==='stun') as any;pg.push({name:N.webrtc,type:'select',proxies:st.p==='REJECT'?['REJECT',N.proxy]:[N.proxy,'REJECT']})}
  // rule providers
  const rp:Record<string,any>={};const rules:string[]=[];
  const rpush=(kind:'site'|'ip',name:string,aliasHint?:string)=>{
    const k=(kind==='site'?'gs_':'gi_')+key(name);
    if(!rp[k])rp[k]={type:'http',behavior:kind==='site'?'domain':'ipcidr',format:'mrs',interval:low?259200:86400,proxy:N.update,url:kind==='site'?MC.site(name):MC.ip(name)};
    return k;
  };
  const adsLite=o.ads==='lite';
  const tgt=(pol:string)=>pol==='DIRECT'?'DIRECT':pol==='REJECT'?'REJECT':null;
  const targetName=(pol:string)=>{const t=tgt(pol);return t||pn(pol)};
  const svcTarget=(r:any)=>{ // 服务规则指向对应服务组；直连/拦截直指
    const pol=r.p;if(pol==='REJECT')return'REJECT';
    const g=p.services.find(x=>x.g.id===r.g.id);
    if(g)return g.g.name;
    return targetName(pol);
  };
  for(const r of p.rules){
    switch(r.t){
      case'comment':rules.push('#'+r.v);break;
      case'suffix':rules.push(`DOMAIN-SUFFIX,${r.v},${r.via&&r.p!=='REJECT'?p.services.find(x=>x.g.id===r.via)?.g.name||targetName(r.p):targetName(r.p)}`);break;
      case'ipcidr':rules.push(`IP-CIDR,${r.v},${targetName(r.p)},no-resolve`);break;
      case'process':rules.push(`PROCESS-NAME,${r.v},${targetName(r.p)}`);break;
      // Mihomo 没有独立的包名规则类型：Android 上应用默认进程名即包名，所以
      // package 与 process 在 Mihomo 里都写 PROCESS-NAME。plan.ts 已按平台
      // 分流（package 只在 android 下产生，process 只在桌面端产生），这里
      // 不做二次区分；sing-box 才有独立的 package_name 字段。
      case'package':rules.push(`PROCESS-NAME,${r.v},${targetName(r.p)}`);break;
      case'rset':{const f=setFmt(r.url);const k='cs_'+r.id.replace(/[^A-Za-z0-9]/g,'');rp[k]={type:'http',behavior:r.kind==='ip'?'ipcidr':r.kind,format:f==='mrs'?'mrs':f==='yaml'?'yaml':'text',interval:86400,...(stash?{}:{proxy:N.update}),url:r.url};
        rules.push(`RULE-SET,${k},${targetName(r.p)}${r.kind==='domain'?'':',no-resolve'}`);break}
      case'quic':if(stash){rules.push('AND,((NETWORK,UDP),(DST-PORT,443),(NOT,((GEOIP,CN)))),REJECT');break}rules.push(`AND,((NETWORK,UDP),(DST-PORT,443),(NOT,((OR,((RULE-SET,gs_cn),(RULE-SET,gi_cn,no-resolve)))))),REJECT`);rpush('site','cn');rpush('ip','cn');break;
      case'stun':if(stash){rules.push(`PROTOCOL,STUN,${targetName(r.p)}`);break}rules.push(`OR,((DST-PORT,3478-3479),(DST-PORT,5349),(DST-PORT,19302-19309)),${N.webrtc}`);break;
      case'wifi':if(stash){for(const d of r.domains)rules.push(`DOMAIN-SUFFIX,${d},${targetName(r.p)}`);break}rules.push(`AND,((NETWORK,UDP),(OR,((DST-PORT,500),(DST-PORT,4500))),(OR,(${r.domains.map(d=>`(DOMAIN-SUFFIX,${d})`).join(',')}))),${targetName(r.p)}`);for(const d of r.domains)rules.push(`DOMAIN-SUFFIX,${d},${targetName(r.p)}`);break;
      case'final':rules.push(`MATCH,${r.p==='PROXY'?N.final:'DIRECT'}`);break;
      case'site':{
        if(stash){let bm=r.g.bm7;if(r.g.id==='ads')bm=o.ads==='full'?'Advertising':'AdvertisingLite';if(r.name==='private')bm='Lan';if(!bm||rp['b_'+bm])break;const k='b_'+bm;rp[k]={type:'http',behavior:'classical',format:'yaml',interval:86400,url:BM7('Clash',bm,'yaml')};rules.push(`RULE-SET,${k},${r.g.id==='cn'||r.g.id==='private'||r.g.category==='direct'?targetName(r.p):svcTarget(r)}`);break}
        if(r.g.id==='ads'&&adsLite){const k='gs_ads_lite';if(!rp[k])rp[k]={type:'http',behavior:'classical',format:'yaml',interval:low?259200:86400,proxy:N.update,url:BM7('Clash','AdvertisingLite','yaml')};rules.push(`RULE-SET,${k},REJECT`);break}
        const k=rpush('site',r.name);rules.push(`RULE-SET,${k},${r.g.id==='cn'||r.g.id==='private'||r.g.category==='direct'?targetName(r.p):svcTarget(r)}`);break}
      case'ip':{if(stash)break;const k=rpush('ip',r.name);rules.push(`RULE-SET,${k},${r.g.id==='cn'||r.g.id==='private'?targetName(r.p):svcTarget(r)},no-resolve`);break}
    }
  }
  // fake-ip-filter 用到的集合名：cn_domain/private_domain 映射到 gs_cn / gs_private
  let cfg=top;
  const out:Record<string,any>={...cfg};
  if(proxies.length)out.proxies=proxies;
  if(Object.keys(providers).length||!p.appMode)out['proxy-providers']=providers;
  if(!stash){out.tun=tun;out.sniffer=sniffer}out.dns=dns;
  if(!stash&&(o.homeDomain&&o.lanGateway))out.hosts={[o.homeDomain]:o.lanGateway};
  if(!stash&&s.platform==='android')out.hosts={...(out.hosts||{}),'services.googleapis.cn':'services.googleapis.com'};
  if(iconsOn(p)){const im=iconMap(p);for(const g of pg){const u=im[g.name];if(u)g.icon=u}}
  out['proxy-groups']=pg;
  let text=hdr+block(out).replace(/\n$/,'\n');
  // 规则集与规则（rules 里用 # 注释行，需手写）
  let rpTxt='rule-providers:\n';for(const [k,v] of Object.entries(rp))rpTxt+=`  ${k}: ${flow(v)}\n`;
  text+=rpTxt+'rules:\n'+rules.map(r=>r.startsWith('#')?`  ${r}`:`  - ${r.includes(',')?JSON.stringify(r):r}`).join('\n')+'\n';
  // 在 Mihomo 中 fake-ip-filter / nameserver-policy 引用的 rule-set 名要与 provider 一致
  if(stash)return text;
  text=text.replace(/rule-set:cn_domain/g,'rule-set:gs_cn').replace(/rule-set:private_domain/g,'rule-set:gs_private');
  if(!rp['gs_cn']&&!stash)text=text.replace('rule-providers:\n','rule-providers:\n  gs_cn: '+flow({type:'http',behavior:'domain',format:'mrs',interval:86400,proxy:N.update,url:MC.site('cn')})+'\n');
  if(!rp['gs_private']&&!stash)text=text.replace('rule-providers:\n','rule-providers:\n  gs_private: '+flow({type:'http',behavior:'domain',format:'mrs',interval:86400,proxy:N.update,url:MC.site('private')})+'\n');
  return text;
}
function stripFlags(r:string){return r.replace(/^\(\?i\)/,'')}
export function safeRe(r:string){try{return new RegExp(r.replace(/^\(\?i\)/,''),'i')}catch{return /$^/}}
