// 内置 App 数据库（离线可搜）。字段：n 中文名｜en 英文名｜pkg 安卓包名｜exe Windows 进程名｜bid iOS Bundle ID｜dom 域名后缀（iOS 无法按 App 分流时用它写域名规则）｜g 对应服务组
// 来自公开信息整理，应用更新后可能变化，未逐个在真机核实；搜不到的 App 可用「在线搜索」或「自定义域名」。
export interface AppEntry{n:string;en?:string;pkg?:string;exe?:string;bid?:string;dom?:string[];g?:string;cn?:boolean}
const L=(s:string):AppEntry[]=>s.trim().split('\n').map(l=>{const [n,en,pkg,exe,bid,dom,g,cn]=l.split('|');return{n,en:en||undefined,pkg:pkg||undefined,exe:exe||undefined,bid:bid||undefined,dom:dom?dom.trim().split(','):undefined,g:g||undefined,cn:cn==='1'||undefined}});
import {APPDB_MORE} from './appdb-more';
const BASE:AppEntry[]=L(`
微信|WeChat|com.tencent.mm|WeChat.exe|com.tencent.xin|weixin.qq.com,wechat.com,wx.qq.com||1
QQ|QQ|com.tencent.mobileqq|QQ.exe|com.tencent.mqq|qq.com||1
支付宝|Alipay|com.eg.android.AlipayGphone|Alipay.exe|com.alipay.iphoneclient|alipay.com,alipayobjects.com||1
淘宝|Taobao|com.taobao.taobao|Taobao.exe|com.taobao.taobao4iphone|taobao.com,tmall.com||1
京东|JD|com.jingdong.app.mall|||jd.com||1
拼多多|Pinduoduo|com.xunmeng.pinduoduo|||pinduoduo.com,yangkeduo.com||1
抖音|Douyin|com.ss.android.ugc.aweme||com.ss.iphone.ugc.Aweme|douyin.com,douyinpic.com||1
今日头条|Toutiao|com.ss.android.article.news|||toutiao.com||1
哔哩哔哩|Bilibili|tv.danmaku.bili|bilibili.exe|tv.danmaku.bilianime|bilibili.com,hdslb.com,biliapi.net|bilibili|1
小红书|Xiaohongshu|com.xingin.xhs|||xiaohongshu.com,xhscdn.com||1
微博|Weibo|com.sina.weibo|||weibo.com,weibo.cn,sinaimg.cn||1
知乎|Zhihu|com.zhihu.android|||zhihu.com,zhimg.com||1
网易云音乐|NetEase Cloud Music|com.netease.cloudmusic|cloudmusic.exe|com.netease.cloudmusic|music.163.com,126.net||1
QQ音乐|QQ Music|com.tencent.qqmusic|QQMusic.exe|com.tencent.QQMusic|y.qq.com||1
酷狗音乐|Kugou|com.kugou.android|KuGou.exe||kugou.com||1
百度网盘|Baidu Netdisk|com.baidu.netdisk|BaiduNetdisk.exe|com.baidu.netdisk|baidu.com,pan.baidu.com||1
百度|Baidu|com.baidu.searchbox|||baidu.com,bdstatic.com||1
高德地图|Amap|com.autonavi.minimap|||amap.com,autonavi.com||1
百度地图|Baidu Map|com.baidu.BaiduMap|||map.baidu.com||1
滴滴出行|DiDi|com.sdu.didi.psnger|||xiaojukeji.com,didiglobal.com||1
美团|Meituan|com.sankuai.meituan|||meituan.com,meituan.net||1
饿了么|Ele.me|me.ele|||ele.me||1
钉钉|DingTalk|com.alibaba.android.rimet|DingTalk.exe|com.laiwang.DingTalk|dingtalk.com||1
企业微信|WeCom|com.tencent.wework|WXWork.exe|com.tencent.wework|work.weixin.qq.com||1
飞书|Feishu / Lark|com.ss.android.lark|Feishu.exe|com.bytedance.lark|feishu.cn,larksuite.com||1
腾讯会议|Tencent Meeting|com.tencent.wemeet.app|wemeetapp.exe|com.tencent.wemeet|meeting.tencent.com||1
WPS Office|WPS|cn.wps.moffice_eng|wps.exe|com.kingsoft.www.office.wpsoffice|wps.cn,wps.com||1
夸克|Quark|com.quark.browser|||quark.cn||1
UC浏览器|UC Browser|com.UCMobile|UCBrowser.exe||uc.cn||1
Steam|Steam|com.valvesoftware.android.steam.community|steam.exe|com.valvesoftware.Steam|steampowered.com,steamcommunity.com,steamstatic.com|steam|
Steam 客户端 WebHelper|Steam Web Helper||steamwebhelper.exe||steampowered.com|steam|
Epic Games|Epic Games Launcher||EpicGamesLauncher.exe|com.epicgames.Portal|epicgames.com|epic|
Battle.net|Battle.net||Battle.net.exe||battle.net,blizzard.com|blizzard|
原神|Genshin Impact|com.miHoYo.GenshinImpact|YuanShen.exe,GenshinImpact.exe|com.miHoYo.GenshinImpact|hoyoverse.com,mihoyo.com||
崩坏：星穹铁道|Honkai: Star Rail|com.HoYoverse.hkrpgoversea|StarRail.exe||hoyoverse.com||
英雄联盟|League of Legends||LeagueClient.exe||riotgames.com,leagueoflegends.com||
Valorant|Valorant||VALORANT.exe||riotgames.com||
Minecraft|Minecraft|com.mojang.minecraftpe|Minecraft.Windows.exe,javaw.exe|com.mojang.minecraftpe|minecraft.net,mojang.com||
Discord|Discord|com.discord|Discord.exe|com.hammerandchisel.discord|discord.com,discord.gg,discordapp.com|discord|
Telegram|Telegram|org.telegram.messenger|Telegram.exe|ph.telegra.Telegraph|telegram.org,t.me,telegra.ph|telegram|
Telegram X|Telegram X|org.thunderdog.challegram|||telegram.org|telegram|
Signal|Signal|org.thoughtcrime.securesms|Signal.exe|org.whispersystems.signal|signal.org||
WhatsApp|WhatsApp|com.whatsapp|WhatsApp.exe|net.whatsapp.WhatsApp|whatsapp.com,whatsapp.net,wa.me|meta|
Messenger|Messenger|com.facebook.orca||com.facebook.Messenger|messenger.com,facebook.com|meta|
Facebook|Facebook|com.facebook.katana||com.facebook.Facebook|facebook.com,fbcdn.net|meta|
Instagram|Instagram|com.instagram.android||com.burbn.instagram|instagram.com,cdninstagram.com|meta|
Threads|Threads|com.instagram.barcelona||com.burbn.barcelona|threads.net|meta|
X / Twitter|X|com.twitter.android||com.atebits.Tweetie2|x.com,twitter.com,twimg.com|twitter|
Reddit|Reddit|com.reddit.frontpage||com.reddit.Reddit|reddit.com,redd.it,redditmedia.com||
LINE|LINE|jp.naver.line.android|LINE.exe|jp.naver.line|line.me,line-apps.com,line-scdn.net||
KakaoTalk|KakaoTalk|com.kakao.talk|KakaoTalk.exe|com.iwilab.KakaoTalk|kakao.com,kakaocdn.net||
Snapchat|Snapchat|com.snapchat.android||com.toyopagroup.picaboo|snapchat.com,sc-cdn.net||
Pinterest|Pinterest|com.pinterest||pinterest|pinterest.com,pinimg.com||
LinkedIn|LinkedIn|com.linkedin.android||com.linkedin.LinkedIn|linkedin.com,licdn.com||
YouTube|YouTube|com.google.android.youtube||com.google.ios.youtube|youtube.com,googlevideo.com,ytimg.com|youtube|
YouTube Music|YouTube Music|com.google.android.apps.youtube.music||com.google.ios.youtubemusic|music.youtube.com|youtube|
Netflix|Netflix|com.netflix.mediaclient||com.netflix.Netflix|netflix.com,nflxvideo.net,nflximg.net|netflix|
Disney+|Disney Plus|com.disney.disneyplus||com.disney.disneyplus|disneyplus.com,bamgrid.com,disney-plus.net|disney|
Prime Video|Prime Video|com.amazon.avod.thirdpartyclient||com.amazon.aiv.AIVApp|primevideo.com,amazonvideo.com|primevideo|
Max / HBO Max|Max|com.wbd.stream||com.wbd.stream|max.com,hbomax.com||
Hulu|Hulu|com.hulu.plus||com.hulu.plus|hulu.com,hulustream.com||
Twitch|Twitch|tv.twitch.android.app|Twitch.exe|tv.twitch|twitch.tv,ttvnw.net,jtvnw.net||
TikTok|TikTok|com.zhiliaoapp.musically|TikTok.exe|com.zhiliaoapp.musically|tiktok.com,tiktokcdn.com,byteoversea.com|tiktok|
Spotify|Spotify|com.spotify.music|Spotify.exe|com.spotify.client|spotify.com,scdn.co,spotifycdn.com|spotify|
Apple Music|Apple Music|com.apple.android.music|AppleMusic.exe|com.apple.Music|music.apple.com,apple.com|apple|
SoundCloud|SoundCloud|com.soundcloud.android||com.soundcloud.TouchApp|soundcloud.com,sndcdn.com||
ChatGPT|ChatGPT|com.openai.chatgpt|ChatGPT.exe|com.openai.chat|openai.com,chatgpt.com,oaistatic.com,oaiusercontent.com|ai|
Claude|Claude|com.anthropic.claude|Claude.exe|com.anthropic.claude|claude.ai,anthropic.com|ai|
Gemini|Google Gemini|com.google.android.apps.bard||com.google.gemini|gemini.google.com,generativelanguage.googleapis.com|ai|
Grok|Grok|ai.x.grok||ai.x.grok|grok.com,x.ai|ai|
Perplexity|Perplexity|ai.perplexity.app.android||ai.perplexity.app|perplexity.ai|ai|
Copilot|Microsoft Copilot|com.microsoft.copilot||com.microsoft.copilot|copilot.microsoft.com|ai|
Cursor|Cursor||Cursor.exe||cursor.com,cursor.sh|ai|
DeepSeek|DeepSeek|com.deepseek.chat||com.deepseek.chat|deepseek.com|ai-cn|
Google Chrome|Chrome|com.android.chrome|chrome.exe|com.google.chrome.ios|google.com,gstatic.com|google|
Microsoft Edge|Edge|com.microsoft.emmx|msedge.exe|com.microsoft.msedge|microsoft.com,bing.com|microsoft|
Firefox|Firefox|org.mozilla.firefox|firefox.exe|org.mozilla.ios.Firefox|mozilla.org,mozilla.com||
Brave|Brave|com.brave.browser|brave.exe|com.brave.ios.browser|brave.com||
Opera|Opera|com.opera.browser|opera.exe||opera.com||
Safari|Safari|||com.apple.mobilesafari||apple|
Google 地图|Google Maps|com.google.android.apps.maps||com.google.Maps|google.com,gstatic.com|google|
Gmail|Gmail|com.google.android.gm||com.google.Gmail|gmail.com,google.com|google|
Google Drive|Google Drive|com.google.android.apps.docs|GoogleDriveFS.exe|com.google.Drive|drive.google.com,googleusercontent.com|google|
Google Photos|Google Photos|com.google.android.apps.photos||com.google.photos|photos.google.com|google|
Google Play 商店|Google Play|com.android.vending||| play.google.com,googleapis.com|google|
Google Play 服务|Google Play Services|com.google.android.gms|||googleapis.com,gstatic.com|google|
Google Translate|Google Translate|com.google.android.apps.translate||com.google.Translate|translate.google.com|google|
Microsoft Teams|Teams|com.microsoft.teams|ms-teams.exe,Teams.exe|com.microsoft.skype.teams|teams.microsoft.com,microsoft.com|microsoft|
Outlook|Outlook|com.microsoft.office.outlook|OUTLOOK.EXE|com.microsoft.Office.Outlook|outlook.com,office365.com,live.com|microsoft|
OneDrive|OneDrive|com.microsoft.skydrive|OneDrive.exe|com.microsoft.skydrive|onedrive.com,sharepoint.com|onedrive|
Skype|Skype|com.skype.raider|Skype.exe|com.skype.skype|skype.com|microsoft|
Zoom|Zoom|us.zoom.videomeetings|Zoom.exe|us.zoom.videomeetings|zoom.us,zoom.com|zoom|
Slack|Slack|com.Slack|slack.exe|com.tinyspeck.chatlyio|slack.com,slack-edge.com||
Notion|Notion|notion.id|Notion.exe|notion.id|notion.so,notion.site||
Dropbox|Dropbox|com.dropbox.android|Dropbox.exe|com.getdropbox.Dropbox|dropbox.com,dropboxstatic.com||
Evernote|Evernote|com.evernote||com.evernote.iPhone.Evernote|evernote.com||
GitHub|GitHub|com.github.android|GitHubDesktop.exe|com.github.stormbreaker.prod|github.com,githubusercontent.com,githubassets.com|github|
Git（命令行）|Git||git.exe,git-remote-https.exe||github.com|github|
Docker Desktop|Docker||Docker Desktop.exe,com.docker.backend.exe||docker.com,docker.io|docker|
VS Code|Visual Studio Code||Code.exe||visualstudio.com,vscode-cdn.net|microsoft|
Node.js / npm|npm||node.exe||npmjs.org,npmjs.com||
Python / pip|pip||python.exe,pip.exe||pypi.org,pythonhosted.org||
Termux|Termux|com.termux|||||
Steam Link|Steam Link|com.valvesoftware.steamlink|||steampowered.com|steam|
qBittorrent|qBittorrent|org.qbittorrent.client|qbittorrent.exe|||||
uTorrent|uTorrent|com.utorrent.client|uTorrent.exe||||
Telegram Desktop|Telegram Desktop||Telegram.exe||telegram.org|telegram|
Binance|Binance|com.binance.dev||com.czzhao.binance|binance.com,bnbstatic.com|crypto|
OKX|OKX|com.okinc.okex.gp||com.okex.OKExAppstoreRelease|okx.com,okx.org|crypto|
Bybit|Bybit|com.bybit.app||com.bybit.app|bybit.com,bytick.com|crypto|
Coinbase|Coinbase|com.coinbase.android||com.vilcsak.bitcoin2|coinbase.com||
Kraken|Kraken|com.kraken.invest.app||com.kraken.invest.app|kraken.com||
MetaMask|MetaMask|io.metamask||io.metamask.MetaMask|metamask.io||
Trust Wallet|Trust Wallet|com.wallet.crypto.trustapp||com.sixdigitsapps.trust|trustwallet.com||
PayPal|PayPal|com.paypal.android.p2pmobile||com.yourcompany.PPClient|paypal.com,paypalobjects.com|paypal|
Wise|Wise|com.transferwise.android||com.transferwise.Transferwise|wise.com||
Revolut|Revolut|com.revolut.revolut||com.revolut.revolut|revolut.com||
Stripe Dashboard|Stripe|com.stripe.android.dashboard||com.stripe.dashboard|stripe.com||
Uber|Uber|com.ubercab||com.ubercab.UberClient|uber.com||
Airbnb|Airbnb|com.airbnb.android||com.airbnb.app|airbnb.com||
Booking.com|Booking|com.booking||com.booking.BookingApp|booking.com||
Grab|Grab|com.grabtaxi.passenger||com.grab.taxi|grab.com||
Amazon 购物|Amazon Shopping|com.amazon.mShop.android.shopping||com.amazon.Amazon|amazon.com,media-amazon.com||
eBay|eBay|com.ebay.mobile||com.ebay.iphone|ebay.com||
AliExpress|AliExpress|com.alibaba.aliexpresshd||com.alibaba.AliExpress|aliexpress.com||
Shein|SHEIN|com.zzkko||com.zzkko.Shein|shein.com||
Temu|Temu|com.einnovation.temu||com.einnovation.temu|temu.com||
Shopee|Shopee|com.shopee.sg||com.beeasy.shopee.sg|shopee.com||
Lazada|Lazada|com.lazada.android||com.lazada.Lazada|lazada.com||
Wikipedia|Wikipedia|org.wikipedia||org.wikimedia.wikipedia|wikipedia.org,wikimedia.org||
Medium|Medium|com.medium.reader||com.medium.reader|medium.com||
Quora|Quora|com.quora.android||com.quora.quora|quora.com||
Adobe Creative Cloud|Adobe CC||Creative Cloud.exe||adobe.com,adobe.io||
Figma|Figma||Figma.exe|com.figma.FigmaMirror|figma.com||
Canva|Canva|com.canva.editor||com.canva.canvaeditor|canva.com||
VPN 订阅更新（Clash Verge）|Clash Verge||clash-verge.exe,verge-mihomo.exe|||||
FaceTime / iMessage|FaceTime|||com.apple.facetime|apple.com,icloud.com|apple|
iCloud|iCloud||||icloud.com,icloud-content.com|apple|
App Store|App Store|||com.apple.AppStore|apps.apple.com,itunes.apple.com,mzstatic.com|apple|
Apple TV|Apple TV|||com.apple.tv|tv.apple.com,apple.com|apple|
`);
// 增补条目覆盖同名旧条目（如 Wise / Revolut 补上服务组）
export const APPDB:AppEntry[]=(()=>{const m=L(APPDB_MORE);const names=new Set(m.map(a=>a.n.toLowerCase()));return[...BASE.filter(a=>!names.has(a.n.toLowerCase())),...m]})();
export function searchApps(q:string,limit=30):AppEntry[]{
  const t=q.trim().toLowerCase();if(!t)return[];
  const sc=(a:AppEntry)=>{const f=[a.n,a.en,a.pkg,a.exe,a.bid,...(a.dom||[])].filter(Boolean).map(x=>x!.toLowerCase());
    let best=0;for(const x of f){if(x===t)best=Math.max(best,100);else if(x.startsWith(t))best=Math.max(best,80);else if(x.includes(t))best=Math.max(best,50)}return best};
  return APPDB.map(a=>({a,s:sc(a)})).filter(x=>x.s>0).sort((x,y)=>y.s-x.s).slice(0,limit).map(x=>x.a);
}
export interface ItunesApp{name:string;bid:string;seller:string;icon:string;url:string}
/** 在线：iTunes Search API（官方、允许跨域）。拿到的是 iOS 的名称和 Bundle ID，不含域名。 */
export async function itunesSearch(q:string,country='us',signal?:AbortSignal):Promise<ItunesApp[]>{
  const r=await fetch(`https://itunes.apple.com/search?term=${encodeURIComponent(q)}&entity=software&country=${country}&limit=20`,{signal});
  const j=await r.json();return (j.results||[]).map((x:any)=>({name:x.trackName,bid:x.bundleId,seller:x.sellerName,icon:x.artworkUrl60,url:x.trackViewUrl}));
}
