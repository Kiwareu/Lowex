/** 远程覆写 / 脚本重写（9.8+）：独立模块，与"生成配置文件"互斥独立，不写进配置文件。
 *
 *  三种类型，绝不混用，按客户端 gating。核实来源：
 *  - config-override（覆写配置链接 .yaml）：在客户端的「覆写 / Override」里添加远程 .yaml 链接。
 *    ClashMi：官方手册（clashmi.app/guide：我的配置 → ＋ → 添加配置链接）+ 用户截图实证；
 *    Clash Verge Rev / Mihomo Party / FlClash：各自官方仓库文档的覆写（Override）说明。
 *    Stash 另有自家 .stoverride 格式（stash.wiki/en/configuration/override），与 Mihomo 系
 *    YAML 覆写（prepend-/append- merge 键）不通用，故 Stash 不在此列。
 *  - config-overwrite（配置级 JS 覆写 .js）：脚本收到完整 config 对象，返回修改后的 config。
 *    Mihomo Party / Clash Verge Rev 的 script.js（V8），FlClash 的脚本覆写（scriptId，
 *    chen08209/FlClash DeepWiki Profile Management）；ClashMi：覆写支持 JS 类型
 *    （核心设置 → 覆写 → ＋ → 添加配置链接 → 选 JS 类型；加完后把该覆写的「覆写方式」
 *    改为「内置-覆写」才会生效——来源：Perfect-Rules 第三方教程 README + 视频
 *    https://youtu.be/jmJiyDSmZE0，2026-10-20 核实；非官方文档，步骤与用户截图的覆写 UI 一致）。
 *  - http-rewrite（HTTP 重写 .js + MITM）：http-request / http-response 脚本 + MITM。
 *    Surge / Loon / Quantumult X / Shadowrocket / Stash 为 Surge 系脚本写法；
 *    Egern 官方文档确认支持 URL 重写 + JavaScript + MITM（egernapp.com/docs），
 *    但脚本 API 与 Surge 系不同，按 Egern 自家语法写，本站模板只给 Surge 系写法。
 *  sing-box 不支持 JS（无脚本能力）；其余客户端未核实，一律不提供——绝不越界。
 *
 *  安全红线（校验器强制执行）：仅 https；.js 类型链接必须 .js 结尾，覆写链接必须 .yaml/.yml
 *  结尾；SHA256 锁定可选——填了就强制校验（作者更新即提示），不填则放行但常显「未锁定」
 *  警告，只用信任的来源；第三方分享脚本由用户自行核验来源（脚本库标注出处）；
 *  MITM hostname 绝不写 *；含付费绕过关键词的脚本直接拒绝；
 *  敏感域名（银行/支付/社交账号）需用户显式确认。
 */
import {CLIENTS} from '../data/clients';

export type RemoteJsKind = 'config-override' | 'config-overwrite' | 'http-rewrite';
export const REMOTE_JS_KINDS: RemoteJsKind[] = ['config-override', 'config-overwrite', 'http-rewrite'];
/** 每种类型支持的客户端 id（见文件头核实来源注释） */
export const REMOTE_JS_KIND_CLIENTS: Record<RemoteJsKind, string[]> = {
  'config-override': ['clashmi', 'verge', 'clashparty', 'flclash'],
  'config-overwrite': ['clashmi', 'clashparty', 'verge', 'flclash'],
  'http-rewrite': ['surge', 'loon', 'qx', 'shadowrocket', 'stash', 'egern'],
};
/** 客户端中文显示名（用于「支持的客户端」提示） */
export const REMOTE_JS_CLIENT_NAMES: Record<string, string> = {
  clashmi: 'ClashMi', verge: 'Clash Verge Rev', clashparty: 'Mihomo Party', flclash: 'FlClash',
  surge: 'Surge', loon: 'Loon', qx: 'Quantumult X', shadowrocket: 'Shadowrocket',
  stash: 'Stash', egern: 'Egern',
};
export const REMOTE_JS_KIND_ZH: Record<RemoteJsKind, string> = {
  'config-override': '覆写配置链接',
  'config-overwrite': '配置级 JS 覆写',
  'http-rewrite': 'HTTP 重写',
};
export interface RemoteJsKindInfo {
  kind: RemoteJsKind;
  supported: boolean;
  /** 支持时=用法说明；不支持时=原因 + 支持的客户端名单 */
  note: string;
  /** 该类型支持的客户端中文名 */
  supporters: string[];
}
export interface RemoteJsSupport { kinds: RemoteJsKindInfo[]; anySupported: boolean }
function kindNote(kind: RemoteJsKind, clientId: string, ok: boolean): string {
  const names = REMOTE_JS_KIND_CLIENTS[kind].map(id => REMOTE_JS_CLIENT_NAMES[id] || id);
  if (ok) {
    if (kind === 'config-override') return '在该客户端的「覆写 / Override」里添加 .yaml 链接即可（以客户端内实际入口为准）';
    if (kind === 'config-overwrite') return clientId === 'clashmi'
      ? '在「核心设置 → 覆写」里添加配置链接并选 JS 类型；加完后把该覆写的「覆写方式」改为「内置-覆写」，否则可能不生效'
      : '脚本收到完整 config 对象，返回修改后的 config（.js，以客户端文档为准）';
    return clientId === 'egern'
      ? '支持 URL 重写 + JavaScript + MITM（官方文档确认），但脚本 API 与 Surge 系不同，按 Egern 自家语法写'
      : '支持 http-request / http-response 脚本 + MITM（.js，以客户端文档为准）';
  }
  const extra = (kind === 'config-override' && clientId === 'stash')
    ? 'Stash 用自家 .stoverride 格式，与此处的 YAML 覆写不通用。' : '';
  return `该客户端不支持${REMOTE_JS_KIND_ZH[kind]}。${extra}支持的客户端：${names.join('、')}。`;
}
/** 按客户端 id gating（不是按家族：同一家族的不同 App 支持情况不同）。返回三种类型的各自支持情况。 */
export function remoteJsSupport(clientId: string): RemoteJsSupport {
  const kinds = REMOTE_JS_KINDS.map(k => {
    const supporters = REMOTE_JS_KIND_CLIENTS[k];
    const ok = supporters.includes(clientId);
    return {
      kind: k, supported: ok, note: kindNote(k, clientId, ok),
      supporters: supporters.map(id => REMOTE_JS_CLIENT_NAMES[id] || id),
    };
  });
  return { kinds, anySupported: kinds.some(k => k.supported) };
}

