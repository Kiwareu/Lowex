// ============================================================================
// 名称：Lowex 原创 · Mihomo DNS 防泄漏加固覆写
// 用途：Mihomo Party / Clash Verge Rev / FlClash 的配置级覆写脚本。
//       保守加固 DNS：只补缺、不覆盖——用户已有的值一律不动。
// 用法：把本文件放到你自己的 GitHub 仓库（或等本仓库合并到 main 后直接用
//       App「脚本库」里的链接），在客户端的「覆写 / 扩展脚本」里引用 URL，
//       并在引用处锁定本文件的 SHA256（作者更新后哈希变化即拒绝加载）。
// 安全提示：不要从网上复制不明作者的覆写脚本；任何改动都要重新计算 SHA256。
// ============================================================================

function main(config) {
  if (!config || typeof config !== 'object') return config;

  // 确保 dns 段存在；enable 强制为 true（DNS 关了等于裸奔）。
  if (!config.dns || typeof config.dns !== 'object') config.dns = {};
  var dns = config.dns;
  dns.enable = true;

  // —— 以下全部“缺才补”，用户已有值绝不覆盖 ——
  if (dns.listen == null) dns.listen = '127.0.0.1:1053';
  if (dns['default-nameserver'] == null) dns['default-nameserver'] = ['223.5.5.5', '119.29.29.29'];
  if (dns.nameserver == null)
    dns.nameserver = ['https://dns.alidns.com/dns-query', 'https://doh.pub/dns-query'];
  if (dns.fallback == null) dns.fallback = ['tls://1.0.0.1', 'tls://8.8.8.8'];

  // 防投毒过滤：只信任非 CN 答案。整段缺失才补，不合并进用户已有的 fallback-filter。
  if (dns['fallback-filter'] == null) {
    dns['fallback-filter'] = {
      geoip: true,
      'geoip-code': 'CN',
      ipcidr: [
        '240.0.0.0/4',
        '0.0.0.0/32',
        '10.0.0.0/8',
        '127.0.0.0/8',
        '172.16.0.0/12',
        '192.168.0.0/16',
        '100.64.0.0/10'
      ],
      domain: ['+.cn']
    };
  }

  // 绝不碰：ipv6 开关（dns.ipv6 / config.ipv6）与用户已有规则（config.rules）。
  return config;
}
