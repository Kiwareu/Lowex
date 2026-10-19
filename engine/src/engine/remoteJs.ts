/** 远程 JS 独立模块（9.8+）：与“生成配置文件”互斥独立，不写进配置文件。
 *
 *  两种类型，绝不混用，按客户端 gating：
 *  - config-overwrite（Mihomo 系配置级覆写）：脚本收到完整 config 对象，返回修改后的
 *    config。仅 Mihomo Party / Clash Verge Rev / FlClash 三个客户端已核实支持
 *    （其覆写脚本机制见各自文档）；其余 Mihomo 系客户端（Clash Mi、CMFA、裸内核）
 *    未核实，一律不提供。
 *  - http-rewrite（Surge 系 HTTP 重写）：http-request / http-response + MITM。
 *    仅 Surge / Loon / QX / Shadowrocket / Stash 支持；sing-box 不支持 JS 重写；
 *    Egern 未核实，仅提供注释说明。
 *
 *  安全红线（校验器强制执行）：仅 https + 仅 .js 结尾 + SHA256 锁定（64 位 hex）+
 *  仅自建/受信源；默认不内置任何第三方脚本；MITM hostname 绝不写 *；
 *  含付费绕过关键词的脚本直接拒绝；敏感域名（银行/支付/社交账号）需用户显式确认。
 */
import {CLIENTS} from '../data/clients';

export type RemoteJsKind = 'config-overwrite' | 'http-rewrite' | 'none';
export interface RemoteJsSupport { kind: RemoteJsKind; reason: string }
/** 按客户端 id gating（不是按家族：同一家族的不同 App 支持情况不同）。 */
export function remoteJsSupport(clientId: string): RemoteJsSupport {
  if (['clashparty', 'verge', 'flclash'].includes(clientId))
    return { kind: 'config-overwrite', reason: '该客户端支持配置级 JS 覆写（脚本收到 config 对象并返回修改后的 config）' };
  const c = CLIENTS.find(x => x.id === clientId);
  if (!c) return { kind: 'none', reason: '未知客户端' };
  if (['surge', 'loon', 'qx', 'shadowrocket', 'stash'].includes(c.family))
    return { kind: 'http-rewrite', reason: '该客户端支持 Surge 系 HTTP 重写（http-request / http-response + MITM）' };
  if (c.family === 'singbox') return { kind: 'none', reason: 'sing-box 不支持 JS 重写/覆写' };
  if (c.family === 'egern') return { kind: 'none', reason: 'Egern 的 JS 重写未核实，暂不提供' };
  return { kind: 'none', reason: '该客户端未核实支持 JS 覆写/重写' };
}

export interface RemoteJsInput { url: string; sha256: string; name?: string; mitmHosts?: string[]; confirmSensitive?: boolean; content?: string }
export interface RemoteJsCheck { blocked: string[]; warns: string[] }
const PAID_BYPASS = ['破解', '绕过付费', '解锁会员', '解锁付费', '去付费', '激活码', '授权破解', 'crack', 'bypass paywall', '付费解锁'];
const SENSITIVE = ['alipay', 'wechat', 'weixin', 'tenpay', 'unionpay', 'paypal', 'icloud', 'bank', 'wallet'];
/** 校验远程 JS 引用。blocked 非空 = 拒绝使用；warns = 需用户确认后才可继续。 */
export function validateRemoteJs(input: RemoteJsInput): RemoteJsCheck {
  const blocked: string[] = []; const warns: string[] = [];
  const url = (input.url || '').trim();
  if (!/^https:\/\//i.test(url)) blocked.push('远程 JS 只允许 https 链接');
  if (!/\.js(\?.*)?$/i.test(url)) blocked.push('远程 JS 链接必须以 .js 结尾');
  if (!/^[0-9a-f]{64}$/i.test((input.sha256 || '').trim())) blocked.push('必须提供 SHA256 锁定（64 位 hex）：作者更新脚本后哈希变化即拒绝加载，防供应链劫持');
  const hay = `${input.name || ''} ${url} ${input.content || ''}`.toLowerCase();
  for (const k of PAID_BYPASS) if (hay.includes(k.toLowerCase())) blocked.push(`含付费绕过关键词「${k}」，拒绝使用`);
  for (const h of input.mitmHosts || []) {
    const host = h.trim();
    if (!host) continue;
    if (host.includes('*')) warns.push(`MITM hostname「${host}」含通配符 *：必须只写该脚本必需的域名，绝不写 *`);
    if (SENSITIVE.some(s => host.toLowerCase().includes(s)) && !input.confirmSensitive)
      warns.push(`MITM hostname「${host}」涉及敏感域名（支付/账号类），需你显式确认后才可继续`);
  }
  return { blocked, warns };
}

/** 自建模板（身份变换，默认不做任何修改）：复制到你自己的 GitHub 仓库后填 URL + SHA256。
 *  不要直接用网上不明作者的脚本链接。 */
export const MIHOMO_SCRIPT_TEMPLATE = `// Lowex 自建远程 JS 覆写模板（Mihomo Party / Clash Verge Rev / FlClash 配置级覆写）
// 用法：把本文件放到你自己的 GitHub 仓库，在 App 里填 URL + 本文件的 SHA256。
// 下面是身份变换（原样返回 config），先验证链路能跑通，再按需改你自己的逻辑。
// 安全：不要从网上复制不明作者的覆写脚本；任何改动都要重新算 SHA256 并更新 App 里的锁定值。
function main(config) {
  // 示例：给所有策略组加一个统一前缀（默认注释掉，需要时取消注释）
  // if (config['proxy-groups']) {
  //   for (const g of config['proxy-groups']) g.name = 'Lowex-' + g.name;
  // }
  return config;
}
`;

export const SURGE_SCRIPT_TEMPLATE = `// Lowex 自建远程 JS 重写模板（Surge / Loon / QX / Shadowrocket / Stash HTTP 重写）
// 用法：把本文件放到你自己的 GitHub 仓库，在 App 里填 URL + 本文件的 SHA256。
// 下面是空实现（原样返回响应，不做任何修改），先验证链路能跑通，再按需改你自己的逻辑。
// 安全：不要从网上复制不明作者的重写脚本；任何改动都要重新算 SHA256 并更新 App 里的锁定值。
// 引用本文件的配置片段（按你所用客户端的文档格式粘贴，hostname 只写必需域名，绝不写 *）：
//   Surge: [Script] LowexNoop = type=http-response, pattern=^https://example\\.com/, requires-body=0, script-path=<本文件 URL>
//          [MITM] hostname = example.com
$done({});
`;
