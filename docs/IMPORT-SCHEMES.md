# 导入 URL scheme（v1.5.0 重新核对，2026-10-17）

Lowex 在本机生成配置、**没有服务器**，而 URL scheme 只能携带「配置的在线地址」，不能携带整份本地文件。所以：

- **有 https 直链**（你自己放到 Gist / 对象存储等）→ 「一键导入」直接进入客户端的导入页。
- **没有直链** → 只「唤起 App」只会打开客户端首页，**不会**进入导入页（这是 scheme 的限制，不是 bug）。v1.5.0 起改为主推「用 {客户端} 打开文件」：把带正确扩展名的文件交给系统「打开方式」，由客户端自己的导入流程处理（需要客户端声明了对应文件类型；没有的话退回分享面板）。

| 客户端 | scheme | 依据 |
|---|---|---|
| Surge | `surge:///install-config?url=<enc>` | manual.nssurge.com/others/url-scheme（只有 url 参数；v1.5.0 去掉了未记载的 name） |
| Loon | `loon://import?sub=<enc>`（「安装远端配置文件」） | nsloon.bid/document/scheme（`nodelist=` 才是节点订阅） |
| Stash | `stash://install-config?url=<enc>` | stash.wiki/faq/url-schema（也可 `clash://`；无 name 参数） |
| Egern | `egern:/profiles/new?name=&url=` | egernapp.com/docs/url-scheme |
| sing-box | `sing-box://import-remote-profile?url=<enc>#<name>` | sing-box 官方文档 |
| Karing | `karing://install-config?url=&name=` | karing.app/cooperation/scheme |
| Clash Verge Rev | `clash://install-config?url=<enc>` | clashverge.dev/guide/url_schemes |
| FlClash | `flclash://install-config?url=`（也接受 `clash://`） | FlClash README |
| Clash Mi | `clash://install-config?url=&name=` | KaringX/clashmi |
| Clash Party | `mihomo://install-config?url=&name=`（v1.5.0 起；此前误用 `clash://`） | clashparty.org/docs/guide/urlscheme |
| CMFA | `clash://install-config?url=` | Clash 通用约定（未逐项核实） |
| Shadowrocket | `shadowrocket://config/add/{url}`（v1.5.0 起不再对 url 做百分号编码，与手册写法一致） | LOWERTOP/Shadowrocket 手册；官方无文档，**未在真机验证** |
| Quantumult X | 无整份配置导入 scheme：`quantumult-x:///update-configuration?remote-resource=<json>` / `add-resource` 只接受 server_remote / filter_remote / rewrite_remote 的**资源片段**，不能导入完整 .conf | crossutility/Quantumult-X url-scheme.md |

URL 编码：query 参数用「字母数字 + `-._~`」之外全部百分号编码（避免 `&` `?` `#` 截断）。