export interface RemoteJsInput { kind: RemoteJsKind; url: string; sha256: string; name?: string; mitmHosts?: string[]; confirmSensitive?: boolean; content?: string }
export interface RemoteJsCheck { blocked: string[]; warns: string[] }
const PAID_BYPASS = ['破解', '绕过付费', '解锁会员', '解锁付费', '去付费', '激活码', '授权破解', 'crack', 'bypass paywall', '付费解锁'];
const SENSITIVE = ['alipay', 'wechat', 'weixin', 'tenpay', 'unionpay', 'paypal', 'icloud', 'bank', 'wallet'];
/** 校验远程覆写引用。blocked 非空 = 拒绝使用；warns = 提醒（不拦截），用户确认来源可信后可继续。 */
export function validateRemoteJs(input: RemoteJsInput): RemoteJsCheck {
  const blocked: string[] = []; const warns: string[] = [];
  const kind: RemoteJsKind = (input.kind as RemoteJsKind) || 'config-overwrite';
  const url = (input.url || '').trim();
  if (!/^https:\/\//i.test(url)) blocked.push('远程覆写只允许 https 链接');
  if (kind === 'config-override') {
    if (!/\.ya?ml(\?.*)?$/i.test(url)) blocked.push('覆写配置链接必须以 .yaml / .yml 结尾');
    if ((input.sha256 || '').trim()) warns.push('覆写配置链接不需要 SHA256 锁定（该字段已忽略）');
    if ((input.mitmHosts || []).some(h => h.trim())) warns.push('覆写配置链接不需要 MITM hostname（已忽略）');
  } else {
    if (!/\.js(\?.*)?$/i.test(url)) blocked.push('远程 JS 链接必须以 .js 结尾');
    const sha = (input.sha256 || '').trim();
    if (!sha) warns.push('未填写 SHA256 锁定：作者更新脚本后 App 不会察觉。只用你信任的来源；要锁定就去脚本库复制带哈希的版本');
    else if (!/^[0-9a-f]{64}$/i.test(sha)) blocked.push('SHA256 格式错误：应为 64 位 hex；不填则留空');
    if (kind === 'http-rewrite') {
      for (const h of input.mitmHosts || []) {
        const host = h.trim();
        if (!host) continue;
        if (host.includes('*')) warns.push(`MITM hostname「${host}」含通配符 *：必须只写该脚本必需的域名，绝不写 *`);
        if (SENSITIVE.some(s => host.toLowerCase().includes(s)) && !input.confirmSensitive)
          warns.push(`MITM hostname「${host}」涉及敏感域名（支付/账号类），需你显式确认后才可继续`);
      }
    } else if ((input.mitmHosts || []).some(h => h.trim())) {
      warns.push('配置级 JS 覆写不需要 MITM hostname（该字段已忽略）');
    }
  }
  const hay = `${input.name || ''} ${url} ${input.content || ''}`.toLowerCase();
  for (const k of PAID_BYPASS) if (hay.includes(k.toLowerCase())) blocked.push(`含付费绕过关键词「${k}」，拒绝使用`);
  return { blocked, warns };
}

/** 覆写配置链接模板（.yaml）：放到你自己的 GitHub 仓库，在客户端的「覆写 / Override」里添加本文件 URL。
 *  只补 DNS（fill-missing 思路：只补没有的，不动你原有配置）；规则按需取消注释。
 *  注意：Stash 不吃这套 merge 键，它用自家 .stoverride 格式。 */
export const OVERRIDE_YAML_TEMPLATE = `# Lowex 覆写配置链接模板（ClashMi / Clash Verge Rev / Mihomo Party / FlClash）
# 用法：本文件放到你自己的 GitHub 仓库 → 在客户端「覆写 / Override」里添加本文件的 URL → 启用。
# 下面只补 DNS，不动你原有规则；需要加规则时取消对应行的注释。
dns:
  enable: true
  ipv6: false
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  nameserver:
    - https://223.5.5.5/dns-query
    - https://doh.pub/dns-query
#prepend-rules:
#  - DOMAIN-SUFFIX,example.com,DIRECT
`;

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
