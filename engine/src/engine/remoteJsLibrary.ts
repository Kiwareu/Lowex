/** 远程脚本库（9.8+）：App 内「脚本库」分享区的数据层。
 *
 *  用户需求（2026-10-20）：App 内建脚本库——原创脚本给链接（带 SHA256 锁定/校验），
 *  分享别人的脚本直接给链接让用户一键复制，并标注来源；复制即用，不必在 App 里生成校验。
 *  脚本库不只是 .js：还包括覆写配置链接（.yaml），像 ClashMi「覆写 → 添加配置链接」那样。
 *
 *  三种类型，按客户端 gating，绝不混用：
 *  - config-overwrite（Mihomo 系配置级 JS 覆写）：仅 clashparty / verge / flclash。
 *  - http-rewrite（Surge 系 HTTP 重写 .js）：仅 surge / loon / qx / shadowrocket / stash。
 *  - config-override（覆写配置链接 .yaml）：经核实支持 merge 键
 *    （prepend-rules / append-rules / prepend-proxies / append-proxies /
 *     prepend-proxy-groups / append-proxy-groups，dns 等整段替换）的 Mihomo 系客户端：
 *    clashmi（官方手册「我的配置 → 添加配置链接」）、verge（Merge 类型覆写）、
 *    clashparty、flclash（profile 详情里的覆写入口）。
 *    Stash 的 Override 已核实存在，但用的是另一套语法（.stoverride + #!append /
 *    #!replace 注释），与 Mihomo merge 键不兼容——本仓库的 Mihomo 覆写 YAML
 *    不适用于 Stash，暂不收录 Stash 条目，由用户自行添加。
 *    Surge / Loon / QX / Shadowrocket 的等价机制（托管配置/远程资源/模块订阅）
 *    未在时限内核实，留空由用户自行添加。
 *  - sing-box 不支持；egern 的 HTTP 重写已按官方文档核实（URL 重写 + JavaScript + MITM），但脚本 API 与 Surge 系不同，种子里的 Surge 写法脚本不对 egern 提供。
 *
 *  安全红线（硬编码种子只放两类）：
 *  - 自建脚本：本仓库 remote-scripts/ 下的文件，走
 *    https://raw.githubusercontent.com/Kiwareu/Lowex/main/…（用户可自己 fork 后替换域名）；
 *  - 格式示例空条目：url 为空，仅说明“请替换为你已核验过的脚本”。
 *  绝不硬编码任何未核验的第三方脚本 URL（含视频博主分享的链接）。
 */
export type LibraryKind = 'config-overwrite' | 'http-rewrite' | 'config-override';
export type LibrarySourceKind = 'original' | 'shared';
export interface LibrarySource {
  kind: LibrarySourceKind;
  author: string;      // 原创=作者名；分享=脚本原作者/来源方
  authorUrl?: string;   // 可选：原作者主页（仅已核验时才填）
  note?: string;       // 备注
}
export interface LibraryEntry {
  id: string;
  name: string;
  kind: LibraryKind;
  /** 适用客户端 id；空数组 = 不按客户端过滤（仅当未选择客户端筛选时展示，如示例条目） */
  clients: string[];
  url: string;
  /** SHA256 锁定（64 位 hex）；空 = 未锁定，App 会显示橙色提示。
   *  config-override（yaml 覆写链接）在代理软件里直接添加，不走 App 内校验。 */
  sha256: string;
  source: LibrarySource;
  desc: string;
  updated: string;     // YYYY-MM-DD
  /** true = 文件还在分支上、main 上暂时没有：链接要等合并到 main 后才生效 */
  pendingMerge?: boolean;
}

/** 种子数据。注意：原创条目的 url 指向 main 分支的 raw 链接——在分支合并到 main
 *  之前会 404（pendingMerge），SHA256 已按文件内容填好，合并后哈希不变。
 *  第三方分享条目（shared）由用户指定收录：仅标注来源与出处，不做哈希锁定，
 *  由用户自行核验来源可信度。
 *  （2026-10-20：分支已合并到 main，原创条目的 raw 链接生效，pendingMerge 标记已移除。） */
