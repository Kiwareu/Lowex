import SwiftUI

/// 常用公共 DNS 目录 + 地址校验。校验按客户端能力：只放行当前客户端生成时真正能用的写法。
struct DnsServer: Identifiable {
    let id: String
    let name: String
    let url: String
    let overseas: Bool          // true = 海外（经代理访问）；false = 国内（直连）
    let note: String
}

enum DnsCatalog {
    static var cn: [DnsServer] { [
        DnsServer(id: "ali1", name: L("阿里 AliDNS 223.5.5.5"), url: "https://223.5.5.5/dns-query", overseas: false, note: L("IP 接入，无需 Bootstrap")),
        DnsServer(id: "ali2", name: L("阿里 AliDNS 223.6.6.6"), url: "https://223.6.6.6/dns-query", overseas: false, note: L("IP 接入，无需 Bootstrap")),
        DnsServer(id: "dnspod", name: L("腾讯 DNSPod doh.pub"), url: "https://doh.pub/dns-query", overseas: false, note: L("域名接入，需要 Bootstrap")),
        DnsServer(id: "qihoo", name: L("360 安全 DNS"), url: "https://doh.360.cn/dns-query", overseas: false, note: L("域名接入，作备选")),
    ] }
    static var remote: [DnsServer] { [
        DnsServer(id: "cf", name: "Cloudflare 1.1.1.1", url: "https://1.1.1.1/dns-query", overseas: true, note: L("海外，经代理访问")),
        DnsServer(id: "cf2", name: "Cloudflare 1.0.0.1", url: "https://1.0.0.1/dns-query", overseas: true, note: L("海外，经代理访问")),
        DnsServer(id: "google", name: "Google 8.8.8.8", url: "https://8.8.8.8/dns-query", overseas: true, note: L("海外，经代理访问")),
        DnsServer(id: "google2", name: "Google 8.8.4.4", url: "https://8.8.4.4/dns-query", overseas: true, note: L("海外，经代理访问")),
        DnsServer(id: "quad9", name: "Quad9 9.9.9.9", url: "https://9.9.9.9/dns-query", overseas: true, note: L("海外，带恶意域名过滤")),
        DnsServer(id: "adguard", name: "AdGuard DNS", url: "https://dns.adguard-dns.com/dns-query", overseas: true, note: L("海外，带广告过滤")),
    ] }
}

enum DnsValidator {
    /// 该客户端除 DoH 外还接受的写法。
    struct Caps { var dot: Bool; var plainIP: Bool }
    static func caps(family: String) -> Caps {
        switch family {
        case "mihomo", "stash": return Caps(dot: true, plainIP: true)
        case "singbox": return Caps(dot: true, plainIP: true)
        default: return Caps(dot: false, plainIP: false)   // Surge / Loon / Quantumult X / Egern / Shadowrocket：只写 DoH
        }
    }
    private static func isIPv4(_ s: String) -> Bool {
        let p = s.split(separator: ".", omittingEmptySubsequences: false)
        return p.count == 4 && p.allSatisfy { part in
            guard !part.isEmpty, let n = Int(part) else { return false }
            return (0...255).contains(n)
        }
    }
    private static func isIPv6(_ s: String) -> Bool {
        s.contains(":") && s.range(of: "^[0-9a-fA-F:]+$", options: .regularExpression) != nil && s.filter { $0 == ":" }.count >= 2
    }
    private static func isHost(_ s: String) -> Bool {
        if isIPv4(s) || isIPv6(s) { return true }
        return s.range(of: "^([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\\.)+[A-Za-z]{2,63}$", options: .regularExpression) != nil
    }
    /// 返回规范化后的地址；失败返回 nil 并给出原因。
    static func normalize(_ raw: String, family: String) -> (value: String?, error: String?) {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return (nil, L("地址不能为空。")) }
        let c = caps(family: family)
        if let r = s.range(of: "://") {
            let scheme = s[s.startIndex..<r.lowerBound].lowercased()
            let rest = String(s[r.upperBound...])
            let hostPort = rest.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
            let hp = String(hostPort.first ?? "")
            let host = hp.hasPrefix("[") ? hp : (hp.split(separator: ":").first.map(String.init) ?? "")
            guard isHost(host.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))) else { return (nil, L("主机名或 IP 格式不对。")) }
            switch scheme {
            case "https":
                let path = hostPort.count > 1 ? "/" + hostPort[1] : "/dns-query"
                return ("https://\(hp)\(path)", nil)
            case "tls":
                if !c.dot { return (nil, L("此客户端只接受 DoH 地址（https://…）。")) }
                return ("tls://\(hp)", nil)
            default:
                return (nil, L("不支持的协议，请使用 https:// 的 DoH 地址。"))
            }
        }
        // 没有协议头：IP 或域名
        if isIPv4(s) || isIPv6(s) {
            if c.plainIP { return (s, nil) }
            return (nil, L("此客户端只接受 DoH 地址（https://…）。"))
        }
        if isHost(s) { return ("https://\(s)/dns-query", nil) }   // 裸域名按 DoH 处理
        return (nil, L("格式不对：可填 https://… 的 DoH 地址、IP 或域名。"))
    }
}

