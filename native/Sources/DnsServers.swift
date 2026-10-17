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

/// 一组 DNS 的「摘要行」：只显示最有代表性的一项，点开后在弹层里多选其他常用服务器。
struct DnsRow: View {
    @EnvironmentObject var store: Store
    let title: String, hint: String, key: String, catalog: [DnsServer]
    @State private var showPicker = false
    private var list: [String] { (store.opts[key] as? [String]) ?? [] }
    private var summary: String {
        let picked = catalog.filter { list.contains($0.url) }
        let extra = list.filter { u in !catalog.contains { $0.url == u } }.count
        let n = picked.count + extra
        guard let first = picked.first else { return extra > 0 ? L("自定义 {} 项", extra) : L("未选择") }
        return n > 1 ? L("{} 等 {} 项", first.name, n) : first.name
    }
    var body: some View {
        Button { showPicker = true } label: {
            HStack(spacing: Space.s) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.ink)
                    Text(hint).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                }
                Spacer(minLength: Space.s)
                Text(summary).font(.footnote).foregroundStyle(Brand.pink).lineLimit(1).minimumScaleFactor(0.8)
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(Brand.pink.opacity(0.8))
            }
            .frame(minHeight: 40).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            DnsPickerSheet(title: title, key: key, catalog: catalog).environmentObject(store)
        }
    }
}

/// 弹层：多选常用服务器（至少保留一项）；自己添加的地址可在这里删除。
struct DnsPickerSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.presentationMode) private var pm
    let title: String, key: String, catalog: [DnsServer]
    private var list: [String] { (store.opts[key] as? [String]) ?? [] }
    private var custom: [String] { list.filter { u in !catalog.contains { $0.url == u } } }
    private func write(_ l: [String]) {
        guard !l.isEmpty else { return }
        var patch: [String: Any] = [key: l]
        if key == "dnsCn" {
            let known: [(String, [String])] = [("ali-dnspod", ["https://223.5.5.5/dns-query", "https://doh.pub/dns-query"]),
                                               ("ali", ["https://223.5.5.5/dns-query", "https://223.6.6.6/dns-query"]),
                                               ("dnspod", ["https://doh.pub/dns-query"]), ("qihoo", ["https://doh.360.cn/dns-query"])]
            patch["dnsPreset"] = known.first { $0.1 == l }?.0 ?? "custom"
        }
        store.setOpts(patch)
    }
    var body: some View {
        NavStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.s) {
                    Text(L("可多选，至少保留一项。生成时按勾选顺序使用。")).font(.caption).foregroundStyle(.secondary)
                    ForEach(catalog) { s in
                        let on = list.contains(s.url)
                        Button {
                            Haptics.selection()
                            var l = list
                            if on { l.removeAll { $0 == s.url } } else { l.append(s.url) }
                            write(l)
                        } label: {
                            HStack(spacing: Space.s) {
                                Image(systemName: on ? "checkmark.circle.fill" : "circle").foregroundStyle(on ? Brand.pink : .secondary)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(s.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.ink)
                                    Text(s.note).font(.caption2).foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0)
                                Text(s.overseas ? L("海外") : L("国内")).font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background((s.overseas ? Brand.lilac : Brand.pink).opacity(0.18), in: Capsule())
                                    .foregroundStyle(s.overseas ? Brand.lilac : Brand.pink)
                            }
                            .padding(Space.m).frame(maxWidth: .infinity, alignment: .leading)
                            .softCard().contentShape(Rectangle())
                        }.buttonStyle(.plain)
                    }
                    if !custom.isEmpty {
                        Text(L("自己添加的")).font(.footnote.weight(.semibold)).foregroundStyle(.secondary).padding(.top, Space.s)
                        ForEach(custom, id: \.self) { u in
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Brand.pink)
                                Text(u).font(.caption.monospaced()).lineLimit(1).truncationMode(.middle)
                                Spacer()
                                Button { var l = list; l.removeAll { $0 == u }; write(l) } label: { Image(systemName: "trash").font(.caption) }
                                    .buttonStyle(.plain).foregroundStyle(.red)
                            }
                            .padding(Space.m).softCard()
                        }
                    }
                }
                .padding(Space.l)
            }
            .background(PinkBackground())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L("完成")) { pm.wrappedValue.dismiss() } } }
        }
    }
}

/// 高级：自定义 DNS 地址 + Bootstrap。默认折叠。
struct DnsAdvanced: View {
    @EnvironmentObject var store: Store
    @State private var target = "dnsCn"
    @State private var draft = ""
    @State private var error = ""
    @State private var boot = ""
    @FocusState private var bootFocus: Bool

    private func add() {
        let r = DnsValidator.normalize(draft, family: store.family)
        guard let v = r.value else { error = r.error ?? ""; return }
        error = ""; draft = ""
        var l = (store.opts[target] as? [String]) ?? []
        if !l.contains(v) { l.append(v) }
        var patch: [String: Any] = [target: l]
        if target == "dnsCn" { patch["dnsPreset"] = "custom" }
        store.setOpts(patch)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            VStack(alignment: .leading, spacing: Space.xs) {
                Text(L("自定义 DNS 服务器")).font(.subheadline.weight(.semibold))
                Text(L("填你自己的 DNS 服务器，例如自建或公司提供的 DoH 地址（https://…）、DoT 地址（tls://…）或 IP。它会和上面勾选的服务器一起使用，不会替换它们；想只用自己的，请先在列表里取消其他项。"))
                    .font(.caption2).foregroundStyle(.secondary)
                if store.supports("dnsRemote") {
                    ChoiceTabs(options: [("dnsCn", L("用于国内域名")), ("dnsRemote", L("用于海外域名"))], selection: $target)
                }
                HStack {
                    TextField("https://dns.example.com/dns-query", text: $draft)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                        .padding(.horizontal, 10).padding(.vertical, 8)
                        .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Button(L("添加"), action: add)
                        .buttonStyle(.borderedProminent).tint(Brand.pink)
                        .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                if !error.isEmpty { Text(error).font(.caption2).foregroundStyle(.red) }
            }
            if store.supports("dnsBootstrap") {
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text(L("Bootstrap DNS")).font(.subheadline.weight(.semibold))
                    Text(L("只用来解析 DoH / DoT 服务器自己的域名（例如 doh.pub）的普通 IP DNS，和你用什么网络、选了哪个 DNS 都无关，一般保持默认即可。只能写 IP，逗号分隔。"))
                        .font(.caption2).foregroundStyle(.secondary)
                    TextField("223.5.5.5, 119.29.29.29", text: Binding(
                        get: { bootFocus ? boot : ((store.opts["dnsBootstrap"] as? [String]) ?? []).joined(separator: ", ") },
                        set: { boot = $0 }))
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .keyboardType(.numbersAndPunctuation)
                        .focused($bootFocus)
                        .padding(.horizontal, 10).padding(.vertical, 8)
                        .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .onChangeValue(of: bootFocus) { f in
                            if f { boot = ((store.opts["dnsBootstrap"] as? [String]) ?? []).joined(separator: ", ") }
                            else {
                                let list = boot.split(whereSeparator: { ", ，\n".contains($0) }).map(String.init)
                                    .filter { $0.range(of: "^[0-9a-fA-F:.]+$", options: .regularExpression) != nil }
                                if !list.isEmpty { store.setOpts(["dnsBootstrap": list]) }
                            }
                        }
                }
            }
        }
    }
}
