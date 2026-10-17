// 图标审计（v1.4，2026-10-17）：逐个下载并目视核对了每个服务组的图标。
// ok = 品牌/类别正确；generic = 用了通用类别图标代替具体品牌（保留，列入待补）；
// wrong = 图标是别的品牌 / 与组无关；single = 单一品牌图标代表多品牌组；broken = 链接 404。
// wrong / single / broken 一律改用中性占位图，不再显示错误品牌。
export type IconStatus='ok'|'generic'|'wrong'|'single'|'broken';
export interface IconAudit{s:IconStatus;was?:string;want:string}
export const ICON_BASE='https://raw.githubusercontent.com/wenxu184/Lowex-Icons/main/icons';
export const ICON_PLACEHOLDER=ICON_BASE+'/_placeholder.png';
export const ICON_AUDIT:Record<string,IconAudit>={
  bunq:{s:'wrong',was:'Wise 图标',want:'bunq（荷兰银行）彩虹 b 标志'},
  sumup:{s:'wrong',was:'Wise 图标',want:'SumUp（英国支付）标志'},
  maya:{s:'wrong',was:'云闪付 / UnionPay 图标',want:'Maya（菲律宾银行 / 支付）标志'},
  fintech:{s:'wrong',was:'Wise 图标（组里有多个品牌）',want:'「金融科技 / 新银行」组通用图标（如 Wise / Revolut / N26 的拼合或中性图标）'},
  'nomad-work':{s:'wrong',was:'服务器图标（与远程工作无关）',want:'「远程工作 / 外包平台」组图标'},
  whatsapp:{s:'broken',was:'Qure/WhatsApp.png 返回 404',want:'WhatsApp 标志'},
  'cn-bank-direct':{s:'single',was:'银联 UnionPay 图标（只代表银联）',want:'「国内银行 / 支付 / 政务」组图标'},
  'social-more':{s:'single',was:'Bluesky 图标（只代表 Bluesky）',want:'「社交 / 去中心化」组图标'},
  privacy:{s:'single',was:'Proton Mail 图标（只代表 Proton）',want:'「隐私 / 密码 / 邮箱工具」组图标'},
  'shop-more':{s:'single',was:'Etsy 图标（只代表 Etsy）',want:'「购物（更多海外）」组图标'},
  'ai-more':{s:'single',was:'Gemini 星芒图标（组里还有 Claude / Grok 等）',want:'「AI（更多）」组图标'},
  blizzard:{s:'generic',was:'通用手柄图标',want:'暴雪战网 Battle.net 标志'},
  'bybit-eu':{s:'generic',was:'通用加密币图标',want:'Bybit 标志'},
  krak:{s:'generic',was:'通用加密币图标',want:'Kraken 标志'},
  mexc:{s:'generic',was:'通用加密币图标',want:'MEXC 标志'},
  'bitget-wallet':{s:'generic',was:'通用加密币图标',want:'Bitget Wallet 标志'},
  hsbc:{s:'generic',was:'通用银行图标（¥ 符号）',want:'汇丰 HSBC 六边形标志'},
  blackcat:{s:'generic',was:'通用银行图标（¥ 符号）',want:'Blackcat Card 标志'},
  'bank-overseas':{s:'generic',was:'通用银行图标（¥ 符号）',want:'「海外银行 / 券商」组通用银行图标（无货币符号）'},
  'bank-eu':{s:'generic',was:'通用银行图标（¥ 符号）',want:'「欧洲 / 国际银行与券商」组图标'},
  'bank-hk':{s:'generic',was:'通用银行图标（¥ 符号）',want:'「香港银行 / 虚拟银行」组图标'},
  'bank-sg':{s:'generic',was:'通用银行图标（¥ 符号）',want:'「新加坡银行」组图标'},
  'biz-banking':{s:'generic',was:'通用银行图标（¥ 符号）',want:'「跨境商业账户」组图标'},
  brokers:{s:'generic',was:'通用银行图标（¥ 符号）',want:'「券商」组图标'},
  'nomad-tools':{s:'generic',was:'通用订房图标',want:'「数字游民工具」组图标'},
  twitter:{s:'ok',was:'旧版小鸟 Twitter 标志（品牌已改 X）',want:'X 标志（可选更新）'},
  meta:{s:'ok',was:'Facebook 标志代表 Meta 组',want:'Meta 无限符号标志（可选更新）'},
  gitlab:{s:'ok',was:'google favicon 服务（低清）',want:'GitLab 高清标志（可选更新）'},
  npm:{s:'ok',was:'google favicon 服务（低清）',want:'npm 高清标志（可选更新）'},
};
/** 已上传到 Lowex-Icons 的组 id（运行时由 App 通过 GitHub API 列出仓库文件更新；这里是内置默认值） */
/** v1.5：这些组的图标已画好并上传到 Lowex-Icons（512×512 圆角方块），App 内置此列表，不依赖联网也直接引用仓库路径 */
export const NEW_ICONS:string[]=["ai-more", "bank-eu", "bank-hk", "bank-overseas", "bank-sg", "bitget-wallet", "biz-banking", "blackcat", "blizzard", "brokers", "bunq", "bybit-eu", "cn-bank-direct", "fintech", "hsbc", "krak", "maya", "meta", "mexc", "nomad-tools", "nomad-work", "privacy", "shop-more", "social-more", "sumup", "twitter", "whatsapp"];
let READY:string[]=[];
export const setIconsReady=(l:string[])=>{READY=Array.isArray(l)?l.filter(x=>typeof x==='string'):[]};
export const iconsReady=()=>READY;
/** key 形如 'g:bunq' / 'r:HK' / 's:proxy'。返回要用的图标 URL：Lowex-Icons 已上传 → 它；错图/断链/单品牌 → 占位图；否则沿用原图。 */
export function resolveIcon(key:string,orig:string|undefined):string|undefined{
  if(!key.startsWith('g:'))return orig;
  const id=key.slice(2);
  if(NEW_ICONS.includes(id)||READY.includes(id))return `${ICON_BASE}/${id}.png`;
  const a=ICON_AUDIT[id];
  if(a&&(a.s==='wrong'||a.s==='single'||a.s==='broken'))return ICON_PLACEHOLDER;
  return orig;
}