/// 一组 DNS 地址的编辑器：常用服务器多选 + 自定义地址（带校验）。
struct DnsListEditor: View {
    @EnvironmentObject var store: Store
    let title: String
    let key: String                 // "dnsCn" | "dnsRemote"
    let catalog: [DnsServer]
    @State private var draft = ""
    @State private var error = ""

    private var list: [String] { (store.opts[key] as? [String]) ?? [] }
    private func write(_ l: [String]) {
        var patch: [String: Any] = [key: l]
        if key == "dnsCn" {
            let known: [(String, [String])] = [("ali-dnspod", ["https://223.5.5.5/dns-query", "https://doh.pub/dns-query"]),
                                               ("ali", ["https://223.5.5.5/dns-query", "https://223.6.6.6/dns-query"]),
                                               ("dnspod", ["https://doh.pub/dns-query"]), ("qihoo", ["https://doh.360.cn/dns-query"])]
            patch["dnsPreset"] = known.first { $0.1 == l }?.0 ?? "custom"
        }
        store.setOpts(patch)
    }
    private var custom: [String] { list.filter { u in !catalog.contains { $0.url == u } } }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Text(title).font(.subheadline.weight(.semibold))
            ForEach(catalog) { s in
                let on = list.contains(s.url)
                Button {
                    Haptics.selection()
                    var l = list
                    if on { l.removeAll { $0 == s.url } } else { l.append(s.url) }
                    if l.isEmpty { return }                       // 至少保留一个
                    write(l)
                } label: {
                    HStack(spacing: Space.s) {
                        Image(systemName: on ? "checkmark.circle.fill" : "circle").foregroundStyle(on ? Brand.pink : .secondary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(s.name).font(.footnote.weight(.medium)).foregroundStyle(Brand.ink)
                            Text(s.note).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Text(s.overseas ? L("海外") : L("国内")).font(.caption2.weight(.bold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background((s.overseas ? Brand.lilac : Brand.pink).opacity(0.18), in: Capsule())
                            .foregroundStyle(s.overseas ? Brand.lilac : Brand.pink)
                    }
                    .padding(.vertical, 4).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            ForEach(custom, id: \.self) { u in
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Brand.pink)
                    Text(u).font(.caption.monospaced()).lineLimit(1).truncationMode(.middle)
                    Spacer()
                    Button { var l = list; l.removeAll { $0 == u }; if !l.isEmpty { write(l) } } label: { Image(systemName: "trash").font(.caption) }
                        .buttonStyle(.plain).foregroundStyle(.red)
                }
            }
            HStack {
                TextField(L("自定义 DNS 地址"), text: $draft)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                Button(L("添加")) {
                    let r = DnsValidator.normalize(draft, family: store.family)
                    if let v = r.value {
                        error = ""; draft = ""
                        if !list.contains(v) { write(list + [v]) }
                    } else { error = r.error ?? "" }
                }
                .buttonStyle(.borderedProminent).tint(Brand.pink)
                .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if !error.isEmpty { Text(error).font(.caption2).foregroundStyle(.red) }
        }
    }
}
