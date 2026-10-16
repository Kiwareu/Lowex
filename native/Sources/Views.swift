import SwiftUI
import UIKit

// MARK: - 首页
struct HomeView: View {
    @EnvironmentObject var store: Store
    private let networks = [
        ("mobile", "中国移动宽带"), ("telecom", "中国电信宽带"), ("unicom", "中国联通宽带"),
        ("cellular", "手机蜂窝数据"), ("campus", "校园网"), ("company", "公司网络"),
        ("overseas", "海外网络"), ("other", "其他 / 不确定")
    ]
    private let locations = [
        ("cn", "中国大陆"), ("hk", "香港"), ("mo", "澳门"), ("tw", "台湾"), ("overseas", "海外")
    ]

    var body: some View {
        PageChrome(showBrand: true) {
            Text(store.versionLabel).font(.caption2.monospaced()).foregroundStyle(.secondary)
            HeroCard {
                Text("代理配置生成器")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.ink)
                Text("Windows / iOS / Android · 选系统与客户端 → 节点 → 规则 → 生成。全部本机完成。")
                    .font(.footnote).foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    StepBadge(n: 1, label: "客户端", done: store.stepClientDone, active: store.activeStep == 1)
                    StepBadge(n: 2, label: "节点", done: store.stepNodesDone, active: store.activeStep == 2)
                    StepBadge(n: 3, label: "规则", done: store.stepRulesDone, active: store.activeStep == 3)
                    StepBadge(n: 4, label: "生成", done: store.stepGenerateDone, active: store.activeStep == 4)
                }
                .padding(.top, 4)
            }

            PlainCard {
                Text("① 选择系统与客户端").font(.headline)
                Text("先选目标设备系统，再选客户端。生成的规则只含该系统有效的内容，不会混入其他平台。")
                    .font(.caption).foregroundStyle(.secondary)
                PlatformSelector()
                ClientGrid()
                if let c = store.clientInfo {
                    if let b = c.blurb { Text(b).font(.caption).foregroundStyle(.secondary) }
                    if let h = c.importHint {
                        Text(h).font(.caption2).foregroundStyle(Brand.pink.opacity(0.9)).padding(.top, 2)
                    }
                    Text(c.embedsSubscription
                         ? "订阅模式：可将订阅 URL 写入配置文件"
                         : "订阅模式：节点/订阅需在客户端内添加或展开进文件，URL 不直接进配置")
                        .font(.caption2).foregroundStyle(.secondary)
                    Text("按应用分流：" + platformRuleText).font(.caption2).foregroundStyle(.secondary)
                }
            }

            CapMatrixCard()

            PlainCard {
                Text("配置名称").font(.headline)
                ProfileNameField()
            }

