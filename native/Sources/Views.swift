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
    @State private var draft = ""

    var body: some View {
        PageChrome(title: "节点") {
            HeroCard {
                Text(store.family == "shadowrocket" ? "小火箭：节点在 App 内添加" : "粘贴即可，按客户端写入")
                    .font(.title3.weight(.semibold))
                Text(store.nodeModeHint)
                    .font(.footnote).foregroundStyle(.secondary)
            }

            if store.family == "shadowrocket" {
                PlainCard {
                    Text("推荐流程").font(.headline)
                    Text("1. 打开 Shadowrocket → 首页 → + → 添加订阅或节点\n2. 回到 Lowex 调规则并生成 conf\n3. 用「分享 → 用 Shadowrocket 打开」导入 conf\n4. 策略组会按香港/日本等名称正则收纳你已添加的节点")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text("下方粘贴区仅用于把 URL/节点复制到剪贴板，方便你粘到小火箭；不会写入本配置。")
                        .font(.caption2).foregroundStyle(Brand.pink)
                }
            }

            PlainCard {
                Text(store.family == "shadowrocket" ? "复制到剪贴板" : "粘贴区").font(.headline)
                TextEditor(text: $draft)
                    .frame(minHeight: 140)
                    .scrollContentBackground(.hidden)
                    .font(.system(.footnote, design: .monospaced))
                    .padding(8)
                    .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                HStack {
                    Button {
                        store.applyPaste(draft)
                        if store.family != "shadowrocket" { draft = "" }
                    } label: {
                        Label(store.family == "shadowrocket" ? "复制并提示" : "写入方案",
                              systemImage: store.family == "shadowrocket" ? "doc.on.clipboard" : "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent).tint(Brand.pink)
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if store.family != "shadowrocket" {
                        Button("清空全部", role: .destructive) { store.clearNodes() }
                            .buttonStyle(.bordered)
                    }
                }
                if !store.pasteNote.isEmpty {
                    Text(store.pasteNote).font(.footnote).foregroundStyle(Brand.pink)
                }
            }

            if store.family != "shadowrocket", !store.nodesText.isEmpty || !store.subs.isEmpty {
                PlainCard {
                    Text("当前方案").font(.headline)
                    if !store.subs.isEmpty {
                        Text("订阅 URL · \(store.subs.count) 条").font(.subheadline.weight(.medium))
                        ForEach(Array(store.subs.enumerated()), id: \.offset) { _, s in
                            Text(s["url"] as? String ?? "").font(.caption2).lineLimit(1)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if !store.nodesText.isEmpty {
                        let lines = store.nodesText.split(whereSeparator: \.isNewline)
                        let n = lines.filter { $0.contains("://") }.count
                        Text("节点正文 · \(lines.count) 行" + (n > 0 ? "（约 \(n) 条链接）" : ""))
                            .font(.subheadline.weight(.medium))
                    }
                }
            }

            PlainCard {
                Text("地区分组").font(.headline)
                Text("打开的地区会出现在规则出口与策略组里（含故转/自动/手动）。").font(.caption).foregroundStyle(.secondary)
                ForEach(store.catalog.regions) { r in
                    Toggle(isOn: Binding(
                        get: { store.regions.contains(r.id) },
                        set: { _ in store.toggleRegion(r.id) }
                    )) {
                        HStack(spacing: 8) {
                            RemoteIcon(url: r.icon, name: r.name, size: 22)
                            Text(r.name)
                        }
                    }
                    .tint(Brand.pink)
                }
            }

            Button { store.tab = .rules } label: {
                Label("下一步：规则", systemImage: "arrow.right").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).tint(Brand.pink)
        }
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
        .sensoryFeedback(.selection, trigger: store.platform)
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
        .sensoryFeedback(.selection, trigger: store.client)
    }
    private var platformLabel: String { store.platform == "windows" ? "Windows" : (store.platform == "android" ? "Android" : "iOS") }
}
