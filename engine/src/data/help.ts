/** 白话说明库：每个设置项「是什么 / 为什么 / 推荐 / 风险 / 哪些客户端生效」。界面里 ⓘ 按钮会读这里。 */
import type {Family} from './clients';
export interface Help{
  t:string;            // 标题
  what:string;         // 是什么
  why?:string;         // 为什么要它 / 什么时候用
  rec?:string;         // 推荐值
  risk?:string;        // 风险 / 副作用
  apply?:string;       // 哪些客户端生效（本站生成器的实际行为）
  cl?:Partial<Record<Family,string>>; // 针对某类客户端的补充
}
export const FAMILY_NAME:Record<Family,string>={mihomo:'Mihomo 系（Clash Verge Rev、FlClash、Clash Mi 等）',singbox:'sing-box 系',surge:'Surge',qx:'Quantumult X',shadowrocket:'Shadowrocket',loon:'Loon',stash:'Stash',egern:'Egern'};
export const HELP:Record<string,Help>={
/* ===== 首页 ===== */
platform:{t:'设备',what:'你要在哪个系统上用这份配置。',why:'不同系统能用的客户端不同；iOS 做不到「按 App 分流」，桌面/Android 可以。',rec:'选你正在用的设备；一个人有多台设备，就分别生成一份。'},
client:{t:'客户端',what:'生成的配置文件是给哪个软件用的。每个软件的语法不一样，所以必须先选对。',why:'同一套「你的选择」会被翻译成该软件的写法。',rec:'桌面首选 Clash Verge Rev；iPhone 看你已有的软件，Shadowrocket / Stash / Surge 都行；Android 用 FlClash。',risk:'标「已校验」的用官方内核跑过检查；标「文档核对」的只对照过官方文档，没在真机导入过，请先试导入。'},
status:{t:'客户端维护状态',what:'这个客户端最近一次更新的时间和版本。',why:'很久没更新的软件可能不支持新协议或新语法，也可能有安全问题。',rec:'本站只列仍在更新的客户端。'},
minver:{t:'最低 / 建议版本',what:'生成的配置需要的内核版本。',why:'配置里用了较新的写法（例如 sing-box 1.14 才有的 http_clients），内核太旧会报「未知字段」。',rec:'直接升级到客户端的最新版。'},
preset:{t:'一键预设',what:'一组常见场景的服务分组开关和少数参数。',why:'不知道从哪开始时，先点一个，再逐项改。',rec:'日常用选「日常均衡」；只想要最小改动选「极简」。',risk:'预设会改「服务分组」的开关，不动你的节点和订阅。'},
glass:{t:'玻璃效果',what:'界面的毛玻璃/液态玻璃显示方式，只影响本网页的外观，不影响生成的配置。',why:'不同设备能力不同：支持系统玻璃就用系统的；其次是本站自绘的折射；再其次是普通磨砂；最后是纯色。',rec:'保持「自动」。卡顿或耗电可以手动选「磨砂」或「纯色」。',risk:'折射档只折射自绘的背景，不会折射下面滚动的文字。'},
/* ===== 节点 ===== */
sub:{t:'订阅链接',what:'机场给你的一个网址，打开后是节点列表，更新时由客户端自动重新下载。',why:'有订阅时，Mihomo / Surge / Loon 等会把它写成「远程订阅」，节点变动不用重新生成。',rec:'名称随便取，用来在客户端里区分多个订阅。',risk:'订阅链接相当于你的账号密码，别发给别人；本站默认不保存它（刷新就清空）。',cl:{singbox:'sing-box 没有订阅功能，需要把节点展开写进文件，所以要先「拉取」或粘贴节点。',shadowrocket:'小火箭的配置文件里不能带订阅，请在它的「首页」单独添加订阅；本配置里的分组会用正则自动收纳节点。'}},
fetchsub:{t:'拉取订阅',what:'由你的浏览器直接向订阅服务器下载节点列表，不经过本站或任何中转。',why:'sing-box 等客户端需要把节点写进文件。',risk:'很多订阅服务器不允许浏览器跨域访问，会失败；这时在别处打开订阅，把内容复制进「粘贴节点」。'},
paste:{t:'粘贴节点',what:'直接粘贴 ss:// vmess:// vless:// trojan:// hysteria2:// tuic:// anytls:// 链接，每行一个；也可以整段粘贴 base64 订阅内容。',why:'没有订阅、或客户端不支持订阅时使用。',risk:'不同客户端支持的协议不同（例如 Surge 不支持 Reality），不支持的会被跳过并在文件里注明。'},
nodefilter:{t:'节点过滤（正则）',what:'用「正则表达式」决定保留或排除哪些节点，按节点名字匹配。',why:'机场常塞「剩余流量」「到期时间」这类假节点，会被自动测速选中导致断网。',rec:'「排除」保持默认；「只保留」留空表示全要。',risk:'正则写错会被忽略；对订阅里的节点只在 Mihomo / Stash 生效。',apply:'订阅里的节点：Mihomo、Stash；粘贴的节点：全部客户端。'},
lb:{t:'负载均衡组',what:'多加一个「全部-负载均衡」组：同一个网站固定走同一个节点，不同网站分散到不同节点。',why:'想把流量摊到多个节点、提高总速度。',rec:'普通用户不需要；开了也只是多一个可选项，不会自动启用。',risk:'同一时间会有多个出口 IP，银行、交易所这类风控敏感站点不要用。',apply:'仅 Mihomo 系与 Stash。'},
remember:{t:'在这台设备上记住订阅与节点',what:'把订阅和节点保存在浏览器本地（localStorage），下次打开还在。',why:'省得每次重新填。',rec:'自己的电脑可以开；公用电脑别开。',risk:'保存在本机浏览器里，不会上传；但清浏览器数据会丢，且同一台电脑的其他人可能看到。'},
/* ===== 规则 ===== */
svcgroup:{t:'服务分组',what:'把一类网站（AI、Netflix、Telegram、银行……）打包成一组，统一决定它们走哪里。',why:'按服务选比一个个填域名省事；规则集来自 MetaCubeX / blackmatrix7 等开源项目，会自动更新。',rec:'只开你用得到的，规则越少越省内存（iOS 尤其）。',risk:'同一个域名被多个组命中时，写在前面的先生效；见「合并流程」里的冲突提示。'},
policy:{t:'出口（走哪里）',what:'一个服务分组的流量交给谁：一键代理、直连、拦截，或某个地区的节点组。',why:'把「看 Netflix 走新加坡、银行走香港、国内直连」这种需求落到具体的组。',rec:'默认的「地区 · 故障转移」最稳：先用你手选的节点，挂了自动换最快的。',risk:'「自动测速」会换 IP，风控敏感网站不要用；「拦截」会让对应服务打不开。',cl:{surge:'本站对 Surge 把「故障转移」写成「自动测速」组（url-test）。',loon:'同上：故障转移用自动测速组代替。',qx:'同上：故障转移用 url-latency-benchmark 自动测速代替。',shadowrocket:'同上：故障转移用自动测速组代替。',egern:'同上：故障转移用 auto_test 自动测速代替。'}},
risk:{t:'风控敏感',what:'银行、券商、交易所这类网站，看到 IP 频繁变化或来自异常地区会冻结账户或要求重新验证。',rec:'出口固定为一个地区，再到客户端里把该地区组选成「手动」固定一个节点。'},
app:{t:'按 App 分流',what:'指定某个应用走哪个出口。Windows/macOS/Linux 按「进程名」，Android 按「包名」。',why:'有些软件不走域名规则（比如游戏、下载器），按进程更准。',rec:'桌面需要开 TUN，并用管理员权限运行客户端才能识别所有进程。',risk:'iOS 系统不告诉 VPN 应用「哪个 App 发起了连接」，所以 iOS 上做不到；本站会改成设置该 App 所在服务分组的出口，或让你用「自定义域名」。应用更新后包名/进程名可能变化。',apply:'进程/包名规则：Mihomo 系、sing-box；其余客户端会自动改成服务组或域名。'},
appsearch:{t:'在线搜索 App',what:'用苹果官方的 iTunes Search API 按名称查 App，得到名称和 Bundle ID。',why:'把 App 加到分流里。',risk:'只在你点搜索时向苹果发一次请求；Google Play 没有公开接口，Android 包名只能用内置库或手填。'},
customdomain:{t:'自定义域名',what:'你自己填的域名（按「域名后缀」匹配：example.com 同时匹配 www.example.com）。',why:'优先级高于服务分组和按 App。iOS 上想给某个 App 指定出口，最实用的办法就是把它用到的域名填这里。',rec:'列表从上到下就是优先级，用「↑ ↓」调整；同一个域名别重复写。',risk:'填得太宽（例如 com）会吞掉大量流量。'},
customset:{t:'自定义规则集（URL）',what:'引用别人维护好的规则列表网址，让它们走你指定的出口；列表更新时客户端自动同步。',why:'本站内置的服务不够用时，可以直接用 GitHub 上现成的规则集，比如 blackmatrix7、MetaCubeX、ACL4SSR、Loyalsoldier。',rec:'选对类型：只有域名 → 域名；只有 IP 段 → IP；混合写法（每行如 DOMAIN-SUFFIX,x.com）→ 混合。链接必须是 https:// 直链（GitHub 用 raw.githubusercontent.com）。',risk:'规则集来自第三方，内容你要自己信任；格式必须和客户端匹配，不匹配会在生成时给出提示并跳过。',cl:{mihomo:'支持 .mrs（二进制，仅域名/IP 类型）、.yaml、.list/.txt。',stash:'支持 .yaml 和 .list/.txt，不支持 .mrs。',singbox:'只认 .srs（二进制）和 .json（源码）。.list/.yaml 需要先用 sing-box rule-set convert 转换。',surge:'只认 .list/.txt 文本规则集。',loon:'只认 .list/.txt 文本规则集。',qx:'只认 .list/.txt 文本规则集。',shadowrocket:'只认 .list/.txt 文本规则集。',egern:'只认 .list/.txt 文本规则集（Surge 格式）。'}},
importrules:{t:'从已有配置导入',what:'把你现有配置里的 DOMAIN / DOMAIN-SUFFIX 规则读出来，变成自定义域名。',why:'换客户端时不用重写。Clash、Surge、Loon、Quantumult X 的规则行都能读。',risk:'只导入域名类规则；IP、GEOIP、规则集等会被忽略并告诉你数量。策略名一律映射成 直连 / 拦截 / 一键代理，导入后请逐条检查。'},
pipeline:{t:'合并流程',what:'展示本站如何把「特殊网络 → 自定义域名 → 自定义规则集 → 按 App → 内置保护 → 拦截 → 服务分组 → 兜底」合并成一份配置。',why:'客户端从上往下匹配，命中即停，所以「越具体越靠前」。'},
/* ===== 推荐 / 参数 ===== */
network:{t:'你的网络',what:'你现在用的网络类型。',why:'运营商和网络类型会影响 MTU、DNS 选择和某些线路的丢包情况。',rec:'不确定就选「其他」。'},
location:{t:'你所在的地区',what:'你人在哪里，只用来决定 DNS 和分流策略。',why:'人在海外时，国内服务要走「回国」线路，境外网站直连。',rec:'本站不读取真实定位，也不联网查 IP，完全按你选的来。'},
regions:{t:'地区组',what:'按节点名里的地区关键词（HK、日本、🇺🇸……）自动建组。',why:'「香港」「日本」这样的组才能被服务分组选作出口。',rec:'只勾选你订阅里确实有的地区，没有的地区在 Mihomo 里会是空组（指向直连）。',cl:{mihomo:'每个地区生成 手动 / 自动测速 / 故障转移 三层组。'}},
customregion:{t:'自定义地区组',what:'自己按节点名关键词建一个组，例如「家宽」「游戏专线」「IEPL」。',why:'机场的节点不一定按国家命名，按自己的叫法建组更灵活。',rec:'关键词用 | 分隔，例如 家宽|住宅。写完会出现在所有出口下拉里。',risk:'关键词写太泛会把不相干的节点也收进来。'},
ipv6:{t:'IPv6',what:'是否允许走 IPv6 网络。',why:'多数机场节点没有 IPv6 出口；如果系统用 IPv6 访问，请求会绕过代理直连，等于泄漏你的真实地址。',rec:'关闭（默认）。只有你确认节点和网络都支持 IPv6 才打开。',risk:'关闭后访问纯 IPv6 的网站会失败（国内少见）；校园网有的对 IPv6 免流，关闭会损失这部分。',apply:'Mihomo 系、sing-box、Surge、Loon、Quantumult X、Shadowrocket、Egern。',cl:{mihomo:'同时设置顶层 ipv6、dns.ipv6，并让 TUN 不分配 IPv6 地址。',singbox:'DNS 策略 ipv4_only，TUN 不加 IPv6 地址。',qx:'写进 [dns] 的 no-ipv6。'}},
tun:{t:'TUN 虚拟网卡',what:'在系统里创建一块虚拟网卡，把所有流量都接管给代理软件。',why:'不依赖程序自觉使用系统代理；按进程分流、拦截 UDP/DNS 都需要它。',rec:'桌面和 Android 打开；需要管理员权限（Windows 用服务模式）。',risk:'可能和其他 VPN、虚拟机网络冲突；开启后遇到「上不了网」先检查是否有别的 VPN。',apply:'Mihomo 系、sing-box 写入配置；Stash 与 Surge/Loon/QX/Shadowrocket/Egern 由 App 自己的 VPN 开关管理。',cl:{mihomo:'写入 tun 段：auto-route、strict-route、dns-hijack any:53。',singbox:'写入 tun 入站：auto_route、strict_route。iOS/Android 官方 App 由 App 管理 TUN。'}},
fakeip:{t:'DNS 用 fake-ip',what:'应用查域名时，立刻返回一个假 IP（198.18.0.0/15 内），真正的解析交给代理那一端。',why:'快（不用等解析）、不泄漏（本机根本没有向外发真实 DNS 查询）。',rec:'打开（默认）。局域网、国内常用域名、NTP、连通性检测已自动排除。',risk:'极少数依赖真实 IP 的软件会异常（局域网投屏、部分游戏、网络测速）。遇到这类问题关闭它，改用 redir-host。',apply:'Mihomo 系、sing-box。',cl:{mihomo:'enhanced-mode: fake-ip，并带 fake-ip-filter。',singbox:'fakeip DNS 服务器，A 记录查询走 fakeip。'}},
quic:{t:'拦截境外 QUIC',what:'QUIC 是基于 UDP 443 的 HTTP/3。选「拦截」后，境外的 QUIC 会被拒绝，浏览器自动回退到 TCP。',why:'很多节点对 UDP 的支持不稳定或限速；回落到 TCP 更稳，也避免 QUIC 绕过代理。',rec:'打开（默认）；国内 QUIC 不拦。',risk:'个别应用（部分视频 / 游戏）只用 UDP，被拦会慢；此时关闭。',cl:{qx:'Quantumult X 只能用 udp_drop_list 丢弃所有 QUIC（含国内），浏览器会自动改走 TCP。',shadowrocket:'没有可靠的官方写法，本配置不生成 QUIC 拦截。',stash:'未核实 Stash 的写法，已省略。'}},
stun:{t:'STUN / WebRTC',what:'STUN 是 WebRTC（网页视频通话、语音）用来查询你公网 IP 的协议。',why:'不处理的话，网页可能通过 WebRTC 看到你的真实 IP（一种常见泄漏）。',rec:'「走代理」让它看到的是代理出口；节点不支持 UDP 时选「拦截」。',risk:'拦截后网页视频通话可能无法直连，只能走中继；「不处理」会有泄漏风险。仅靠配置文件无法完全关掉浏览器的 WebRTC，请看「防泄漏」页里的浏览器设置。',cl:{qx:'只能用 udp_drop_list 丢弃 STUN；「走代理」没有官方写法，保持默认。'}},
unknown:{t:'未知域名',what:'没有命中任何规则的网站，该走哪里。',why:'这是「黑名单」还是「白名单」的区别：走代理 = 只有国内直连，其余都代理（更保守）；直连 = 只有被规则命中的才代理（更快，但可能漏代理）。',rec:'走代理（默认）。'},
ads:{t:'广告拦截',what:'用广告规则集把广告域名直接拒绝。',why:'省流量、页面更干净。',rec:'iOS 选 Lite（规则少、占内存少、误伤少）；桌面可选完整。',risk:'规则越多越容易误伤正常功能（登录、优惠券、部分视频）；服务异常时先关掉广告拦截试试。放在服务分流之前生效。'},
telemetry:{t:'拦截遥测',what:'拒绝一批常见的软件遥测（数据收集）域名。',rec:'开（默认），规模很小。',risk:'极少数软件会因为遥测被拒而报错，出问题时关掉。'},
trackers:{t:'拦截追踪器',what:'拒绝常见的广告 / 用户分析 / 归因 SDK 域名（Google 广告、Adjust、AppsFlyer、Mixpanel、友盟、CNZZ 等约 70 个）。只按域名拒绝，不解密流量，不需要 MITM。',why:'减少 App 和网页向第三方上报你的行为，也省一点流量。',rec:'开（默认）。',risk:'个别 App 的登录、支付、广告联盟分成或归因会依赖这些域名；异常时先关掉本项。放在服务分流之前生效，各客户端都用 REJECT 写法。'},
icons:{t:'策略组图标',what:'给每个策略组（一键代理、各服务、各地区、广告拦截等）配一张图标，在客户端的面板里一眼认出。图标是 GitHub 公开图标仓库（Qure、Orz-3/mini、lige47、Semporia、luestr 等）里的 PNG 链接，配置里只写 URL，不内置图片。',why:'分组多了，纯文字很难找；有图标后和手动配置的面板一致。',rec:'开（默认）。',risk:'客户端会在后台下载这些图片：访问 raw.githubusercontent.com，国内可能慢，必要时关闭。个别没有现成图标的品牌（如部分欧洲银行）用同类通用图标代替。',apply:'Mihomo 系 / Stash（icon）、Surge（icon-url）、Loon / Quantumult X（img-url）、Egern（icon）。Shadowrocket 与 sing-box 的配置里没有分组图标字段，不会写。'},
lowmem:{t:'低内存模式',what:'降低规则缓存、把规则集更新间隔拉长到 3 天。',why:'iOS 的 VPN 扩展有严格内存上限，超了会被系统杀掉导致断网。',rec:'iOS 打开，桌面不用。',apply:'Mihomo 系、sing-box。'},
keepalive:{t:'TCP 保活',what:'定期发小包让长连接不被运营商或 NAT 当作空闲而断开。',why:'手机蜂窝网络或在移动中，长连接更稳。',rec:'移动设备可开；桌面不需要。',risk:'会稍微增加耗电和流量。',apply:'Mihomo 系（keep-alive-idle 600，interval 30）。'},
allowlan:{t:'允许局域网连接',what:'让同一局域网里的其他设备也能使用你电脑上的代理端口。',why:'给手机/电视临时共用。',rec:'关闭（默认）。',risk:'打开后同网络里的任何人都能用你的代理（泄漏流量、被滥用）；校园网可能检测到共享而封号。'},
mtu:{t:'TUN MTU',what:'虚拟网卡一个数据包最大多少字节。',why:'太大时会被路径上的设备分片或丢弃，表现为部分网站卡住、大文件下载中断。',rec:'1420 通常够用；蜂窝 1380–1400；公司网络叠了别的隧道时 1380。仍丢包就再降 20。',risk:'太小会略微降低吞吐，影响不大。',apply:'Mihomo 系、sing-box。'},
tunstack:{t:'TUN 协议栈',what:'虚拟网卡内部怎么处理 TCP/UDP：system（用系统的，最快）、gvisor（自己实现，兼容最好但费 CPU）、mixed（TCP 用系统、UDP 用 gvisor，折中）。',rec:'mixed（默认）；出怪问题试 gvisor；追求速度且系统支持再试 system。',apply:'Mihomo 系。sing-box 使用其默认协议栈。'},
mixedport:{t:'混合端口',what:'本机上的 HTTP + SOCKS 代理端口，应用可以手动设成使用它。',rec:'7890（Clash 习惯）。和别的软件冲突时换一个 1024–65535 的端口。',apply:'Mihomo 系、sing-box 桌面。'},
apiport:{t:'控制 API 端口',what:'给网页面板（metacubexd、zashboard 等）管理内核用的端口，只在本机监听。',rec:'9090。',risk:'API 密钥由本站随机生成，别泄漏；CORS 白名单只放了两个面板域名，没有用 *。',apply:'Mihomo 系。'},
secret:{t:'API 密钥',what:'访问控制 API 时要带的密码。',why:'防止你浏览别的网页时，那个网页偷偷调用本机的控制 API（改你的配置）。',rec:'保持自动生成的随机值。'},
loglevel:{t:'日志级别',what:'软件记录多少日志。',rec:'warning（默认）。排错时临时用 info 或 debug。',risk:'debug 日志很多，会占磁盘、拖慢速度，还可能包含你访问的域名，用完改回来。',apply:'Mihomo 系、sing-box。'},
interval:{t:'测速间隔（秒）',what:'自动测速组多久重新测一次各节点的延迟。',why:'间隔短切换更及时，但更费流量和电量，也容易让 IP 频繁变化。',rec:'600（10 分钟）。',apply:'Mihomo 系、sing-box、Surge、Loon、Quantumult X、Shadowrocket、Egern。'},
tolerance:{t:'切换容差（毫秒）',what:'新节点要比当前节点快至少这么多毫秒，自动测速组才会换过去。',why:'防止两个节点延迟差不多时来回跳，导致 IP 频繁变化、连接中断。',rec:'50。网络很稳定可以降到 20；喜欢稳定不想换可以调到 100。',risk:'设得太大，节点变差了也不会及时切走。'},
testurl:{t:'测速 URL',what:'测延迟时请求的地址，要求返回 HTTP 204 或很小的页面。',rec:'https://www.gstatic.com/generate_204（默认，全球 CDN，几乎不会失败）。',risk:'换成不稳定的地址会导致自动测速全部判失败，节点被误判为不可用。'},
dnscn:{t:'国内 DNS（DoH）',what:'解析国内域名用的加密 DNS 服务器，直连发出。',why:'国内域名用国内 DNS 才能解析到离你最近的 CDN 节点；用 DoH（加密）运营商看不到你查了什么。',rec:'阿里 223.5.5.5 + 腾讯 1.12.12.12 的 DoH。每行一个，必须是 https:// 开头。',risk:'填明文 DNS（IP 或 udp://）会在「防泄漏」里标为部分防护。'},
dnsremote:{t:'境外 DNS（DoH）',what:'解析境外域名用的加密 DNS，经代理发出。',why:'走代理发出可以避免被污染，也不会把查询暴露给本地运营商。',rec:'Cloudflare 1.1.1.1 + Google 8.8.8.8 的 DoH。',risk:'如果代理断了，境外域名解析也会失败（这是预期行为，防止泄漏）。'},
campus:{t:'校园网认证（必须直连）',what:'校园网登录页的域名和 IP 段。',why:'认证页必须直连，走代理会登录不上，进而整个网络断掉。',rec:'填认证门户域名和认证服务器 IP 段（例如 10.1.1.1/32）。会放在规则最前面。'},
home:{t:'家庭 / 公司内网',what:'内网域名、网关和内网 DNS。',why:'让内网域名直连并用内网 DNS 解析，同时从 fake-ip 里排除，避免访问 NAS、路由器页面失败。',rec:'没有内网需求就留空。'},
wificalling:{t:'Wi-Fi 通话（VoWiFi）',what:'手机通过 Wi-Fi 打电话 / 发短信时，会先和运营商的 ePDG 网关建立 IPsec（IKEv2，UDP 500 与 4500）隧道。本功能把这些网关的域名单独拿出来，让它们走你指定的出口（直连，或某个固定节点）。域名按 3GPP 规则生成：epdg.epc.mnc<三位MNC>.mcc<MCC>.pub.3gppnetwork.org，IMS 为 ims.mnc<三位MNC>.mcc<MCC>.3gppnetwork.org。',why:'默认「其他流量」可能被代理绕到别的国家，运营商看到注册 IP 和号码归属地不一致就会拒绝，或 UDP 被丢包造成注册失败、断线。',rec:'在运营商所在国：直连。人在国外、想用原籍卡通话：选运营商所在国的「手动选节点」固定 IP 节点，且要支持 UDP 500/4500，不要用自动测速组（换 IP 会断）。拿不准 MNC 就看 SIM 信息，两位 MNC 要补零成三位。',risk:'节点不支持 UDP 或 IP 变化会让通话注册失败；「未验证」的域名只是按 3GPP 规则推导，公共 DNS 查不到，不保证存在。只有能按域名匹配 UDP 的客户端才生效；iOS 上 Wi-Fi 通话流量是否经过 VPN 取决于系统与客户端，以实测为准。',apply:'所有支持的客户端（各自语法：Mihomo 的 AND/UDP/DST-PORT、sing-box 的逻辑规则、Surge/Loon/QX/小火箭/Egern 的域名后缀规则）。'},
/* ===== 模块与脚本 ===== */
modules:{t:'模块与脚本',what:'模块是别人打包好的一组「重写规则 + 脚本 + MITM 主机名」，用来去广告、改写网页或接口、做自动任务。常见格式：.sgmodule（Surge / 小火箭）、.plugin（Loon）、.snippet（Quantumult X）、.stoverride（Stash）。',why:'规则只能决定「走哪里」，模块才能改写内容（比如直接拒绝某个广告接口）。',rec:'先只用广告拦截类，且只用你认识、能看到源码的来源。链接或内容二选一：只填链接 = 引用；粘贴内容 = 本站解析后按你的客户端语法写进配置。',risk:'脚本会在 MITM 解密后读取并修改你的 HTTPS 请求和响应，等于能看到你在这些网站上的登录信息。不要用来源不明的脚本；本站不嵌入用于绕过付费、订阅的模块。',apply:'Surge、Shadowrocket、Loon、Quantumult X、Stash、Egern。Mihomo 与 sing-box 没有 MITM 脚本功能，不适用。',cl:{surge:'模块是 App 内功能，配置文件不能引用；粘贴内容会写进 [URL Rewrite] / [Script] / [MITM]。',shadowrocket:'同 Surge 写法；模块列表在 App 的「配置 → 模块」里添加。',loon:'链接会写进 [Plugin]；粘贴内容写进 [Rewrite] / [Script] / [MITM]。',qx:'链接（.snippet / .conf）写进 [rewrite_remote]；粘贴内容写进 [rewrite_local] / [task_local] / [mitm]。',stash:'按覆写的 http: 写法生成，未在真机验证。',egern:'语法未核实，只生成安装清单。'}},
mitm:{t:'MITM 与主机名',what:'MITM（中间人解密）让客户端临时解开指定网站的 HTTPS，才能改写内容或运行脚本。「主机名」就是允许解密的域名清单。',why:'重写与脚本只对清单里的域名生效；不在清单里的网站不会被解密。',rec:'只放确实需要的域名，越少越好；不要写「*」；支付、银行、微信、政务类域名一律不要放。',risk:'需要在客户端里生成并信任 MITM 证书（iOS 还要在「设置 → 通用 → 关于本机 → 证书信任设置」里打开完全信任）。证书私钥泄漏等于所有流量可被解密。部分 App 做了证书固定，会因此无法联网。',apply:'Surge、Shadowrocket、Loon、Quantumult X、Stash。'},
userrewrite:{t:'自定义重写（URL）',what:'用正则匹配请求地址：拒绝它，或跳转到另一个地址。',why:'不需要脚本、也不需要整个模块时，用它最轻量，例如拒绝一个广告接口。',rec:'拒绝类优先选 reject（直接断开）；想让 App 以为成功用 reject-200 / reject-dict（返回空 JSON）。写得越精确越好。',risk:'HTTPS 地址要生效必须在 MITM 主机名里包含它的域名；正则写得太宽会误伤正常请求。',apply:'Surge、Shadowrocket、Loon、Quantumult X、Stash。'},
modkind:{t:'模块类型标签',what:'你给这个模块贴的分类：广告拦截 / 重写 / 增强 / 路由辅助 / 其他。',why:'只是方便你管理，不影响生成。',rec:'拿不准就选「其他」。'},
adsets:{t:'广告规则集（不需要 MITM）',what:'基于域名的广告规则列表，直接把广告域名拒绝，不解密流量。',why:'比脚本类广告模块安全得多，应当优先使用。',rec:'点「＋」会添加到「自定义规则集」，出口为拦截。来源是 blackmatrix7 / ACL4SSR 这类开源项目。',risk:'规则越多越可能误伤；服务异常时先关掉。'},
/* ===== 生成 ===== */
output:{t:'生成的配置',what:'按你的所有选择生成的完整配置文件，在浏览器里本地生成。',rec:'先「下载文件」，再按下面「怎么导入」导入客户端。'},
leak:{t:'防泄漏清单',what:'根据你选的客户端和参数，逐项列出 DNS、IP、WebRTC、局域网等泄漏风险的防护状态。',rec:'生成后，用清单里的测试网站（BrowserLeaks、ipleak 等）实际测一遍。'},
diff:{t:'配置对比',what:'把当前生成的配置和你保存的基准做逐行对比。',why:'改了参数后确认到底变了什么。',risk:'基准只保存在本机，不会上传。'},
test:{t:'浏览器内测试',what:'在不运行任何客户端的情况下，检查结构、引用关系、规则集声明和各客户端的官方键名。',risk:'这是静态检查，不能代替真机导入；Mihomo 与 sing-box 另有官方内核校验。'},
export:{t:'一键导出',what:'打包成 zip：完整配置、仅规则、自定义域名规则集、来源清单、可读规则顺序、方案 JSON。',risk:'zip 里不含订阅和节点。'},
share:{t:'方案分享',what:'把你的选择压缩进一个链接或二维码，换设备时扫一下就能恢复。',risk:'不含订阅、节点和密钥。链接里是你的偏好（开了哪些服务组、出口等），发给别人前想一想。'},
plan:{t:'方案（导入 / 导出）',what:'你的全部选择（不是配置文件本身）保存成 JSON。',why:'备份、换设备、发给朋友。',risk:'默认不含订阅、节点和密钥；勾选「同时包含」时别把文件发给别人。'},
};
/** 术语表 */
export const GLOSSARY:{term:string;def:string}[]=[
 {term:'分流',def:'按规则决定每个连接走代理、直连还是被拦截。'},
 {term:'节点',def:'一台代理服务器及其连接参数。'},
 {term:'订阅',def:'机场提供的网址，里面是节点列表。'},
 {term:'策略组 / 代理组',def:'把多个节点（或其他组）打包成一个出口，有手动选择、自动测速、故障转移等类型。'},
 {term:'故障转移（fallback）',def:'按顺序用第一个可用的；它挂了才换下一个。IP 比较稳定。'},
 {term:'自动测速（url-test）',def:'定期测延迟，永远选最快的。快，但 IP 会跳。'},
 {term:'规则集（rule-set）',def:'一份域名或 IP 的列表，由开源项目维护，客户端定期下载。'},
 {term:'geosite / geoip',def:'按「网站类别」和「IP 归属地」分好类的规则数据库。'},
 {term:'TUN',def:'虚拟网卡，接管整台设备的流量。'},
 {term:'fake-ip',def:'先给应用一个假 IP，让代理端去真正解析域名。快且不泄漏。'},
 {term:'DoH / DoT',def:'加密的 DNS（走 HTTPS / TLS），运营商看不到你查询了什么。'},
 {term:'DNS 泄漏',def:'你开了代理，但 DNS 查询仍以明文发给本地运营商，暴露你访问的网站。'},
 {term:'IP 泄漏',def:'某些流量绕过代理，被网站看到你的真实 IP。'},
 {term:'WebRTC',def:'浏览器自带的实时通信功能，可能直接暴露你的真实 IP。需要在浏览器里设置。'},
 {term:'STUN',def:'WebRTC 用来查询公网 IP 的协议。'},
 {term:'QUIC / HTTP3',def:'基于 UDP 的新一代网页协议，部分节点对 UDP 不友好。'},
 {term:'MTU',def:'一个数据包的最大长度。设太大会丢包，设太小略损速度。'},
 {term:'嗅探（sniffer）',def:'从连接内容里读出域名，用于在只有 IP 时也能按域名分流。'},
 {term:'进程名 / 包名',def:'桌面软件的可执行文件名 / Android 应用的唯一标识，用于按 App 分流。'},
 {term:'Bundle ID',def:'iOS 应用的唯一标识（例如 com.apple.mobilesafari）。'},
 {term:'ECS',def:'DNS 客户端子网扩展：把你的大致网段告诉 DNS 服务器，换来更近的 CDN，但会泄漏一点位置信息。'},
 {term:'MITM',def:'中间人解密：客户端用自己的证书临时解开 HTTPS，才能改写内容。需要信任证书，只对白名单域名使用。'},
 {term:'模块（.sgmodule / .plugin / .snippet / .stoverride）',def:'打包好的重写规则 + 脚本 + 主机名。不同客户端格式不同，不能直接互用。'},
 {term:'重写（Rewrite）',def:'按请求地址拒绝或跳转的规则，比脚本轻。'},
 {term:'脚本（Script）',def:'一段 JavaScript，在请求或响应经过客户端时运行，可以改写内容，也可以按计划定时运行（cron）。'},
 {term:'直连 / 拦截',def:'直连：不走代理；拦截：直接丢弃连接。'},
];
