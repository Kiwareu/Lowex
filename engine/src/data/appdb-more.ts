// 内置 App 数据库 · 增补（v3.3）：荷兰 / 欧洲银行、金融科技、加密货币、券商、出行、社交、影音、隐私工具、游戏、国内常见 App。
// 格式同 appdb.ts：中文名|英文名|安卓包名|Windows 进程|iOS Bundle ID|域名后缀(逗号)|服务组|国内(1)。
// 包名 / Bundle ID 来自公开商店信息，拿不准的留空（宁缺毋滥）；域名为官网主域名，未逐条真机核实。
export const APPDB_MORE=`
bunq|bunq|com.bunq.android|||bunq.com,bunq.app,bunq.me|fintech|
Wise|Wise|com.transferwise.android||com.transferwise.Transferwise|wise.com,transferwise.com|fintech|
Revolut|Revolut|com.revolut.revolut||com.revolut.revolut|revolut.com,revolut.me|fintech|
N26|N26|de.number26.android|||n26.com|fintech|
Monzo|Monzo|co.uk.getmondo|||monzo.com|fintech|
Starling Bank|Starling Bank|com.starlingbank.android|||starlingbank.com|fintech|
Trade Republic|Trade Republic|de.traderepublic.app|||traderepublic.com|fintech|
Klarna|Klarna|com.myklarnamobile|||klarna.com,klarna.net|fintech|
Payoneer|Payoneer|com.payoneer.android|||payoneer.com|fintech|
Venmo|Venmo|com.venmo|||venmo.com|fintech|
Cash App|Cash App|com.squareup.cash|||cash.app|fintech|
Chime|Chime|com.onedebit.chime|||chime.com|fintech|
Zelle|Zelle|com.zellepay.zelle|||zellepay.com|fintech|
Airwallex|Airwallex||||airwallex.com|fintech|
Remitly|Remitly|com.remitly.androidapp|||remitly.com|fintech|
WorldRemit|WorldRemit|com.worldremit.android|||worldremit.com|fintech|
Western Union|Western Union||||westernunion.com|fintech|
Skrill|Skrill|com.skrill.android|||skrill.com|fintech|
Bitvavo|Bitvavo|com.bitvavo.android|||bitvavo.com|fintech|
Bitpanda|Bitpanda||||bitpanda.com|fintech|
iDEAL / Tikkie|Tikkie||||ideal.nl,tikkie.me|fintech|
ING（荷兰）|ING NL|com.ing.mobile|||ing.nl,ing.com|bank-eu|
ING（德国）|ING Germany|de.ingdiba.bankingapp|||ing.de|bank-eu|
ABN AMRO|ABN AMRO||||abnamro.nl,abnamro.com|bank-eu|
Rabobank|Rabobank|nl.rabomobiel|||rabobank.nl,rabobank.com|bank-eu|
SNS / ASN / RegioBank|SNS Bank||||snsbank.nl,asnbank.nl|bank-eu|
Knab|Knab||||knab.nl|bank-eu|
DEGIRO|DEGIRO||||degiro.com,degiro.nl|bank-eu|
DKB|DKB|de.dkb.portalapp|||dkb.de|bank-eu|
Commerzbank|Commerzbank||||commerzbank.de|bank-eu|
Deutsche Bank|Deutsche Bank||||deutsche-bank.de,db.com|bank-eu|
Santander|Santander||||santander.com,santander.co.uk|bank-eu|
BBVA|BBVA||||bbva.com,bbva.es|bank-eu|
UBS|UBS||||ubs.com|bank-eu|
Scalable Capital|Scalable Capital||||scalable.capital|bank-eu|
Trading 212|Trading 212|com.we.trading212|||trading212.com|bank-eu|
eToro|eToro|com.etoro.openbook|||etoro.com|bank-eu|
Webull|Webull||||webull.com|bank-eu|
Moomoo|Moomoo||||moomoo.com|bank-eu|
富途牛牛|Futu NiuNiu|cn.futu.trader|||futunn.com,futuhk.com||
老虎证券|Tiger Brokers|com.tigerbrokers.stock|||tigerbrokers.com||
Interactive Brokers|IBKR|atws.app|||interactivebrokers.com,ibkr.com|bank-overseas|
Robinhood|Robinhood|com.robinhood.android|||robinhood.com|bank-overseas|
Charles Schwab|Schwab|com.schwab.mobile|||schwab.com|bank-overseas|
Fidelity|Fidelity|com.fidelity.android|||fidelity.com|bank-overseas|
Chase|Chase|com.chase.sig.android|||chase.com|bank-overseas|
Bank of America|Bank of America|com.infonow.bofa|||bankofamerica.com|bank-overseas|
Wells Fargo|Wells Fargo|com.wf.wellsfargomobile|||wellsfargo.com|bank-overseas|
Citi|Citi|com.citi.citimobile|||citi.com,citibank.com|bank-overseas|
American Express|Amex|com.americanexpress.android.acctsvcs.us|||americanexpress.com|bank-overseas|
HSBC（香港）|HSBC HK|hk.com.hsbc.hsbchkmobilebanking|||hsbc.com.hk|bank-overseas|
HSBC（英国）|HSBC UK|uk.co.hsbc.hsbcukmobilebanking|||hsbc.co.uk|bank-overseas|
汇丰 / 恒生 / 渣打 / 中银香港|HK banks||||hangseng.com,sc.com,bochk.com|bank-overseas|
DBS / POSB|DBS|com.dbs.sg.dbsmbanking|||dbs.com,dbs.com.sg|bank-overseas|
OCBC|OCBC||||ocbc.com|bank-overseas|
UOB|UOB||||uob.com.sg|bank-overseas|
Barclays|Barclays|com.barclays.android.barclaysmobilebanking|||barclays.co.uk|bank-overseas|
OKX（欧易）|OKX|com.okinc.okex.gp|||okx.com|crypto|
Bitget|Bitget|com.bitget.exchange|||bitget.com|crypto-more|
KuCoin|KuCoin|com.kubi.kucoin|||kucoin.com|crypto-more|
Gate.io|Gate|io.gate.gateio|||gate.io,gate.com|crypto-more|
HTX（火币）|HTX|pro.huobi|||htx.com,huobi.com|crypto-more|
MEXC|MEXC|com.mexcpro.client|||mexc.com|crypto-more|
Crypto.com|Crypto.com|co.mona.android|||crypto.com|crypto-more|
Kraken Pro|Kraken|com.kraken.invest.app|||kraken.com|crypto|
Bitfinex|Bitfinex||||bitfinex.com|crypto-more|
Gemini|Gemini Exchange||||gemini.com|crypto-more|
Upbit|Upbit|com.dunamu.exchange|||upbit.com|crypto-more|
Phantom|Phantom|app.phantom|||phantom.app|crypto-more|
Coinbase Wallet|Coinbase Wallet|org.toshi|||coinbase.com|crypto-more|
Ledger Live|Ledger Live|com.ledger.live|||ledger.com|crypto-more|
Exodus|Exodus|exodusmovement.exodus|||exodus.com|crypto-more|
Uniswap|Uniswap|com.uniswap.mobile|||uniswap.org|crypto-more|
TradingView|TradingView|com.tradingview.tradingviewapp|||tradingview.com|crypto-more|
CoinGecko|CoinGecko|com.coingecko.coingeckoapp|||coingecko.com|crypto-more|
CoinMarketCap|CoinMarketCap|com.coinmarketcap.android|||coinmarketcap.com|crypto-more|
DeBank|DeBank||||debank.com|crypto-more|
Mastodon|Mastodon|org.joinmastodon.android|||mastodon.social,joinmastodon.org|social-more|
Bluesky|Bluesky|xyz.blueskyweb.app|||bsky.app,bsky.social|social-more|
Tumblr|Tumblr|com.tumblr|||tumblr.com|social-more|
Pixiv|pixiv|jp.pxv.android|||pixiv.net,pximg.net|social-more|
Viber|Viber|com.viber.voip|||viber.com|social-more|
Zalo|Zalo|com.zing.zalo|||zalo.me|social-more|
Substack|Substack|com.substack.app|||substack.com|social-more|
Imgur|Imgur|com.imgur.mobile|||imgur.com|social-more|
Crunchyroll|Crunchyroll|com.crunchyroll.crunchyroid|||crunchyroll.com|media-more|
Paramount+|Paramount+||||paramountplus.com|media-more|
Peacock|Peacock||||peacocktv.com|media-more|
Vimeo|Vimeo|com.vimeo.android.videoapp|||vimeo.com,vimeocdn.com|media-more|
Audible|Audible|com.audible.application|||audible.com|media-more|
Kindle|Kindle|com.amazon.kindle|||kindle.com,amazon.com|media-more|
Tidal|TIDAL|com.aspiro.tidal|||tidal.com|media-more|
Deezer|Deezer|deezer.android.app|||deezer.com|media-more|
Plex|Plex|com.plexapp.android|Plex.exe||plex.tv,plex.direct|media-more|
Skyscanner|Skyscanner|net.skyscanner.android.main|||skyscanner.net,skyscanner.com|travel|
Agoda|Agoda|com.agoda.mobile.consumer|||agoda.com|travel|
Trip.com|Trip.com|ctrip.english|||trip.com|travel|
Expedia|Expedia|com.expedia.bookings|||expedia.com|travel|
Lyft|Lyft|me.lyft.android|||lyft.com|travel|
Bolt|Bolt|ee.mtakso.client|||bolt.eu|travel|
Uber Eats|Uber Eats|com.ubercab.eats|||ubereats.com,uber.com|travel|
DoorDash|DoorDash|com.dd.doordash|||doordash.com|travel|
Wolt|Wolt|com.wolt.android|||wolt.com|travel|
Deliveroo|Deliveroo|com.deliveroo.orderapp|||deliveroo.com|travel|
Flightradar24|Flightradar24|com.flightradar24free|||flightradar24.com|travel|
Proton Mail|Proton Mail|ch.protonmail.android|||proton.me,protonmail.com|privacy|
Proton Drive / Pass / Calendar|Proton||||proton.me|privacy|
Bitwarden|Bitwarden|com.x8bit.bitwarden|Bitwarden.exe||bitwarden.com,bitwarden.net|privacy|
1Password|1Password|com.onepassword.android|1Password.exe||1password.com|privacy|
DuckDuckGo|DuckDuckGo|com.duckduckgo.mobile.android|||duckduckgo.com,duck.com|privacy|
Obsidian|Obsidian|md.obsidian|Obsidian.exe||obsidian.md|privacy|
Tuta Mail|Tuta||||tuta.com,tutanota.com|privacy|
AWS Console|AWS Console|com.amazon.aws.console.mobile|||aws.amazon.com,amazonaws.com|cloud-dev|
Azure / Microsoft Cloud|Azure||||azure.com,azure.net|cloud-dev|
Vercel|Vercel||||vercel.com,vercel.app|cloud-dev|
Hugging Face|Hugging Face||||huggingface.co,hf.co|cloud-dev|
Postman|Postman||Postman.exe||postman.com|cloud-dev|
Stack Overflow|Stack Overflow|com.stackexchange.stackoverflow|||stackoverflow.com,sstatic.net|cloud-dev|
JetBrains IDE / Toolbox|JetBrains||idea64.exe,pycharm64.exe,jetbrains-toolbox.exe||jetbrains.com|cloud-dev|
Roblox|Roblox|com.roblox.client|RobloxPlayerBeta.exe||roblox.com,rbxcdn.com|games-more|
部落冲突 / 皇室战争（国际服）|Supercell|com.supercell.clashofclans|||supercell.com,supercell.net|games-more|
PUBG Mobile|PUBG Mobile|com.tencent.ig|||pubg.com,krafton.com|games-more|
Call of Duty Mobile|CODM|com.activision.callofduty.shooter|||callofduty.com,activision.com|games-more|
Pokémon GO|Pokemon GO|com.nianticlabs.pokemongo|||nianticlabs.com,pokemongolive.com|games-more|
Garena Free Fire|Free Fire|com.dts.freefireth|||garena.com|games-more|
Riot Client|Riot Client||RiotClientServices.exe||riotgames.com|games-more|
PlayStation App|PlayStation|com.scee.psxandroid|||playstation.com,sonyentertainmentnetwork.com|playstation|
Nintendo Switch Online|Nintendo|com.nintendo.znca|||nintendo.com,nintendo.net|nintendo|
Xbox|Xbox|com.microsoft.xboxone.smartglass|||xbox.com,xboxlive.com|xbox|
Walmart|Walmart|com.walmart.android|||walmart.com|shop-more|
Etsy|Etsy|com.etsy.android|||etsy.com|shop-more|
Zalando|Zalando|de.zalando.mobile|||zalando.com|shop-more|
Vinted|Vinted|fr.vinted|||vinted.com|shop-more|
Mercari|Mercari|com.kouzoh.mercari|||mercari.com|shop-more|
Rakuten|Rakuten|jp.co.rakuten.android|||rakuten.co.jp,rakuten.com|shop-more|
Mistral Le Chat|Le Chat|ai.mistral.chat|||mistral.ai|ai-more|
Poe|Poe|com.poe.android|||poe.com|ai-more|
Midjourney|Midjourney||||midjourney.com|ai-more|
Meta AI|Meta AI||||meta.ai,facebook.com|meta|
NotebookLM|NotebookLM||||notebooklm.google|ai-more|
Suno|Suno||||suno.com|ai-more|
ElevenLabs|ElevenLabs||||elevenlabs.io|ai-more|
快手|Kuaishou|com.smile.gifmaker||com.jiuyi.kuaishou|kuaishou.com,yximgs.com||1
腾讯视频|Tencent Video|com.tencent.qqlive|QQLive.exe||v.qq.com,gtimg.com||1
爱奇艺|iQIYI|com.qiyi.video|QyClient.exe||iqiyi.com,qiyipic.com||1
优酷|Youku|com.youku.phone|youku.exe||youku.com,ykimg.com||1
芒果TV|Mango TV|com.hunantv.imgo.activity|||mgtv.com||1
12306|12306|com.MobileTicket|||12306.cn|cn-bank-direct|1
云闪付|UnionPay|com.unionpay|||unionpay.com,95516.com|cn-bank-direct|1
招商银行|CMB|cmb.pb|||cmbchina.com|cn-bank-direct|1
工商银行|ICBC|com.icbc|||icbc.com.cn|cn-bank-direct|1
建设银行|CCB|com.chinamworld.main|||ccb.com|cn-bank-direct|1
中国银行|BOC|com.chinamworld.bocmbci|||boc.cn|cn-bank-direct|1
农业银行|ABC|com.android.bankabc|||abchina.com|cn-bank-direct|1
闲鱼|Xianyu|com.taobao.idlefish|||goofish.com,xianyu.com||1
阿里云盘|Aliyun Drive|com.alicloud.databox|aDrive.exe||alipan.com,aliyundrive.com||1
迅雷|Xunlei|com.xunlei.downloadprovider|Thunder.exe||xunlei.com||1
喜马拉雅|Ximalaya|com.ximalaya.ting.android|||ximalaya.com||1
番茄小说|Fanqie Novel|com.dragon.read|||fanqienovel.com||1
携程旅行|Ctrip|ctrip.android.view|||ctrip.com||1
大众点评|Dianping|com.dianping.v1|||dianping.com||1
小米 / HyperOS 服务|Xiaomi|com.xiaomi.xmsf|||xiaomi.com,mi.com,miui.com||1
华为 / 荣耀服务|Huawei|com.huawei.hwid|||huawei.com,hicloud.com,honor.com||1
`;
