// ============================================================================
// 名称：Lowex 原创 · Surge 系空重写脚本（自建起点）
// 用途：Surge / Loon / Quantumult X / Shadowrocket / Stash 的 HTTP 重写脚本。
//       空实现（$done({})：原样返回，不做任何修改），先验证引用链路能跑通，
//       再按下面的 [Script] / [MITM] 片段示例改成你自己的逻辑。
// 用法：把本文件放到你自己的 GitHub 仓库（或等本仓库合并到 main 后直接用
//       App「脚本库」里的链接），按客户端文档格式引用 URL，并锁定 SHA256。
// 安全提示：hostname 只写该脚本必需的域名，绝不写 *；不要引用不明作者的脚本。
// ============================================================================

// 空实现：不对请求/响应做任何修改
$done({});

// ---- 引用片段示例（按你所用客户端的文档格式粘贴，<URL> 换成本文件链接）----
// Surge:
//   [Script]
//   LowexNoop = type=http-response, pattern=^https://example\.com/, requires-body=0, script-path=<URL>
//   [MITM]
//   hostname = example.com
//
// Loon:
//   [Script]
//   http-response ^https://example\.com/ script-path=<URL>, requires-body=false, tag=LowexNoop
//   [MITM]
//   hostname = example.com
//
// Quantumult X:
//   [rewrite_local]
//   ^https://example\.com/ url script-response-body <URL>
//   [mitm]
//   hostname = example.com
//
// Shadowrocket / Stash：按各自文档把上面的 rewrite_local / mitm 片段粘贴到配置对应段。
// 注意：hostname 只写必需域名，绝不写 *。