            PlainCard {
                Text("网络环境与所在地").font(.headline)
                Picker("网络", selection: Binding(get: { store.str("network") }, set: { store.set("network", $0) })) {
                    ForEach(networks, id: \.0) { Text($0.1).tag($0.0) }
                }.pickerStyle(.menu)
                Picker("所在地", selection: Binding(get: { store.str("location") }, set: { store.set("location", $0) })) {
                    ForEach(locations, id: \.0) { Text($0.1).tag($0.0) }
                }.pickerStyle(.menu)
                Button { store.applyRecommend() } label: {
                    Label("按环境智能推荐", systemImage: "wand.and.stars").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(Brand.pink)
                if !store.recommendNote.isEmpty {
                    Text(store.recommendNote).font(.footnote).foregroundStyle(.secondary)
                }
            }

            PlainCard {
                Text("一键预设").font(.headline)
                Text("对齐作者 Clash Meta v4 结构并加强：故障转移、防泄漏、数字游民银行与加密货币规则包。不含私人订阅。")
                    .font(.caption).foregroundStyle(.secondary)
                PresetButtons()
            }

            PlainCard {
                Text("② 生成选项（仅当前客户端支持）").font(.headline)
                OptToggle(title: "故障转移（地区故转组）", key: "failover", feature: "failover")
                if store.supports("failover") {
                    Text("开启后为每个地区生成「手动 / 自动 / 故转」：故转优先用手动，失败再落到自动测速。")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                if store.supports("ads") {
                    Picker("广告拦截", selection: Binding<String>(
                        get: { store.adsMode },
                        set: { store.setOpt("ads", $0) }
                    )) {
                        Text("关闭").tag("off")
                        Text("Lite").tag("lite")
                        Text("完整").tag("full")
                    }
                    .pickerStyle(.segmented)
                }
                OptToggle(title: "拦截追踪器", key: "trackers", feature: "trackers")
                OptToggle(title: "拦截遥测", key: "telemetry", feature: "telemetry")
                OptToggle(title: "策略组图标", key: "icons", feature: "icons")
                OptToggle(title: "关闭 IPv6（防泄漏）", key: "ipv6", feature: "ipv6", invert: true)
                OptToggle(title: "TUN 虚拟网卡", key: "tun", feature: "tun")
                OptToggle(title: "DNS fake-ip", key: "fakeIp", feature: "fakeIp")
                if store.supports("quic") {
                    Toggle("拦截境外 QUIC", isOn: Binding(
                        get: {
                            let v = store.opts["blockQuic"]
                            if let s = v as? String { return s != "off" }
                            return (v as? Bool) ?? true
                        },
                        set: { store.setOpt("blockQuic", $0 ? "foreign" : "off") }
                    )).tint(Brand.pink)
                }
                if store.supports("stun") {
                    Toggle("STUN / WebRTC 防护", isOn: Binding(
                        get: {
                            let v = store.opts["stun"]
                            if let s = v as? String { return s != "off" }
                            return (v as? Bool) ?? true
                        },
                        set: { store.setOpt("stun", $0 ? "proxy" : "off") }
                    )).tint(Brand.pink)
                }
                OptToggle(title: "允许局域网连接", key: "allowLan", feature: "allowLan")
                OptToggle(title: "Wi-Fi 通话规则", key: "wifiCalling", feature: "wifi")
                if store.supports("wifi") {
                    Text("打开后请到「规则」页选择运营商；规则会写入生成配置。")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }

            if !store.unsupportedOptionNames.isEmpty {
                Text("当前客户端不支持（已隐藏）：" + store.unsupportedOptionNames.joined(separator: "、"))
                    .font(.caption2).foregroundStyle(.secondary).padding(.horizontal, 4)
            }
            PlainCard {
                Button(role: .destructive) { store.restoreDefaults() } label: {
                    Label("恢复默认选项", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button { store.tab = .nodes } label: {
                Label("下一步：节点", systemImage: "arrow.right").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).tint(Brand.pink)
        }
    }
}

extension HomeView {
    var platformRuleText: String {
        switch store.platform {
        case "windows": return (store.clientInfo?.processRules ?? false) ? "支持 PROCESS-NAME（.exe 进程名）" : "此客户端不支持进程规则，将按域名 / 服务组"
        case "android": return (store.clientInfo?.processRules ?? false) || store.family == "mihomo" || store.family == "singbox" ? "支持按包名（Android 包名）" : "此客户端不支持包名规则，将按域名 / 服务组"
        default: return "iOS 无进程 / 包名规则，一律按域名 / 服务组"
        }
    }
}

struct CapMatrixCard: View {
    @EnvironmentObject var store: Store
    @State private var open = false
    var body: some View {
        PlainCard {
            Button { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { open.toggle() } } label: {
                HStack {
                    Text("能力矩阵 · \(store.clientInfo?.name ?? "")").font(.headline).foregroundStyle(Brand.ink)
                    Spacer()
                    Image(systemName: "chevron.down").rotationEffect(.degrees(open ? 180 : 0)).foregroundStyle(.secondary)
                }
            }.buttonStyle(.plain)
            if open {
                let caps = Set(store.clientInfo?.caps ?? [])
                LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], spacing: 6) {
                    ForEach(store.catalog.capList.filter { $0.id != "wifi" || store.isMobilePlatform }) { c in
                        let ok = caps.contains(c.id) && (c.id != "wifi" || store.isMobilePlatform)
                        Label(c.label, systemImage: ok ? "checkmark.circle.fill" : "xmark.circle")
                            .font(.caption2)
                            .foregroundStyle(ok ? Brand.pink : Color.secondary.opacity(0.7))
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                Text("灰色 = 该客户端的语法不支持，生成时自动省略。").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

struct PresetButtons: View {
    @EnvironmentObject var store: Store
    private let order = ["nomad", "crypto-pack", "antileak", "safe", "min", "stream", "dev", "ai"]
    var body: some View {
        let all = store.engine.presets()
        let list = order.compactMap { id in all.first { ($0["id"] as? String) == id } }
        ForEach(Array(list.enumerated()), id: \.offset) { _, pr in
            Button {
                if let id = pr["id"] as? String {
                    store.applyPreset(id)
                }
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(pr["name"] as? String ?? "")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.ink)
                    Text(pr["desc"] as? String ?? "")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

struct OptToggle: View {
    @EnvironmentObject var store: Store
    let title: String; let key: String; let feature: String; var invert = false
    var body: some View {
        if store.supports(feature) {
            Toggle(title, isOn: Binding(
                get: {
                    let defOn: Bool = {
                        if key == "ipv6" || key == "tun" || key == "allowLan" || key == "wifiCalling" { return false }
                        if key == "failover" { return true }
                        return true
                    }()
                    let v = (store.opts[key] as? Bool) ?? defOn
                    return invert ? !v : v
                },
                set: { store.setOpt(key, invert ? !$0 : $0) }
            ))
            .tint(Brand.pink)
        }
    }
}

// MARK: - 节点
struct NodesView: View {
    @EnvironmentObject var store: Store
    @State private var subDraft = ""
    @State private var linkDraft = ""
    @State private var editing: ManualNodeDraft?

    private var isSR: Bool { store.family == "shadowrocket" }
    private var isSB: Bool { store.family == "singbox" }
    /// 订阅区：只有能把订阅 URL 写进配置的客户端才显示
    private var showSubs: Bool { store.embedsSub }
    /// 节点链接区：Shadowrocket 的配置文件带不了节点链接
    private var showLinks: Bool { !isSR }
    private var hiddenNote: String? {
        if isSR { return "小火箭：配置无法携带订阅与节点链接，已隐藏这两块；请在小火箭 App 首页添加（右上角 + ）。手动节点会写进 conf 的 [Proxy]。" }
        if !showSubs { return "\(store.clientInfo?.name ?? "该客户端") 没有订阅字段，已隐藏订阅 URL 区；请把节点链接或 Base64 正文粘贴到下面，生成时展开写入。" }
        return nil
    }
    private func target(_ kind: String) -> String {
        switch store.family {
        case "mihomo": return kind == "sub" ? "proxy-providers" : "proxies"
        case "stash": return kind == "sub" ? "proxy-providers" : "proxies"
        case "surge": return kind == "sub" ? "[Proxy Group] 的 policy-path" : "[Proxy]"
        case "qx": return kind == "sub" ? "[server_remote]" : "[server_local]"
        case "loon": return kind == "sub" ? "[Remote Proxy]" : "[Proxy]"
        case "egern": return kind == "sub" ? "external 策略组" : "proxies"
        case "singbox": return "outbounds"
        default: return "配置文件"
        }
    }

    var body: some View {
        PageChrome(title: "节点") {
            HeroCard {
                Text("节点来源，可同时使用").font(.title3.weight(.semibold))
                Text("当前客户端：\(store.clientInfo?.name ?? "")。填写的内容会在生成时自动写入配置对应位置，导入文件即可用。")
                    .font(.footnote).foregroundStyle(.secondary)
                if let n = hiddenNote { Text(n).font(.caption2).foregroundStyle(.secondary) }
            }

            // A. 订阅 URL
            if showSubs { PlainCard {
                Label("① 订阅链接 URL", systemImage: "link").font(.headline)
                Text(subHelper).font(.caption).foregroundStyle(.secondary)
                inputBox($subDraft, placeholder: "https://example.com/sub?token=…\n可一行一个，多个订阅")
                HStack {
                    Button {
                        store.addSubscriptions(subDraft)
                        if !isSR { subDraft = "" }
                    } label: {
                        Label(isSR ? "复制到剪贴板" : "添加订阅", systemImage: isSR ? "doc.on.clipboard" : "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent).tint(Brand.pink)
                    .disabled(subDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if !store.subs.isEmpty {
                        Button("清空订阅", role: .destructive) { var s = store.state; s["subs"] = []; store.state = s }.buttonStyle(.bordered)
                    }
                }
                if !store.subs.isEmpty && !isSR {
                    ForEach(Array(store.subs.enumerated()), id: \.offset) { i, sub in
                        HStack {
                            Text(sub["url"] as? String ?? "").font(.caption2).lineLimit(1).truncationMode(.middle).foregroundStyle(.secondary)
                            Spacer()
                            Button { store.removeSub(i) } label: { Image(systemName: "trash").font(.caption) }.buttonStyle(.plain).foregroundStyle(.red)
                        }
                    }
                }
            }

            }
            // B. 节点链接
            if showLinks { PlainCard {
                Label(showSubs ? "② 节点链接 / Base64" : "① 节点链接 / Base64", systemImage: "text.alignleft").font(.headline)
                Text(linkHelper).font(.caption).foregroundStyle(.secondary)
                inputBox($linkDraft, placeholder: "ss://… vmess://… vless://… trojan://… hysteria2://… tuic://…\n每行一条，或整段 Base64")
                HStack {
                    Button {
                        store.applyPaste(linkDraft)
                        if !isSR { linkDraft = "" }
                    } label: {
                        Label(isSR ? "复制到剪贴板" : "写入方案", systemImage: isSR ? "doc.on.clipboard" : "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent).tint(Brand.pink)
                    .disabled(linkDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if !store.nodesText.isEmpty && !isSR {
                        Button("清空链接", role: .destructive) { store.clearNodeText() }.buttonStyle(.bordered)
                    }
                }
                if !store.nodesText.isEmpty && !isSR {
                    let lines = store.nodesText.split(whereSeparator: \.isNewline)
                    let n = lines.filter { $0.contains("://") }.count
                    Text("已写入 \(lines.count) 行" + (n > 0 ? "（约 \(n) 条链接）" : "")).font(.caption.weight(.medium))
                }
                if !store.pasteNote.isEmpty { Text(store.pasteNote).font(.footnote).foregroundStyle(Brand.pink) }
            }

            }
            // C. 手动节点
            manualCard

            PlainCard {
                Text("地区分组").font(.headline)
                Text("打开的地区会出现在规则出口与策略组里（含故转/自动/手动）。手动节点按名称里的地区关键词（如「香港」「日本」）归入对应地区。").font(.caption).foregroundStyle(.secondary)
                ForEach(store.catalog.regions) { r in
                    Toggle(isOn: Binding(get: { store.regions.contains(r.id) }, set: { _ in store.toggleRegion(r.id) })) {
                        HStack(spacing: 8) { RemoteIcon(url: r.icon, name: r.name, size: 22); Text(r.name) }
                    }.tint(Brand.pink)
                }
            }

            Button { store.tab = .rules } label: {
                Label("下一步：规则", systemImage: "arrow.right").frame(maxWidth: .infinity)
            }.buttonStyle(.borderedProminent).tint(Brand.pink)
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(item: $editing) { d in
            ManualNodeForm(draft: d).environmentObject(store)
        }
    }

    private var subHelper: String {
        "一行一个 URL，点「添加订阅」→ 下方列表可逐条删除。生成时写入 \(target("sub"))，由客户端自行更新节点。"
    }
    private var linkHelper: String {
        "支持 ss / vmess / vless / trojan / hysteria2 / tuic / anytls 链接（每行一条）或整段 Base64 订阅正文。点「写入方案」→ 生成时写入 \(target("link"))；客户端不支持的协议会跳过并提示。"
    }

    @ViewBuilder private var manualCard: some View {
        PlainCard {
            HStack {
                Label((showSubs ? "③ " : (showLinks ? "② " : "① ")) + "手动添加节点（SOCKS5 / HTTP / HTTPS）", systemImage: "network").font(.headline)
                Spacer()
            }
            Text("适合家宽 / 住宅代理套餐：点「添加节点」填名称、类型、主机、端口、账号密码，保存后生成时写入 \(isSR ? "[Proxy]" : target("link"))。名称里的地区词决定归入哪个地区；密码存本机钥匙串，不上传。")
                .font(.caption).foregroundStyle(.secondary)
            if let c = store.manualCaps {
                Text("当前客户端支持：SOCKS5 \(c.socks5 ? "✓" : "✗") · SOCKS5-TLS \(c.socks5tls ? "✓" : "✗") · HTTP \(c.http ? "✓" : "✗") · HTTPS \(c.https ? "✓" : "✗")")
                    .font(.caption2).foregroundStyle(Brand.pink)
            }
            ForEach(Array(store.manualNodes.enumerated()), id: \.offset) { _, m in
                let id = m["id"] as? String ?? ""
                let on = (m["on"] as? Bool) ?? true
                let issue = store.manualIssue(m)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(m["name"] as? String ?? "").font(.subheadline.weight(.semibold))
                            Text("\(kindLabel(m)) · \(m["host"] as? String ?? ""):\(String(describing: m["port"] ?? 0))" + (((m["user"] as? String) ?? "").isEmpty ? "" : " · 有账号"))
                                .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(get: { on }, set: { _ in store.toggleManual(id) })).labelsHidden().tint(Brand.pink)
                    }
                    if let issue, on { Label("当前客户端不会写入：\(issue)", systemImage: "exclamationmark.triangle.fill").font(.caption2).foregroundStyle(.orange) }
                    HStack(spacing: 14) {
                        Button("编辑") { editing = ManualNodeDraft(m) }
                        Button("删除", role: .destructive) { store.removeManual(id) }
                    }.font(.caption).buttonStyle(.plain).foregroundStyle(Brand.pink)
                }
                .padding(10).background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            Button { editing = ManualNodeDraft(nil) } label: {
                Label("添加节点", systemImage: "plus.circle.fill").frame(maxWidth: .infinity)
            }.buttonStyle(.borderedProminent).tint(Brand.pink)
            if store.manualBlockedCount > 0 {
                Text("有 \(store.manualBlockedCount) 个手动节点当前客户端写不出，生成时会跳过并在结果里提示。").font(.caption2).foregroundStyle(.orange)
            }
        }
    }

    private func kindLabel(_ m: [String: Any]) -> String {
        let tls = (m["tls"] as? Bool) ?? false
        return (m["kind"] as? String) == "http" ? (tls ? "HTTPS" : "HTTP") : (tls ? "SOCKS5-TLS" : "SOCKS5")
    }

    private func inputBox(_ text: Binding<String>, placeholder: String) -> some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: text)
                .frame(minHeight: 96)
                .scrollContentBackground(.hidden)
                .font(.system(.footnote, design: .monospaced))
                .autocorrectionDisabled().textInputAutocapitalization(.never)
                .padding(8)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            if text.wrappedValue.isEmpty {
                Text(placeholder).font(.system(.footnote, design: .monospaced)).foregroundStyle(.tertiary)
                    .padding(.horizontal, 13).padding(.vertical, 16).allowsHitTesting(false)
            }
        }
    }
}

struct ManualNodeDraft: Identifiable {
    let id: String
    var name = ""; var kind = "socks5"; var tls = false; var host = ""; var port = ""; var user = ""; var pass = ""; var on = true
    let isNew: Bool
    init(_ m: [String: Any]?) {
        isNew = m == nil
        id = (m?["id"] as? String) ?? UUID().uuidString
        guard let m else { return }
        name = m["name"] as? String ?? ""; kind = m["kind"] as? String ?? "socks5"; tls = (m["tls"] as? Bool) ?? false
        host = m["host"] as? String ?? ""; port = String(describing: m["port"] ?? ""); user = m["user"] as? String ?? ""
        pass = m["pass"] as? String ?? ""; on = (m["on"] as? Bool) ?? true
    }
    var dict: [String: Any] {
        ["id": id, "name": name.trimmingCharacters(in: .whitespaces), "kind": kind, "tls": tls, "host": host.trimmingCharacters(in: .whitespaces),
         "port": Int(port.trimmingCharacters(in: .whitespaces)) ?? 0, "user": user, "pass": pass, "on": on]
    }
}

struct ManualNodeForm: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State var draft: ManualNodeDraft
    @State private var showPass = false
    @State private var type = 0   // 0 SOCKS5, 1 HTTP, 2 HTTPS
    init(draft: ManualNodeDraft) {
        _draft = State(initialValue: draft)
        _type = State(initialValue: draft.kind == "http" ? (draft.tls ? 2 : 1) : 0)
    }
    private var issue: String? { store.manualIssue(draft.dict) }
    var body: some View {
        NavigationStack {
            Form {
                Section("名称（决定归入哪个地区）") {
                    TextField("例如 香港-住宅 / 日本-家宽", text: $draft.name)
                }
                Section("类型") {
                    Picker("类型", selection: $type) { Text("SOCKS5").tag(0); Text("HTTP").tag(1); Text("HTTPS").tag(2) }.pickerStyle(.segmented)
                    if type == 0 { Toggle("SOCKS5 over TLS", isOn: $draft.tls).tint(Brand.pink) }
                }
                Section("服务器") {
                    TextField("主机（域名或 IP）", text: $draft.host).textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    TextField("端口", text: $draft.port).keyboardType(.numberPad)
                }
                Section("账号（可留空）") {
                    TextField("用户名", text: $draft.user).textInputAutocapitalization(.never).autocorrectionDisabled()
                    HStack {
                        Group { if showPass { TextField("密码", text: $draft.pass) } else { SecureField("密码", text: $draft.pass) } }
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                        Button { showPass.toggle() } label: { Image(systemName: showPass ? "eye.slash" : "eye") }.buttonStyle(.plain)
                    }
                }
                Section {
                    if let issue { Label(issue, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange).font(.footnote) }
                    else { Label("当前客户端可以写入这个节点", systemImage: "checkmark.circle.fill").foregroundStyle(.green).font(.footnote) }
                    Text("密码保存在本机钥匙串（不可用时回退到 App 沙盒私有文件），不会上传。").font(.caption2).foregroundStyle(.secondary)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(draft.isNew ? "添加节点" : "编辑节点").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }.disabled(!canSave)
                }
            }
            .onChange(of: type) { _, t in draft.kind = t == 0 ? "socks5" : "http"; draft.tls = t == 2 ? true : (t == 1 ? false : draft.tls) }
        }
    }
    /// 基础字段齐全即可保存；客户端写不出的会在列表里提示，不阻止保存
    private var canSave: Bool {
        !draft.name.trimmingCharacters(in: .whitespaces).isEmpty && !draft.host.trimmingCharacters(in: .whitespaces).isEmpty
            && (Int(draft.port.trimmingCharacters(in: .whitespaces)).map { (1...65535).contains($0) } ?? false)
    }
    private func save() {
        var d = draft; d.kind = type == 0 ? "socks5" : "http"
        if type == 1 { d.tls = false }; if type == 2 { d.tls = true }
        store.upsertManual(d.dict); Haptics.success(); dismiss()
    }
}

// MARK: - 规则
struct RulesView: View {
    @EnvironmentObject var store: Store
    @State private var query = ""
    @State private var section: RuleSection = .groups
    @State private var onlyFav = false

    enum RuleSection: String, CaseIterable, Identifiable {
        case groups = "服务分组"
        case apps = "按 App"
        case domains = "自定义域名"
        case wifi = "Wi-Fi 通话"
        var id: String { rawValue }
    }

    var filteredGroups: [Catalog.Group] {
        var list = store.catalog.groups
        if onlyFav { list = list.filter { store.favoriteIds.contains($0.id) } }
        if query.isEmpty { return list }
        return list.filter {
            $0.name.localizedCaseInsensitiveContains(query) || $0.id.contains(query.lowercased())
        }
    }

    var body: some View {
        PageChrome(title: "规则") {
            HeroCard {
                Text("③ 分流与增强")
                    .font(.title3.weight(.semibold))
                Text(store.stepRulesHint + " · 选项会直接进入生成配置")
                    .font(.footnote).foregroundStyle(.secondary)
                Picker("分区", selection: $section) {
                    ForEach(RuleSection.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            switch section {
            case .groups:
                PlainCard {
                    TextField("搜索服务分组", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Toggle("只看收藏", isOn: $onlyFav).tint(Brand.pink)
                }
                ForEach(filteredGroups) { g in
                    groupRow(g)
                }
            case .apps:
                AppsInline()
            case .domains:
                DomainsInline()
            case .wifi:
                if store.supports("wifi") {
                    WifiInline()
                } else {
                    PlainCard {
                        Text("当前客户端不支持在配置里写 Wi-Fi 通话规则。")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }

            Button { store.tab = .generate } label: {
                Label("下一步：生成", systemImage: "sparkles").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).tint(Brand.pink)
        }
    }

    @ViewBuilder
    private func groupRow(_ g: Catalog.Group) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                RemoteIcon(url: g.icon, name: g.name, size: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(g.name).font(.subheadline.weight(.semibold))
                    Text(store.catalog.cats[g.cat] ?? g.cat).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    store.toggleFavorite(g.id)
                } label: {
                    Image(systemName: store.favoriteIds.contains(g.id) ? "star.fill" : "star")
                        .foregroundStyle(Brand.pink)
                }
                .buttonStyle(.plain)
                Toggle("", isOn: Binding(
                    get: { store.isOn(g) },
                    set: { store.setGroup(g, on: $0) }
                ))
                .labelsHidden()
                .tint(Brand.pink)
            }
            if store.isOn(g) {
                Picker("出口", selection: Binding(
                    get: { store.policy(g) },
                    set: { store.setGroup(g, policy: $0) }
                )) {
                    Text("代理").tag("PROXY")
                    Text("直连").tag("DIRECT")
                    Text("拦截").tag("REJECT")
                    ForEach(store.catalog.regions.filter { store.regions.contains($0.id) }) {
                        Text("\($0.name) 节点").tag("R:\($0.id)")
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding(12)
        .softCard()
    }
}

// MARK: - 生成


struct ProfileNameField: View {
    @EnvironmentObject var store: Store
    @State private var text = ""
    @FocusState private var focused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(store.profileNameIsCustom ? "自定义" : "自动")
                    .font(.caption2.weight(.bold)).foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(store.profileNameIsCustom ? Color.orange : Brand.pink, in: Capsule())
                Text(store.profileNameIsCustom ? "手动名称，不随客户端变化" : "随所选客户端自动变化").font(.caption2).foregroundStyle(.secondary)
            }
            // 未聚焦时永远直接显示 store 里的当前名字，避免本地缓存过期
            TextField("配置名称", text: Binding(get: { focused ? text : store.profileName }, set: { text = $0 }))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focused)
                .submitLabel(.done)
                .onSubmit { focused = false }
                .onChange(of: focused) { _, f in
                    if f { text = store.profileName } else { store.profileName = text }
                }
            if store.profileNameIsCustom {
                Button("恢复自动名称（\(store.autoProfileName)）") { focused = false; store.profileName = "" }
                    .font(.caption).buttonStyle(.plain).foregroundStyle(Brand.pink)
            }
        }
    }
}

/// 系统选择：三个大按钮（不用系统分段控件，点击反馈明确）
struct PlatformSelector: View {
    @EnvironmentObject var store: Store
    private let items: [(String, String, String)] = [("windows", "Windows", "pc"), ("ios", "iOS", "iphone"), ("android", "Android", "smartphone")]
    var body: some View {
        HStack(spacing: 8) {
            ForEach(items, id: \.0) { it in
                let on = store.platform == it.0
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) { store.setPlatform(it.0) }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: it.2 == "pc" ? "desktopcomputer" : (it.2 == "iphone" ? "iphone" : "candybarphone"))
                            .font(.title3)
                        Text(it.1).font(.footnote.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .foregroundStyle(on ? Color.white : Brand.ink)
                    .background(on ? Brand.pink : Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(PressableStyle())
            }
        }
    }
}

/// 客户端选择：当前系统可用的客户端全部平铺显示，点哪个就选哪个
struct ClientGrid: View {
    @EnvironmentObject var store: Store
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("当前选择：\(platformLabel) · \(store.clientInfo?.name ?? "—")")
                .font(.caption.weight(.semibold)).foregroundStyle(Brand.pink)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 8)], spacing: 8) {
                ForEach(store.clientsForPlatform) { c in
                    let on = store.client == c.id
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) { store.setClient(c.id) }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: on ? "checkmark.circle.fill" : "circle").font(.footnote)
                            Text(c.name).font(.footnote.weight(.semibold)).lineLimit(2).multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 10)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .foregroundStyle(on ? Color.white : Brand.ink)
                        .background(on ? Brand.pink : Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
    }
    private var platformLabel: String { store.platform == "windows" ? "Windows" : (store.platform == "android" ? "Android" : "iOS") }
}