const SEED: LibraryEntry[] = [
  {
    id: 'lowex-mihomo-dns-fix',
    name: 'Lowex 原创 · Mihomo DNS 防泄漏加固覆写',
    kind: 'config-overwrite',
    clients: ['clashmi', 'clashparty', 'verge', 'flclash'],
    url: 'https://raw.githubusercontent.com/Kiwareu/Lowex/main/remote-scripts/mihomo-dns-leak-fix.js',
    sha256: '96841d9b0705d667a83f800b2f8785677e53b65d63af6c4d2ed4075a2992b90f', // remote-scripts/mihomo-dns-leak-fix.js
    source: { kind: 'original', author: 'Lowex', note: '仓库自建：remote-scripts/mihomo-dns-leak-fix.js' },
    desc: '配置级 JS 覆写：只补缺不覆盖，补齐 DNS 开关/监听/国内外分流与防投毒过滤，绝不碰 IPv6 与已有规则。',
    updated: '2026-10-20',
  },
  {
    id: 'lowex-surge-noop',
    name: 'Lowex 原创 · Surge 系空重写脚本（自建起点）',
    kind: 'http-rewrite',
    clients: ['surge', 'loon', 'qx', 'shadowrocket', 'stash'],
    url: 'https://raw.githubusercontent.com/Kiwareu/Lowex/main/remote-scripts/surge-noop.js',
    sha256: 'acc5c0f497591cf56012a5e577ee7b4eecab91f55ab67ef423739b29455db141', // remote-scripts/surge-noop.js
    source: { kind: 'original', author: 'Lowex', note: '仓库自建：remote-scripts/surge-noop.js' },
    desc: '空实现重写脚本（$done({})），先验证引用链路跑通，再按注释示例改自己的逻辑。',
    updated: '2026-10-20',
  },
  {
    id: 'lowex-mihomo-override-yaml',
    name: 'Lowex 优化版 · Mihomo 覆写配置（DNS 防泄漏 + 精确 fallback）',
    kind: 'config-override',
    clients: ['clashmi', 'verge', 'clashparty', 'flclash'],
    url: 'https://raw.githubusercontent.com/Kiwareu/Lowex/main/remote-scripts/mihomo-override-dns-rules.yaml',
    sha256: '', // yaml 覆写链接在代理软件的「覆写 / Override」里直接添加，不走 App 内校验
    source: { kind: 'original', author: 'Lowex', note: '仓库自建：remote-scripts/mihomo-override-dns-rules.yaml，基于 Lowex 9.8+ 分析优化' },
    desc: '覆写配置链接：DNS 防泄漏整段 + fallback 精确化注释 + 分流规则骨架。在代理软件的「覆写 / Override」里添加配置链接即可。',
    updated: '2026-10-20',
  },
  {
    id: 'chunlion-dns-leak-full',
    name: '分享 · Chunlion DNS 防泄漏 + 完整分流（43 策略组）',
    kind: 'config-overwrite',
    clients: ['clashparty', 'verge', 'flclash'],
    url: 'https://raw.githubusercontent.com/Chunlion/Clash_Rule-Set/main/Chunlion_Rule-Set_DNS-Leak.js',
    sha256: '',
    source: { kind: 'shared', author: 'Chunlion', authorUrl: 'https://github.com/Chunlion/Clash_Rule-Set', note: '2026-10-20 已审查：无网络外发、无窃密；规则源为 MetaCubeX 官方 meta-rules-dat、anti-ad、666OS 等可信源；会覆写端口为 7893、开启 TUN、面板 secret 默认为 123456（仅本机）；作者更新后行为可能变化，未做哈希锁定' },
    desc: '配置级 JS 覆写：给已有订阅一键注入 DNS 防泄漏（Fake-IP + 分流）与 43 个策略组（流媒体/AI/金融/游戏等）。在客户端的覆写/脚本里添加此链接。',
    updated: '2026-10-20',
  },
  {
    id: 'chunlion-dns-leak-lite',
    name: '分享 · Chunlion DNS 防泄漏 + 轻量分流（24 策略组）',
    kind: 'config-overwrite',
    clients: ['clashparty', 'verge', 'flclash'],
    url: 'https://raw.githubusercontent.com/Chunlion/Clash_Rule-Set/main/Chunlion_Rule-Set_DNS-Leak_Lite.js',
    sha256: '',
    source: { kind: 'shared', author: 'Chunlion', authorUrl: 'https://github.com/Chunlion/Clash_Rule-Set', note: '2026-10-20 已审查：同完整版，策略组精简到 24 个，适合节点多或低资源设备；未做哈希锁定' },
    desc: '轻量版覆写：保留核心 DNS 防泄漏与常用服务分流，规则源更少、后台更轻。',
    updated: '2026-10-20',
  },
  {
    id: 'perfect-rules-clashmi',
    name: '分享 · Perfect Rules ClashMi 一键覆写（完美分流 + DNS 防泄漏）',
    kind: 'config-overwrite',
    clients: ['clashmi'],
    url: 'https://raw.githubusercontent.com/n0de-sudo/Perfect-Rules/refs/heads/main/Clash/Clash_mi.js',
    sha256: '',
    source: { kind: 'shared', author: 'n0de-sudo（阿尔忒弥斯实验室）', authorUrl: 'https://github.com/n0de-sudo/Perfect-Rules', note: '2026-10-20 全文审查（1957 行）：无网络外发、无窃密、无付费绕过、无硬编码订阅；URL 仅公共 DoH、generate_204 与作者自有规则仓库；DNS 国内外分流 + fallback-filter 规范。注意：会接管基础配置（mixed-port 固定 7890 等），保留机场原有分组并动态生成地区组；作者更新不受哈希锁定；README 含机场推广，脚本本身无推广代码。ClashMi 用法：覆写选 JS 类型，覆写方式改「内置-覆写」' },
    desc: '配置级 JS 覆写：给机场订阅一键注入完美分流（国内直连/海外代理/AI/YouTube/广告拦截）+ DNS 防泄漏 + 动态地区分组。在 ClashMi「核心设置 → 覆写」里添加配置链接并选 JS 类型。',
    updated: '2026-10-20',
  },
  {
    id: 'example-shared',
    name: '示例：收藏的第三方覆写配置（请替换）',
    kind: 'config-override',
    clients: [],
    url: '',
    sha256: '',
    source: { kind: 'shared', author: '', note: '示例条目：替换为你已核验过的覆写配置并写明作者' },
    desc: '这是格式示例：url 留空。在「添加我的收藏」里填入你已核验过的覆写配置链接、作者与来源标注。',
    updated: '2026-10-20',
  },
];

/** 按客户端过滤脚本库。clientId 为空时返回全部（含 clients 为空的示例条目）；
 *  非空时只保留 clients 包含该 id 的条目（示例条目此时不展示）。 */
export function libraryList(clientId: string): LibraryEntry[] {
  const c = (clientId || '').trim();
  if (!c) return SEED.slice();
  return SEED.filter(e => e.clients.includes(c));
}

/** 复制给别人的来源标注文本。text 格式：
 *  「名字」
 *  链接：url
 *  来源：作者（原创/分享）
 *  SHA256：前12位…（或“未锁定”） */
export function libraryAttribution(id: string): { url: string; text: string } {
  const e = SEED.find(x => x.id === id);
  if (!e) return { url: '', text: '未知脚本' };
  const srcLabel = e.source.kind === 'original' ? '原创' : '分享';
  const author = e.source.author || '（待填写）';
  const sha = e.sha256 ? `${e.sha256.slice(0, 12)}…` : '未锁定';
  const text = `「${e.name}」\n链接：${e.url || '（待填写）'}\n来源：${author}（${srcLabel}）\nSHA256：${sha}`;
  return { url: e.url, text };
}
