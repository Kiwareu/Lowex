import raw from './groups.json';
import regionsRaw from './regions.json';

export interface RuleGroup{
  id:string;name:string;category:string;cat:string;
  geosite:string[];geoip:string[];bm7?:string;domains?:string[];
  def:string;           // 默认出口 PROXY / DIRECT / REJECT / R:xx
  defOn:boolean;risk:string;notes:string;custom?:boolean;
}
export const CATS:Record<string,string>={ai:'AI',streaming:'流媒体','cn-streaming':'国内视频',social:'社交',game:'游戏',dev:'开发',general:'通用',office:'办公',shopping:'购物',finance:'银行 / 支付',crypto:'加密货币',download:'下载',tools:'工具',reject:'拦截',direct:'直连',proxy:'兜底'};
const NAMES:Record<string,string>={signal:'Signal',jetbrains:'JetBrains',stackexchange:'Stack Overflow',zoom:'Zoom',wise:'Wise',pt:'PT / BT 下载（直连）',npm:'npm / JS 生态'};
const ON=new Set(['ai','youtube','netflix','disney','spotify','telegram','twitter','meta','discord','github','google','microsoft','apple','paypal','crypto','bilibili','games-cn','pt','ads','telemetry','cn','private','proxy-fallback','bank-overseas','steam']);
const PROXYISH=new Set(['ai']);
function defExit(id:string,d:string):string{
  if(d==='reject')return'REJECT';
  if(d.startsWith('direct')&&!d.includes('或'))return'DIRECT';
  if(['apple','microsoft','onedrive','xbox','steam','zoom'].includes(id))return'DIRECT';
  if(id==='ai')return'R:US';
  return'PROXY';
}
const catMap:Record<string,string>={ai:'ai',streaming:'streaming','cn-streaming':'cn-streaming',social:'social',game:'game',dev:'dev',general:'general',office:'office',shopping:'shopping',finance:'finance',crypto:'crypto',download:'download',tools:'tools',reject:'reject',direct:'direct',proxy:'proxy'};
/** v2 精简：移除过于小众的分组（用户反馈规则太多占空间）。Wise 已含在「海外银行/券商」域名里。 */
export const REMOVED:Record<string,string>={hbo:'HBO / Max',line:'LINE',ea:'EA / Origin',ubisoft:'Ubisoft',shopee:'Shopee',stripe:'Stripe',wise:'Wise',jetbrains:'JetBrains',stackexchange:'Stack Overflow',speedtest:'Speedtest'};
const base:RuleGroup[]=(raw as any).groups.filter((g:any)=>!REMOVED[g.id]).map((g:any)=>({
  id:g.id,name:g.name_zh&&g.name_zh!=='None'?g.name_zh:(NAMES[g.id]||g.id),category:g.category,cat:catMap[g.category]||g.category,
  geosite:g.geosite.map((s:any)=>s.name),geoip:g.geoip.map((s:any)=>s.name),bm7:g.bm7?.exists?g.bm7.name:undefined,
  def:defExit(g.id,g.default_exit),defOn:ON.has(g.id)||false,risk:g.misblock_risk,notes:g.notes,
}));
// 手写域名组（知识库里没有现成规则集；域名为公开的官网主域名，未做逐条校验）
const extra:RuleGroup[]=[
 {id:'bank-overseas',name:'海外银行 / 券商',category:'finance',cat:'finance',geosite:[],geoip:[],custom:true,def:'PROXY',defOn:true,risk:'高',
  notes:'手写域名：HSBC、渣打、花旗、Chase、BoA、Wells Fargo、Revolut、N26、Monzo、嘉信、富达、盈透、Wise 等。银行风控敏感，建议固定一个节点（把出口选成「某地区-手动」）并不要用自动测速组。',
  domains:['hsbc.com','hsbc.com.hk','hsbc.co.uk','hangseng.com','sc.com','standardchartered.com','citi.com','citibank.com','chase.com','bankofamerica.com','wellsfargo.com','capitalone.com','americanexpress.com','barclays.co.uk','lloydsbank.com','natwest.com','schwab.com','fidelity.com','interactivebrokers.com','ibkr.com','vanguard.com','robinhood.com','tdameritrade.com','futuhk.com','futunn.com','tigerbrokers.com','zabank.hk','mox.com','bochk.com','bochk.com.hk','dbs.com','dbs.com.sg','ocbc.com','uob.com.sg','hsbc.com.sg','hsbc.com.au','hsbc.ca','hsbcnet.com','scotiabank.com','rbc.com','td.com','bmo.com','cibc.com','anz.com','commbank.com.au','westpac.com.au','nab.com.au','mizuho-fg.co.jp','smbc.co.jp','mufg.jp','sbisec.co.jp','rakuten-sec.co.jp','shinhan.com','kbstar.com','hanabank.com','citibank.com.hk','bochk.com','cmbwinglungbank.com','bankcomm.com.hk','boci.com.hk','ccb.com.hk','icbcasia.com','sc.com.hk','hangseng.com.hk','bea.com.hk','livi.hk','welab.co','airstar.com']},
 {id:'crypto-more',name:'加密货币（更多交易所 / 钱包）',category:'crypto',cat:'crypto',geosite:[],geoip:[],custom:true,def:'PROXY',defOn:false,risk:'高',
  notes:'手写域名：Coinbase、Bitget、Gate、KuCoin、HTX、MetaMask、Trust Wallet、Uniswap、TradingView、CoinGecko、CoinMarketCap、Etherscan 等。与「加密货币平台」组互补。',
  domains:['coinbase.com','bitget.com','gate.io','gate.com','kucoin.com','htx.com','huobi.com','mexc.com','mexc.fm','mexc.link','mexc.me','mexcservices.com','mexcstatic.com','bitfinex.com','bitstamp.net','gemini.com','crypto.com','metamask.io','trustwallet.com','phantom.app','uniswap.org','pancakeswap.finance','1inch.io','opensea.io','etherscan.io','bscscan.com','solscan.io','tradingview.com','coingecko.com','coinmarketcap.com','dexscreener.com','debank.com','ledger.com','trezor.io','binance.us','okx.com','bybit.com','kraken.com','bitmex.com','deribit.com','bingx.com','phemex.com','lbank.com','bitrue.com','upbit.com','bithumb.com','coincheck.com','bitflyer.com','bitvavo.com','bitpanda.com','blockchain.com','exodus.com','safepal.com','tokenpocket.pro','rabby.io','walletconnect.com','walletconnect.org','alchemy.com','infura.io','chainlink.com','lido.fi','aave.com','curve.fi','compound.finance','binance.th','tether.to','circle.com','dune.com','defillama.com','coinglass.com','tokenterminal.com','cryptoquant.com','glassnode.com','arkhamintelligence.com','layerzero.network','jup.ag','raydium.io','magiceden.io','blur.io','ens.domains','safe.global','zerion.io','zapper.xyz']},
 {id:'ai-more',name:'AI（更多：Claude / Gemini / Grok 等）',category:'ai',cat:'ai',geosite:[],geoip:[],custom:true,def:'R:US',defOn:false,risk:'中',
  notes:'手写域名，补充 AI 服务组之外的站点：Claude、Gemini、Grok、Mistral、Poe、Midjourney、Stability、ElevenLabs 等。',
  domains:['claude.ai','claude.com','anthropic.com','gemini.google.com','aistudio.google.com','generativelanguage.googleapis.com','x.ai','grok.com','mistral.ai','poe.com','midjourney.com','stability.ai','elevenlabs.io','groq.com','together.ai','replicate.com','openrouter.ai','deepmind.google','notebooklm.google','perplexity.ai','cohere.com','suno.com','runwayml.com','civitai.com']},
 {id:'p2p-private',name:'私有 Tracker / 下载站（直连）',category:'download',cat:'download',geosite:[],geoip:[],custom:true,def:'DIRECT',defOn:false,risk:'低',notes:'空组：用于把你自己的下载站域名固定直连；在「自定义域名」里添加即可。',domains:[]},
];
import {EXTRA_GROUPS} from './groups-extra';
const moreGroups:RuleGroup[]=EXTRA_GROUPS.map(g=>({id:g.id,name:g.name,category:g.category,cat:g.cat,geosite:[],geoip:[],custom:true,def:g.def,defOn:g.defOn,risk:g.risk,notes:g.notes,domains:g.domains}));
export const GROUPS:RuleGroup[]=[...base.filter(g=>!['ads','telemetry','cn','private','proxy-fallback'].includes(g.id)),...extra.filter(g=>g.domains?.length),...moreGroups.filter(g=>!extra.some(e=>e.id===g.id)),...base.filter(g=>['ads','telemetry'].includes(g.id))];
for(const g of GROUPS)if(g.domains)g.domains=[...new Set(g.domains)];
export const CORE:Record<string,RuleGroup>=Object.fromEntries(base.filter(g=>['cn','private','proxy-fallback'].includes(g.id)).map(g=>[g.id,g]));
export const DIRECT_EXC:{id:string;geosite:string;note:string}[]=(raw as any).direct_exceptions;
export interface Region{id:string;name:string;regex:string}
export const REGIONS:Region[]=(regionsRaw as any).regions.map((r:any)=>({id:r.id,name:r.name_zh,regex:r.regex}));
export const GROUP_BY_ID:Record<string,RuleGroup>=Object.fromEntries([...GROUPS,...Object.values(CORE)].map(g=>[g.id,g]));
