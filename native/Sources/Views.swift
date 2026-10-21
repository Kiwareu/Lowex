import SwiftUI
import UIKit

// MARK: - 首页
struct HomeView: View {
    @EnvironmentObject var store: Store
    @State private var showRecs = false
    @State private var showGuide = false
    private let networks = [
        ("mobile", L("移动宽带")), ("telecom", L("电信宽带")), ("unicom", L("联通宽带")), ("cbn", L("广电宽带 / 5G")),
        ("cell-cmcc", L("移动 手机流量")), ("cell-unicom", L("联通 手机流量")), ("cell-telecom", L("电信 手机流量")),
        ("cellular", L("其他蜂窝数据")), ("campus", L("校园网")), ("company", L("公司网络")),
        ("overseas", L("海外网络")), ("other", L("其他 / 不确定"))
    ]
    private let locations = [
        ("cn", L("中国")), ("hk", L("香港")), ("mo", L("澳门")), ("tw", L("台湾")), ("overseas", L("海外"))
    ]

    var body: some View {
        PageChrome(showBrand: true) {
            HeroCard {
                Text(L("代理配置生成器"))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.ink)
                Text(L("Windows / iOS / Android · 选系统与客户端 → 节点 → 规则 → 生成。全部本机完成。"))
                    .font(.footnote).foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    StepBadge(n: 1, label: L("客户端"), done: store.stepClientDone, active: store.activeStep == 1)
                    StepBadge(n: 2, label: L("节点"), done: store.stepNodesDone, active: store.activeStep == 2)
                    StepBadge(n: 3, label: L("规则"), done: store.stepRulesDone, active: store.activeStep == 3)
                    StepBadge(n: 4, label: L("生成"), done: store.stepGenerateDone, active: store.activeStep == 4)
                }
                .padding(.top, 4)
            }

            PlainCard {
                Text(L("① 选择系统与客户端")).font(.headline)
                Text(L("先选目标设备系统，再选客户端。生成的规则只含该系统有效的内容，不会混入其他平台。"))
                    .font(.caption).foregroundStyle(.secondary)
                PlatformSelector()
                ClientGrid()
                if let c = store.clientInfo {
                    if let b = c.blurb { Text(b).font(.caption).foregroundStyle(.secondary) }
                    if let h = store.importHow {
                        Text(h).font(.caption2).foregroundStyle(Brand.pink.opacity(0.9)).padding(.top, 2)
                    }
                    Text((c.placement == "both" ? L("订阅 / 节点：可写进配置，也可在客户端 App 内自己添加（在「节点」页选择）") : (c.embedsSubscription ? L("订阅 / 节点：写进配置文件") : L("订阅 / 节点：展开成节点写进配置（无订阅字段）"))) + L(" · 资料可信度：") + c.confLabel)
                        .font(.caption2).foregroundStyle(.secondary)
                    Text(L("按应用分流：") + platformRuleText).font(.caption2).foregroundStyle(.secondary)
                    Button { showGuide = true } label: {
                        Label(L("查看使用指南"), systemImage: "book").font(.subheadline.weight(.medium)).foregroundStyle(Brand.pink)
                    }.buttonStyle(PressableStyle()).padding(.top, 2)
                }
            }
            .sheet(isPresented: $showGuide) {
                if let c = store.clientInfo {
                    NavStack {
                        ClientGuideView(client: c)
                            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L("完成")) { showGuide = false } } }
                    }
                }
            }

            CapMatrixCard()

            PlainCard {
                Text(L("配置名称")).font(.headline)
                ProfileNameField()
            }

            PlainCard {
                SectionHeader(title: L("网络环境与所在地"), subtitle: L("告诉 Lowex 你现在用的网络和所在地，点「按环境智能推荐」会据此给出 DNS、IPv6、MTU、QUIC 等建议。只是建议，每一项都能再改。"))
                Picker(L("网络"), selection: Binding(get: { store.str("network") }, set: { store.set("network", $0) })) {
                    ForEach(networks, id: \.0) { Text($0.1).tag($0.0) }
                }.pickerStyle(.menu)
                Picker(L("所在地"), selection: Binding(get: { store.str("location") }, set: { store.set("location", $0) })) {
                    ForEach(locations, id: \.0) { Text($0.1).tag($0.0) }
                }.pickerStyle(.menu)
                Button { store.applyRecommend() } label: {
                    Label(L("按环境智能推荐"), systemImage: "wand.and.stars").frame(maxWidth: .infinity, minHeight: Space.tap)
                }
                .buttonStyle(.borderedProminent).tint(Brand.pink)
                if !store.recommendNote.isEmpty {
                    Text(store.recommendNote).font(.footnote).foregroundStyle(.secondary)
                }
                if !store.recommendList.isEmpty {
                    ExpandHeader(open: $showRecs) {
                        Text(L("查看推荐明细与依据（{} 项）", store.recommendList.count)).font(.subheadline.weight(.medium)).foregroundStyle(Brand.ink)
                    }
                    if showRecs {
                        VStack(alignment: .leading, spacing: Space.m) {
                            ForEach(Array(store.recommendList.enumerated()), id: \.offset) { _, r in
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: Space.s) {
                                        Text(r["label"] as? String ?? "").font(.footnote.weight(.semibold))
                                        Text(r["basis"] as? String ?? "").font(.caption2.weight(.bold)).foregroundStyle(.white)
                                            .padding(.horizontal, 6).padding(.vertical, 1)
                                            .background(Brand.pink.opacity(0.8), in: Capsule())
                                    }
                                    Text(r["value"] as? String ?? "").font(.caption).foregroundStyle(Brand.pink)
                                    Text(r["why"] as? String ?? "").font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
                    }
                }
            }

            DnsCard()

            PlainCard {
                Text(L("一键预设")).font(.headline)
                Text(L("对齐作者 Clash Meta v4 结构并加强：故障转移、防泄漏、数字游民银行与加密货币规则包。不含私人订阅。"))
                    .font(.caption).foregroundStyle(.secondary)
                Text(L("预设会一次性改写下面的「生成选项」，建议先套预设，再按需微调。"))
                    .font(.caption2).foregroundStyle(Brand.pink.opacity(0.9))
                DefaultTemplateCard()
                PresetButtons()
            }

            PlainCard {
                Text(L("② 生成选项（仅当前客户端支持）")).font(.headline)
                if store.supports("failover") {
                    OptToggle(title: L("故障转移（地区故转组）"), key: "failover", feature: "failover")
                    Text(L("开启后为每个地区生成「手动 / 自动 / 故转」：故转优先用手动，失败再落到自动测速。"))
                        .font(.caption2).foregroundStyle(.secondary)
                } else if store.family == "singbox" {
                    // sing-box 无原生 fallback：开关仍保留 = 分层预设 A/B 选择，A 降级为地区-自动
                    Toggle(L("故障转移（地区故转组）"), isOn: Binding(
                        get: { (store.opts["failover"] as? Bool) ?? true },
                        set: { store.setOpt("failover", $0) }
                    ))
                    Text(L("sing-box 无原生 fallback：开 = 预设 A（降级为地区-自动组，不是真故转），关 = 预设 B（无故转层）。"))
                        .font(.caption2).foregroundStyle(.secondary)
                }
                PresetModeCard()
                if store.supports("ads") {
                    Picker(L("广告拦截"), selection: Binding<String>(
                        get: { store.adsMode },
                        set: { store.setOpt("ads", $0) }
                    )) {
                        Text(L("关闭")).tag("off")
                        Text("Lite").tag("lite")
                        Text(L("完整")).tag("full")
                    }
                    .pickerStyle(.segmented)
                }
                OptToggle(title: L("拦截追踪器"), key: "trackers", feature: "trackers")
                OptToggle(title: L("拦截遥测"), key: "telemetry", feature: "telemetry")
                OptToggle(title: L("策略组图标"), key: "icons", feature: "icons")
                OptToggle(title: L("关闭 IPv6（防泄漏）"), key: "ipv6", feature: "ipv6", invert: true)
                OptToggle(title: L("TUN 虚拟网卡"), key: "tun", feature: "tun")
                OptToggle(title: "DNS fake-ip", key: "fakeIp", feature: "fakeIp")
                if store.supports("quic") && store.engine.tiers(client: store.client).quic != "not-generated" {
                    Toggle(L("拦截境外 QUIC"), isOn: Binding(
                        get: {
                            let v = store.opts["blockQuic"]
                            if let s = v as? String { return s != "off" }
                            return (v as? Bool) ?? true
                        },
                        set: { store.setOpt("blockQuic", $0 ? "foreign" : "off") }
                    ))
                    if !store.quicTierText.isEmpty {
                        Text(L("QUIC：") + store.quicTierText).font(.caption2).foregroundStyle(.secondary)
                    }
                } else if store.engine.tiers(client: store.client).quic == "not-generated" {
                    Text(L("QUIC：") + store.quicTierText).font(.caption2).foregroundStyle(.secondary)
                }
                if store.supports("stun") {
                    Toggle(L("STUN / WebRTC 防护"), isOn: Binding(
                        get: {
                            let v = store.opts["stun"]
                            if let s = v as? String { return s != "off" }
                            return (v as? Bool) ?? true
                        },
                        set: { store.setOpt("stun", $0 ? "proxy" : "off") }
                    ))
                    if !store.stunTierText.isEmpty {
                        Text(L("STUN：") + store.stunTierText).font(.caption2).foregroundStyle(.secondary)
                    }
                }
                OptToggle(title: L("允许局域网连接"), key: "allowLan", feature: "allowLan")
                OptToggle(title: L("Wi-Fi 通话规则"), key: "wifiCalling", feature: "wifi")
                if store.supports("wifi") {
                    Text(L("打开后请到「规则」页选择运营商；规则会写入生成配置。"))
                        .font(.caption2).foregroundStyle(.secondary)
                    WifiCallNote()
                }
            }

            if !store.unsupportedOptionNames.isEmpty {
                Text(L("当前客户端不支持（已隐藏）：") + store.unsupportedOptionNames.joined(separator: "、"))
                    .font(.caption2).foregroundStyle(.secondary).padding(.horizontal, 4)
            }
            PlainCard {
                Button(role: .destructive) { store.restoreDefaults() } label: {
                    Label(L("恢复默认选项"), systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button { store.tab = .nodes } label: {
                Label(L("下一步：节点"), systemImage: "arrow.right").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).tint(Brand.pink)

            // 页脚：标语 + 版本，低调放在最底部，不挤在字标下面
            VStack(spacing: 2) {
                Text(L("本机生成 · 不上传")).font(.caption2).foregroundStyle(.secondary)
                Text(store.versionLabel).font(.caption2.monospaced()).foregroundStyle(.secondary.opacity(0.7))
            }
            .frame(maxWidth: .infinity).padding(.top, Space.s)
        }
    }
}

extension HomeView {
    var platformRuleText: String {
        switch store.platform {
        case "windows": return (store.clientInfo?.processRules ?? false) ? L("支持 PROCESS-NAME（.exe 进程名）") : L("此客户端不支持进程规则，将按域名 / 服务组")
        case "android": return (store.clientInfo?.processRules ?? false) || store.family == "mihomo" || store.family == "singbox" ? L("支持按包名（Android 包名）") : L("此客户端不支持包名规则，将按域名 / 服务组")
        default: return L("iOS 无进程 / 包名规则，一律按域名 / 服务组")
        }
    }
}

struct CapMatrixCard: View {
    @EnvironmentObject var store: Store
    @State private var open = false
    var body: some View {
        PlainCard {
            ExpandHeader(open: $open) {
                Text(L("能力矩阵 · {}", store.clientInfo?.name ?? "")).font(.headline).foregroundStyle(Brand.ink)
            }
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
                Text(L("灰色 = 该客户端的语法不支持，生成时自动省略。")).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

struct PresetButtons: View {
    @EnvironmentObject var store: Store
    // 默认模板常驻在上；其余预设默认收起，点收放按钮展开，避免一屏全是卡片
    @State private var expanded = false
    private let order = ["balanced", "nomad", "crypto-pack", "antileak", "safe", "min", "stream", "dev", "ai", "cn", "all"]
    var body: some View {
        let all = store.engine.presets()
        let list = order.compactMap { id in all.first { ($0["id"] as? String) == id } }
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
        } label: {
            HStack {
                Text(L("更多预设（{} 个）", list.count)).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.ink)
                Spacer()
                Image(systemName: "chevron.down").font(.footnote.weight(.semibold)).foregroundStyle(Brand.pink)
                    .rotationEffect(.degrees(expanded ? 180 : 0))
            }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        if expanded {
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
            .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
        }
    }
}

/// 分层预设 A/B（9.8+）：由“故障转移”开关决定。A = 有故转，B = 无故转。
struct PresetModeCard: View {
    @EnvironmentObject var store: Store
    var body: some View {
        let mode = store.presetMode
        VStack(alignment: .leading, spacing: 2) {
            Text(mode == "A" ? L("分层预设 A · 有故障转移") : L("分层预设 B · 无故障转移"))
                .font(.subheadline.weight(.semibold)).foregroundStyle(Brand.ink)
            Text(mode == "A"
                 ? L("服务组 → 地区-故转 → 自动 / 手动 → 节点。节点变红 / 超时自动跳转，保持持续连接。")
                 : L("服务组 → 地区 → 直接手动 / 自动 → 节点，没有故转层。"))
                .font(.caption2).foregroundStyle(.secondary)
            if mode == "A" && store.family == "singbox" {
                Text(L("sing-box 无原生 fallback：A 在此自动降级为地区-自动组（已标注，不是真故转）。"))
                    .font(.caption2).foregroundStyle(.orange)
            }
            Text(L("切换：上面「故障转移」开关开 = A，关 = B。"))
                .font(.caption2).foregroundStyle(.secondary)
        }
    }
}

/// 默认模板（9.8+）最前最显眼：不套任何预设的基础配置。
struct DefaultTemplateCard: View {
    @EnvironmentObject var store: Store
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L("默认模板（推荐 · 9.8+）")).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.ink)
            Text(L("不套预设的基础配置：DNS 双通道 + fallback 精确可靠 + TUN 一条链 + 规则 7 阶段。订阅处留空，生成时自动注入你自己填的订阅。"))
                .font(.caption2).foregroundStyle(.secondary)
            Button { store.restoreDefaults() } label: {
                Label(L("恢复为默认模板"), systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered).tint(Brand.pink)
        }
        .padding(10)
        .background(Brand.pink.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// DNS：本地 / 海外各一行（点开选择）、可选「用当前网络自带 DNS」、高级折叠区（自定义地址、Bootstrap）。
struct DnsCard: View {
    @EnvironmentObject var store: Store
    @State private var advanced = false
    var body: some View {
        if store.supports("dnsCn") {
            PlainCard {
                SectionHeader(title: L("DNS"), subtitle: L("决定域名由谁来解析。默认已选好，一般不用改。依据见 docs/NETWORK-ENV.md。"))
                DnsRow(title: L("直连域名"), hint: L("本地网站直连时用的公共 DNS"), key: "dnsCn", catalog: DnsCatalog.cn)
                if store.supports("dnsRemote") {
                    Divider().opacity(0.4)
                    DnsRow(title: L("海外域名"), hint: L("国外网站经代理解析时用的公共 DNS"), key: "dnsRemote", catalog: DnsCatalog.remote)
                }
                if store.supports("cnDnsMode") {
                    Divider().opacity(0.4)
                    OptToggle(title: L("直连域名改用当前网络自带的 DNS"), key: "cnDnsMode", feature: "cnDnsMode", systemMode: true)
                    Text(L("即运营商 / 校园网 / 公司网络分配给你的 DNS。DoH 被拦、或要解析内网域名时再开；它是明文 DNS，节点域名仍走 DoH。开启后「直连域名」那一行不再生效。"))
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Divider().opacity(0.4)
                ExpandHeader(open: $advanced) {
                    Text(L("高级（自定义服务器 / Bootstrap）")).font(.subheadline.weight(.medium)).foregroundStyle(Brand.ink)
                }
                if advanced { DnsAdvanced() }
            }
        }
    }
}

struct OptToggle: View {
    @EnvironmentObject var store: Store
    let title: String; let key: String; let feature: String; var invert = false; var systemMode = false
    var body: some View {
        if store.supports(feature) && systemMode {
            Toggle(title, isOn: Binding(
                get: { (store.opts[key] as? String) == "system" },
                set: { store.setOpt(key, $0 ? "system" : "doh") }
            ))
        } else if store.supports(feature) {
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
            
        }
    }
}

// MARK: - 节点
struct NodesView: View {
    @EnvironmentObject var store: Store
    @State private var subDraft = ""
    @State private var subNameDraft = ""
    @State private var linkDraft = ""
    @State private var showClearSubsConfirm = false
    @State private var showClearHistoryConfirm = false
    @State private var editing: ManualNodeDraft?
    @State private var renameCtx: SubRenameContext?
    @ObservedObject private var ap = LayoutPrefs.shared

    private var isSR: Bool { store.family == "shadowrocket" }
    private var isSB: Bool { store.family == "singbox" }
    /// 订阅区：只有能把订阅 URL 写进配置的客户端才显示
    private var showSubs: Bool { !store.appMode && store.embedsSub }
    /// 节点链接区：Shadowrocket 的配置文件带不了节点链接
    private var showLinks: Bool { !store.appMode && !isSR }
    private var showManual: Bool { !store.appMode }
    private var hiddenNote: String? {
        if store.appMode { return nil }
        if isSR { return L("Shadowrocket 的 conf 只能携带手动节点（[Proxy]）；订阅与节点链接请在 App 内添加，已隐藏这两块。") }
        if !store.embedsSub { return L("{} 没有订阅字段，已隐藏订阅 URL 区；节点链接 / Base64 生成时展开写入。", store.clientInfo?.name ?? L("该客户端")) }
        return nil
    }
    private var singleModeNote: String? {
        store.nodeModeChoice ? nil : L("该客户端的订阅 / 节点只能写进配置文件（资料可信度：{}）。", store.clientInfo?.confLabel ?? L("低"))
    }
    private var appGuide: String { store.clientInfo?.howApp ?? "" }
    private func target(_ kind: String) -> String {
        switch store.family {
        case "mihomo": return kind == "sub" ? "proxy-providers" : "proxies"
        case "stash": return kind == "sub" ? "proxy-providers" : "proxies"
        case "surge": return kind == "sub" ? L("[Proxy Group] 的 policy-path") : "[Proxy]"
        case "qx": return kind == "sub" ? "[server_remote]" : "[server_local]"
        case "loon": return kind == "sub" ? "[Remote Proxy]" : "[Proxy]"
        case "egern": return kind == "sub" ? L("external 策略组") : "proxies"
        case "singbox": return "outbounds"
        default: return L("配置文件")
        }
    }

    var body: some View {
        PageChrome(title: L("节点")) {
            HeroCard {
                Text(L("节点来源，可同时使用")).font(.title3.weight(.semibold))
                Text(L("当前客户端：{}。填写的内容会在生成时自动写入配置对应位置，导入文件即可用。", store.clientInfo?.name ?? ""))
                    .font(.footnote).foregroundStyle(.secondary)
                if let n = singleModeNote { Text(n).font(.caption2).foregroundStyle(.secondary) }
                if let n = hiddenNote { Text(n).font(.caption2).foregroundStyle(.secondary) }
            }

            if store.nodeModeChoice {
                PlainCard {
                    Text(L("节点放在哪里")).font(.headline)
                    ChoiceTabs(options: [("config", L("写入配置")), ("app", L("客户端内添加"))],
                               selection: Binding(get: { store.nodeMode }, set: { store.setNodeMode($0) }))
                    Text(store.appMode ? appGuide : L("输入的内容会在生成时直接写进配置文件，导入后即可使用。{}", store.family == "shadowrocket" ? L("（Shadowrocket conf 只能带手动节点，订阅请选「在客户端 App 内自己添加」。）") : "")).font(.caption).foregroundStyle(.secondary)
                }
            }

            // A. 订阅 URL
            if showSubs { PlainCard {
                Label(L("① 订阅链接 URL"), systemImage: "link").font(.headline)
                Text(subHelper).font(.caption).foregroundStyle(.secondary)
                if !isSR {
                    TextField(L("订阅名称（可空）"), text: $subNameDraft)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                inputBox($subDraft, placeholder: L("https://example.com/sub?token=…\n可一行一个，多个订阅"))
                HStack {
                    Button {
                        store.addSubscriptions(subDraft, name: subNameDraft)
                        if !isSR { subDraft = ""; subNameDraft = "" }
                    } label: {
                        Label(isSR ? L("复制到剪贴板") : L("添加订阅"), systemImage: isSR ? "doc.on.clipboard" : "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent).tint(Brand.pink)
                    .disabled(subDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if !store.subs.isEmpty {
                        Button(L("清空订阅"), role: .destructive) { showClearSubsConfirm = true }.buttonStyle(.bordered)

                    }
                }
                if !store.subs.isEmpty && !isSR {
                    ForEach(Array(store.subs.enumerated()), id: \.offset) { i, sub in
                        let nm = (sub["name"] as? String) ?? ""
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 1) {
                                if !nm.isEmpty { Text(nm).font(.footnote.weight(.semibold)).lineLimit(1) }
                                Text((sub["url"] as? String) ?? "").font(.caption).lineLimit(1).truncationMode(.middle).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button { renameCtx = SubRenameContext(title: L("订阅名称"), initial: nm) { store.renameSub(i, $0) } } label: { Image(systemName: "pencil").font(.footnote) }.buttonStyle(.plain).foregroundStyle(Brand.pink)
                                .frame(width: 36, height: 36).contentShape(Rectangle())
                            Button { store.removeSub(i) } label: { Image(systemName: "trash").font(.footnote) }.buttonStyle(.plain).foregroundStyle(.red)
                                .frame(width: 36, height: 36).contentShape(Rectangle())
                        }
                        .padding(.vertical, 4)
                    }
                    Text(L("点铅笔可随时改名。")).font(.caption2).foregroundStyle(.tertiary)
                }
                // 订阅历史：防误删——清空订阅后可从这里逐条恢复
                if !store.subHistory.isEmpty {
                    HStack {
                        Text(L("历史记录（{}）", store.subHistory.count)).font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                        Spacer()
                        Button(L("清空历史"), role: .destructive) { showClearHistoryConfirm = true }
                            .font(.footnote).foregroundStyle(.red)
                    }

                    Text(L("点一条恢复导入到上方列表；垃圾桶只删这条历史，不影响已添加的订阅。")).font(.caption2).foregroundStyle(.secondary)
                    ForEach(Array(store.subHistory.enumerated()), id: \.offset) { i, entry in
                        let added = store.subs.contains { ($0["url"] as? String) == entry.url }
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 1) {
                                if !entry.name.isEmpty { Text(entry.name).font(.footnote.weight(.semibold)).lineLimit(1) }
                                Text(entry.url).font(.caption).lineLimit(1).truncationMode(.middle).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button { renameCtx = SubRenameContext(title: L("订阅名称"), initial: entry.name) { store.renameSubHistory(i, $0) } } label: { Image(systemName: "pencil").font(.footnote) }.buttonStyle(.plain).foregroundStyle(Brand.pink)
                                .frame(width: 36, height: 36).contentShape(Rectangle())
                            if added {
                                Text(L("已添加")).font(.caption).foregroundStyle(.tertiary)
                            } else {
                                Button { store.removeSubHistory(at: i) } label: { Image(systemName: "trash").font(.footnote) }.buttonStyle(.plain).foregroundStyle(.red)
                                    .frame(width: 36, height: 36).contentShape(Rectangle())
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture { if !added { store.restoreSub(entry) } }
                    }
                }
            }

            }
            // B. 节点链接
            if showLinks { PlainCard {
                Label(showSubs ? L("② 节点链接 / Base64") : L("① 节点链接 / Base64"), systemImage: "text.alignleft").font(.headline)
                Text(linkHelper).font(.caption).foregroundStyle(.secondary)
                inputBox($linkDraft, placeholder: L("ss://… vmess://… vless://… trojan://… hysteria2://… tuic://…\n每行一条，或整段 Base64"))
                HStack {
                    Button {
                        store.applyPaste(linkDraft)
                        if !isSR { linkDraft = "" }
                    } label: {
                        Label(isSR ? L("复制到剪贴板") : L("写入方案"), systemImage: isSR ? "doc.on.clipboard" : "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent).tint(Brand.pink)
                    .disabled(linkDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if !store.nodesText.isEmpty && !isSR {
                        Button(L("清空链接"), role: .destructive) { store.clearNodeText() }.buttonStyle(.bordered)
                    }
                }
                if !store.nodesText.isEmpty && !isSR {
                    let lines = store.nodesText.split(whereSeparator: \.isNewline)
                    let n = lines.filter { $0.contains("://") }.count
                    Text(L("已写入 {} 行", lines.count) + (n > 0 ? L("（约 {} 条链接）", n) : "")).font(.caption.weight(.medium))
                }
                if !store.pasteNote.isEmpty { Text(store.pasteNote).font(.footnote).foregroundStyle(Brand.pink) }
            }

            }
            // C. 手动节点
            if showManual { manualCard }

            PlainCard {
                Text(L("地区分组")).font(.headline)
                Text(L("打开的地区会出现在规则出口与策略组里（含故转/自动/手动）。手动节点按名称里的地区关键词（如「香港」「日本」）归入对应地区。")).font(.caption).foregroundStyle(.secondary)
                // 地区只有十来个：两列、尺寸一致的大卡片；数量为奇数时最后一个占满整行（不留空格），不跟随规则页的显示模式
                PairGrid(items: store.catalog.regions, spacing: 8, height: 56) { r in
                    let on = store.regions.contains(r.id)
                    Button { Haptics.selection(); store.toggleRegion(r.id) } label: {
                        HStack(spacing: 8) {
                            RemoteIcon(url: r.icon, name: r.name, size: 30)
                            Text(r.name).font(.subheadline.weight(on ? .semibold : .regular)).lineLimit(2).minimumScaleFactor(0.8).multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                            Image(systemName: on ? "checkmark.circle.fill" : "circle").foregroundStyle(on ? Brand.pink : Color.secondary.opacity(0.5))
                        }
                        .foregroundStyle(Brand.ink)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(on ? Brand.pink.opacity(0.14) : Color.primary.opacity(0.06)))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Brand.pink.opacity(on ? 0.55 : 0), lineWidth: 1.2))
                        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }.buttonStyle(.plain)
                }
            }

            Button { store.tab = .rules } label: {
                Label(L("下一步：规则"), systemImage: "arrow.right").frame(maxWidth: .infinity)
            }.buttonStyle(.borderedProminent).tint(Brand.pink)
        }
        .dismissKeyboardOnScroll()
        .sheet(item: $editing) { d in
            ManualNodeForm(draft: d).environmentObject(store)
        }
        .sheet(item: $renameCtx) { ctx in
            SubRenameSheet(ctx: ctx)
        }
    }

    private var subHelper: String {
        L("名称在前、链接在后，一行一个 URL。一次只贴一条时，名称会给到这条订阅并写入配置（替换 sub1、sub2…）；贴多条时名称不生效，添加后点铅笔逐条改名。")
    }
    private var linkHelper: String {
        L("每行一条节点链接，或整段 Base64 订阅正文。点「写入方案」→ 生成时写入 {}；不支持的协议会跳过并提示。", target("link"))
    }

    @ViewBuilder private var manualCard: some View {
        PlainCard {
            HStack {
                Label((showSubs ? "③ " : (showLinks ? "② " : "① ")) + L("手动添加节点（SOCKS5 / HTTP / HTTPS）"), systemImage: "network").font(.headline)
                Spacer()
            }
            Text(L("适合家宽 / 住宅代理套餐：点「添加节点」填名称、类型、主机、端口、账号密码，保存后生成时写入 {}。名称里的地区词决定归入哪个地区；密码存本机钥匙串，不上传。", isSR ? "[Proxy]" : target("link")))
                .font(.caption).foregroundStyle(.secondary)
            if let c = store.manualCaps {
                Text(L("当前客户端支持：SOCKS5 {} · SOCKS5-TLS {} · HTTP {} · HTTPS {}", c.socks5 ? "✓" : "✗", c.socks5tls ? "✓" : "✗", c.http ? "✓" : "✗", c.https ? "✓" : "✗"))
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
                            Text("\(kindLabel(m)) · \(m["host"] as? String ?? ""):\(String(describing: m["port"] ?? 0))" + (((m["user"] as? String) ?? "").isEmpty ? "" : L(" · 有账号")))
                                .font(.caption2).foregroundStyle(.secondary).lineLimit(2).truncationMode(.middle)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(get: { on }, set: { _ in store.toggleManual(id) })).labelsHidden()
                    }
                    if let issue, on { Label(L("当前客户端不会写入：{}", issue), systemImage: "exclamationmark.triangle.fill").font(.caption2).foregroundStyle(.orange) }
                    HStack(spacing: 14) {
                        Button(L("编辑")) { editing = ManualNodeDraft(m) }
                        Button(L("删除"), role: .destructive) { store.removeManual(id) }
                    }.font(.caption).buttonStyle(.plain).foregroundStyle(Brand.pink)
                }
                .padding(10).background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            Button { editing = ManualNodeDraft(nil) } label: {
                Label(L("添加节点"), systemImage: "plus.circle.fill").frame(maxWidth: .infinity)
            }.buttonStyle(.borderedProminent).tint(Brand.pink)
            if store.manualBlockedCount > 0 {
                Text(L("有 {} 个手动节点当前客户端写不出，生成时会跳过并在结果里提示。", store.manualBlockedCount)).font(.caption2).foregroundStyle(.orange)
            }
        }
        .overlay {
            if showClearSubsConfirm {
                GlassConfirm(title: L("清空全部订阅？"), message: "",
                    actions: [.init(title: L("全部删除"), destructive: true) { var s = store.state; s["subs"] = []; store.state = s }],
                    dismiss: { showClearSubsConfirm = false })
            }
            if showClearHistoryConfirm {
                GlassConfirm(title: L("清空全部历史记录？"), message: "",
                    actions: [.init(title: L("全部删除"), destructive: true) { store.clearSubHistory() }],
                    dismiss: { showClearHistoryConfirm = false })
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
                .hideScrollBG()
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
        NavStack {
            Form {
                Section(L("名称（决定归入哪个地区）")) {
                    TextField(L("例如 香港-住宅 / 日本-家宽"), text: $draft.name)
                }
                Section(L("类型")) {
                    Picker(L("类型"), selection: $type) { Text("SOCKS5").tag(0); Text("HTTP").tag(1); Text("HTTPS").tag(2) }.pickerStyle(.segmented)
                    if type == 0 { Toggle("SOCKS5 over TLS", isOn: $draft.tls) }
                }
                Section(L("服务器")) {
                    TextField(L("主机（域名或 IP）"), text: $draft.host).textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    TextField(L("端口"), text: $draft.port).keyboardType(.numberPad)
                }
                Section(L("账号（可留空）")) {
                    TextField(L("用户名"), text: $draft.user).textInputAutocapitalization(.never).autocorrectionDisabled()
                    HStack {
                        Group { if showPass { TextField(L("密码"), text: $draft.pass) } else { SecureField(L("密码"), text: $draft.pass) } }
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                        Button { showPass.toggle() } label: { Image(systemName: showPass ? "eye.slash" : "eye") }.buttonStyle(.plain)
                    }
                }
                Section {
                    if let issue { Label(issue, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange).font(.footnote) }
                    else { Label(L("当前客户端可以写入这个节点"), systemImage: "checkmark.circle.fill").foregroundStyle(.green).font(.footnote) }
                    Text(L("密码保存在本机钥匙串（不可用时回退到 App 沙盒私有文件），不会上传。")).font(.caption2).foregroundStyle(.secondary)
                }
            }
            .dismissKeyboardOnScroll()
            .navigationTitle(draft.isNew ? L("添加节点") : L("编辑节点")).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L("取消")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("保存")) { save() }.disabled(!canSave)
                }
            }
            .onChangeValue(of: type) { t in draft.kind = t == 0 ? "socks5" : "http"; draft.tls = t == 2 ? true : (t == 1 ? false : draft.tls) }
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

/// 出口选择弹窗：液态玻璃小窗（可滚动），替代原来的全屏 confirmationDialog。
/// 顶部：代理 / 直连 / 拦截；中部：全部节点（自动/手动）；下部：每个地区（故转/自动/手动）。
/// 选中未启用的地区会自动启用该地区。
struct ExitPicker: View {
    @EnvironmentObject var store: Store
    let group: Catalog.Group
    var onClose: () -> Void

    private var current: String { (store.groupState[group.id]?["policy"] as? String) ?? group.def }

    private func pick(_ policy: String) {
        if policy.hasPrefix("R:") {
            let id = String(policy.dropFirst(2).split(separator: "/").first ?? "")
            if !id.isEmpty && !store.regions.contains(id) { store.toggleRegion(id) }
        }
        store.setGroup(group, policy: policy)
        Haptics.light()
        onClose()
    }

    private var selectedFill: AnyShapeStyle {
        AnyShapeStyle(LinearGradient(colors: [Brand.pink, Brand.lilac], startPoint: .leading, endPoint: .trailing))
    }

    /// 地区行里的小胶囊：故转 / 自动 / 手动
    private func chip(_ title: String, _ policy: String) -> some View {
        let on = current == policy
        return Button { pick(policy) } label: {
            Text(title)
                .font(.caption.weight(on ? .bold : .regular))
                .foregroundStyle(on ? Color.white : Brand.ink)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(on ? selectedFill : AnyShapeStyle(Color.secondary.opacity(0.12))))
        }
        .buttonStyle(.plain)
    }

    /// 顶部大按钮：代理 / 直连 / 拦截
    private func baseButton(_ title: String, _ policy: String) -> some View {
        let on = current == policy
        return Button { pick(policy) } label: {
            Text(title)
                .font(.subheadline.weight(on ? .bold : .regular))
                .foregroundStyle(on ? Color.white : Brand.ink)
                .frame(maxWidth: .infinity).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(on ? selectedFill : AnyShapeStyle(Color.secondary.opacity(0.12))))
        }
        .buttonStyle(.plain)
    }

    private func regionRow(_ r: Catalog.Region) -> some View {
        HStack(spacing: 6) {
            Text(r.name).font(.subheadline).foregroundStyle(Brand.ink)
            if !store.regions.contains(r.id) {
                Text(L("未启用")).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            chip(L("故转"), "R:" + r.id)
            chip(L("自动"), "R:" + r.id + "/a")
            chip(L("手动"), "R:" + r.id + "/m")
        }
        .padding(.vertical, 4)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.12).ignoresSafeArea()
                .onTapGesture { onClose() }
            VStack(spacing: 0) {
                HStack {
                    Text(L("出口")).font(.headline).foregroundStyle(Brand.ink)
                    Text(group.name).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    Spacer()
                    Button { onClose() } label: {
                        Image(systemName: "xmark.circle.fill").font(.body).foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 8)
                HStack(spacing: 6) {
                    baseButton(L("代理"), "PROXY")
                    baseButton(L("直连"), "DIRECT")
                    baseButton(L("拦截"), "REJECT")
                }
                .padding(.horizontal, 14).padding(.bottom, 8)
                Divider().padding(.horizontal, 14)
                ScrollView {
                    VStack(spacing: 2) {
                        HStack(spacing: 6) {
                            Text(L("全部节点")).font(.subheadline).foregroundStyle(Brand.ink)
                            Spacer()
                            chip(L("自动"), "ALL/a")
                            chip(L("手动"), "ALL/m")
                        }
                        .padding(.vertical, 4)
                        ForEach(store.catalog.regions) { r in regionRow(r) }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 6)
                }
                .frame(maxHeight: 340)
            }
            .frame(maxWidth: 300)
            .popupGlass()
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - 规则
struct RulesView: View {
    @EnvironmentObject var store: Store
    @State private var query = ""
    @State private var section: RuleSection = .groups
    @State private var onlyFav = false
    @State private var expanded: Set<String> = []
    @State private var policyTarget: Catalog.Group?
    @State private var detailTarget: Catalog.Group?
    @ObservedObject private var ap = LayoutPrefs.shared

    enum RuleSection: String, CaseIterable, Identifiable {
        case groups = "服务分组"
        case apps = "按 App"
        case domains = "自定义域名"
        case wifi = "Wi-Fi 通话"
        var id: String { rawValue }
        var title: String { L(rawValue) }
    }

    /// 常用度排序（只影响界面顺序，不影响生成结果）：越常用越靠前，未列出的保持原顺序排在后面。
    private static let popularity: [String: Int] = {
        let order = ["ai", "ai-cn", "telegram", "youtube", "netflix", "google", "apple", "microsoft", "discord", "twitter", "meta", "whatsapp", "instagram",
                     "tiktok", "github", "steam", "disney", "spotify", "primevideo", "twitch", "reddit", "paypal", "bank-overseas",
                     "crypto", "crypto-more", "xbox", "playstation", "epic", "nintendo", "blizzard", "onedrive", "cloudflare",
                     "notion", "slack", "zoom", "dropbox", "linkedin", "signal", "amazon", "ebay", "docker", "npm", "gitlab",
                     "wikimedia", "scholar", "bilibili", "games-cn", "pt", "p2p-private", "ads", "telemetry", "cn", "proxy-fallback"]
        return Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })
    }()
    var filteredGroups: [Catalog.Group] {
        var list = store.catalog.groups.enumerated().sorted {
            let a = Self.popularity[$0.element.id] ?? 1000 + $0.offset, b = Self.popularity[$1.element.id] ?? 1000 + $1.offset
            return a < b
        }.map { $0.element }
        if onlyFav { list = list.filter { store.favoriteIds.contains($0.id) } }
        if query.isEmpty { return list }
        return list.filter {
            $0.name.localizedCaseInsensitiveContains(query) || $0.id.contains(query.lowercased())
        }
    }

    var body: some View {
        PageChrome(title: L("规则")) {
            HeroCard {
                Text(L("③ 分流与增强"))
                    .font(.headline)
                Text(store.stepRulesHint + L(" · 选项会直接进入生成配置"))
                    .font(.caption).foregroundStyle(.secondary)
                ChipTabs(options: RuleSection.allCases.map { ($0, $0.title) }, selection: $section)
            }

            switch section {
            case .groups:
                if store.family == "mihomo" || store.family == "stash" {
                    PlainCard {
                        Text("💡 " + L("「资源更新」组需要先在客户端的控制面板里手动选中一个具体节点（或「一键代理」），选好之后才会生效；没选之前它默认直连。")).font(.footnote).foregroundStyle(.secondary)
                    }
                }
                PlainCard {
                    TextField(L("搜索服务分组"), text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    HStack(spacing: 8) {
                        Text(L("只看收藏")).font(.subheadline)
                        // 开关统一缩小一档：仍是系统原生开关，只做缩放
                        Toggle("", isOn: $onlyFav).labelsHidden()
                            .scaleEffect(0.8)
                            .frame(width: 41, height: 25)
                    }
                    DensityBar()
                }
                // 三种模式各自是「全部同一种行」：单列 / 紧凑 = 每项一行；双列 = 每两项一行（奇数时最后一格留空，尺寸相同）
                // 每次渲染只取一次分组状态 / 收藏 / 分类（以前每行都各自从 [String: Any] 里重新转换一遍）
                let gs = store.groupState, favs = Set(store.favoriteIds), cats = store.catalog.cats
                let list = filteredGroups
                if list.isEmpty {
                    // 以前这里直接白屏：没收藏时开「只看收藏」、或搜索没结果，页面全空还零提示，看着像坏了
                    PlainCard {
                        Text(onlyFav && store.favoriteIds.isEmpty ? L("还没有收藏的分组") : L("没有找到匹配的分组"))
                            .font(.subheadline.weight(.semibold))
                        Text(onlyFav && store.favoriteIds.isEmpty
                             ? L("点任意分组行上的 ☆ 星星就能收藏它。收藏之后打开「只看收藏」，这里就只显示你收藏的分组。")
                             : L("换个关键词试试，或者清空搜索。"))
                            .font(.caption).foregroundStyle(.secondary)
                        if onlyFav && store.favoriteIds.isEmpty {
                            Button { onlyFav = false } label: { Text(L("先看全部分组")) }
                                .buttonStyle(.bordered).tint(Brand.pink)
                        }
                    }
                } else if ap.density == .category {
                    // 按分类：单列、行高一致，分类标题按常见程度排序；名称完整显示
                    ForEach(categorySections(list), id: \.0) { sec in
                        HStack(spacing: 6) {
                            Text(cats[sec.0] ?? sec.0).font(.footnote.weight(.bold)).foregroundStyle(Brand.ink)
                            Text("\(sec.1.count)").font(.caption2).foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.top, Space.s).padding(.leading, 4)
                        ForEach(sec.1) { g in row(g, gs, favs, cats) }
                    }
                } else if ap.density == .dual {
                    ForEach(pairs(list), id: \.0.id) { pair in
                        HStack(alignment: .top, spacing: Space.s) {
                            row(pair.0, gs, favs, cats)
                            if let b = pair.1 { row(b, gs, favs, cats) } else { Color.clear.frame(maxWidth: .infinity) }
                        }
                    }
                } else {
                    ForEach(list) { g in row(g, gs, favs, cats) }
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
                        Text(L("当前客户端不支持在配置里写 Wi-Fi 通话规则。"))
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }

            Button { store.tab = .generate } label: {
                Label(L("下一步：生成"), systemImage: "sparkles").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).tint(Brand.pink)
        }
        .overlay {
            if let g = policyTarget {
                ExitPicker(group: g) { policyTarget = nil }
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .animation(.easeOut(duration: 0.18), value: policyTarget?.id)
        .sheet(item: $detailTarget) { g in GroupDetailSheet(group: g, cat: store.catalog.cats[g.cat] ?? g.cat) }
    }

    /// 分类显示顺序（越常用越靠前）；未列出的分类按原顺序排在最后
    private static let categoryOrder = ["ai", "streaming", "social", "game", "dev", "office", "finance", "crypto", "shopping", "general", "cn-streaming", "download", "tools", "direct", "reject", "proxy"]
    private func categorySections(_ l: [Catalog.Group]) -> [(String, [Catalog.Group])] {
        var buckets: [String: [Catalog.Group]] = [:]
        var firstSeen: [String] = []
        for g in l { if buckets[g.cat] == nil { firstSeen.append(g.cat) }; buckets[g.cat, default: []].append(g) }
        let known = Self.categoryOrder.filter { buckets[$0] != nil }
        let rest = firstSeen.filter { !Self.categoryOrder.contains($0) }
        return (known + rest).map { ($0, buckets[$0] ?? []) }
    }
    private func pairs(_ l: [Catalog.Group]) -> [(Catalog.Group, Catalog.Group?)] {
        stride(from: 0, to: l.count, by: 2).map { (l[$0], $0 + 1 < l.count ? l[$0 + 1] : nil) }
    }
    private func policyText(_ p: String) -> String {
        switch p {
        case "PROXY": return L("代理")
        case "DIRECT": return L("直连")
        case "REJECT": return L("拦截")
        case "ALL/a": return L("全部 · 自动")
        case "ALL/m": return L("全部 · 手动")
        case "LB": return L("负载均衡")
        default:
            if p.hasPrefix("R:") {
                let parts = p.dropFirst(2).split(separator: "/").map(String.init)
                if let id = parts.first, let r = store.catalog.regions.first(where: { $0.id == id }) {
                    let mode = parts.count > 1 ? (parts[1] == "a" ? L("自动") : L("手动")) : L("故转")
                    return L("{} · {}", r.name, mode)
                }
            }
            return p
        }
    }
    /// 一行服务分组：只吃值类型，不依赖 EnvironmentObject，用 equatable 避免无关状态变化时整列重绘。
    private func row(_ g: Catalog.Group, _ gs: [String: [String: Any]], _ favs: Set<String>, _ cats: [String: String]) -> some View {
        let detail = [g.notes, g.risk.map { L("误判拦截风险：{}", $0) }].compactMap { $0 }.filter { !$0.isEmpty }
        return GroupRow(
            name: g.name, icon: g.icon, cat: cats[g.cat] ?? g.cat, detail: detail,
            on: (gs[g.id]?["on"] as? Bool) ?? g.defOn, policy: policyText((gs[g.id]?["policy"] as? String) ?? g.def), fav: favs.contains(g.id),
            density: ap.density == .category ? .single : ap.density, open: expanded.contains(g.id),
            onOpen: {
                Haptics.light()
                if ap.density == .dual { detailTarget = g; return }     // 双列：弹出详情，不撑高单元格
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expanded.contains(g.id) { expanded.remove(g.id) } else { expanded.insert(g.id) }
                }
            },
            onFav: { store.toggleFavorite(g.id) },
            onOn: { store.setGroup(g, on: $0) },
            onPolicy: { policyTarget = g }
        ).equatable().id(g.id + ap.density.rawValue)   // 模式变化时该行整体重建，不保留旧样式
    }
}

/// 服务分组行（三种密度，同一模式下所有行尺寸一致；只有用户主动展开详情时单列 / 紧凑行才会变高）。
struct GroupRow: View, Equatable {
    let name: String, icon: String?, cat: String, detail: [String]
    let on: Bool, policy: String, fav: Bool, density: LayoutDensity, open: Bool
    var onOpen: () -> Void, onFav: () -> Void, onOn: (Bool) -> Void, onPolicy: () -> Void
    static func == (a: GroupRow, b: GroupRow) -> Bool {
        a.name == b.name && a.icon == b.icon && a.cat == b.cat && a.detail == b.detail && a.on == b.on
            && a.policy == b.policy && a.fav == b.fav && a.density == b.density && a.open == b.open
    }
    private var radius: CGFloat { max(10, Brand.radius * 0.7) }
    private var rowHeight: CGFloat { density == .single ? 60 : (density == .compact ? 44 : 84) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Group {
                if density == .dual { dualBody } else { lineBody }
            }
            .frame(height: rowHeight)
            if open && density != .dual && !detail.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(detail, id: \.self) { Text($0).font(.caption2).foregroundStyle(.secondary) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
            }
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GlassFill(r: radius, tint: on ? Brand.pink : nil))
    }

    /// 单列 / 紧凑：图标 | 名称（永远完整显示，必要时两行）+ 第二行（分类 / 出口）| 小箭头 | 星标 | 开关。
    /// 出口菜单从名称右侧挪到名称下方，名称才有足够宽度。
    private var lineBody: some View {
        HStack(spacing: 4) {
            Button(action: onOpen) {
                HStack(spacing: 8) {
                    RemoteIcon(url: icon, name: name, size: density == .single ? 30 : 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name).font(density == .single ? .subheadline.weight(.semibold) : .footnote.weight(.semibold))
                            .foregroundStyle(Brand.ink).lineLimit(2).minimumScaleFactor(0.8)
                            .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                        if density == .single { Text(cat).font(.caption2).foregroundStyle(.secondary).lineLimit(1) }
                    }
                    .layoutPriority(1)
                    Spacer(minLength: 0)
                }
                .frame(maxHeight: .infinity).contentShape(Rectangle())
            }.buttonStyle(.plain)
            if on { policyChip }
            if !detail.isEmpty { chevron }
            starButton
            toggle
        }
    }
    private var chevron: some View {
        Button(action: onOpen) {
            Image(systemName: "chevron.down").font(.system(size: 11, weight: .bold)).foregroundStyle(Brand.pink)
                .rotationEffect(.degrees(open ? 180 : 0))
                .frame(width: 22, height: 22).background(Brand.pink.opacity(0.14), in: Circle())
                .frame(width: 28, height: 36).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    /// 双列：上排图标 + 名称（占满单元格宽度，最多两行）；下排出口 / 未启用 + 星标 + 开关。有详情时名称后带 ⓘ，点名称弹出详情。
    private var dualBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: onOpen) {
                HStack(spacing: 6) {
                    RemoteIcon(url: icon, name: name, size: 24)
                    Text(name).font(.footnote.weight(.semibold)).foregroundStyle(Brand.ink)
                        .lineLimit(2).minimumScaleFactor(0.8).multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true).layoutPriority(1)
                    if !detail.isEmpty { Image(systemName: "info.circle").font(.caption2).foregroundStyle(.secondary) }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading).contentShape(Rectangle())
            }.buttonStyle(.plain)
            HStack(spacing: 0) {
                if on { policyChip } else { Text(L("未启用")).font(.caption2).foregroundStyle(.secondary).lineLimit(1) }
                Spacer(minLength: 0)
                starButton
                toggle
            }
            .frame(height: 36)
        }
        .padding(.top, 4)
    }

    private var starButton: some View {
        Button(action: onFav) {
            Image(systemName: fav ? "star.fill" : "star").foregroundStyle(Brand.pink).font(.footnote)
                .frame(width: 28, height: 36).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
    private var toggle: some View {
        // 系统原生开关：iOS 26 上自动是液态玻璃（和「只看收藏」同款），旧系统是经典扁开关，全 App 统一
        // 四种布局共用：统一缩小一档（0.8），卡片里更协调，仍是系统原生控件
        Toggle("", isOn: Binding(get: { on }, set: { Haptics.light(); onOn($0) }))
            .labelsHidden()
            .scaleEffect(0.8)
            .frame(width: 41, height: 25)
    }
    private var policyChip: some View {
        Button(action: onPolicy) {
            HStack(spacing: 2) {
                Text(policy).lineLimit(1).minimumScaleFactor(0.8)
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 8, weight: .bold))
            }
            .font(.caption2.weight(.semibold)).foregroundStyle(Brand.pink)
            .padding(.horizontal, 7).padding(.vertical, 4)
            .background(Brand.pink.opacity(0.12), in: Capsule())
            .frame(maxWidth: 96)
        }.buttonStyle(.plain)
    }
}

/// 分组详情（双列模式下点名称 / ⓘ 弹出）。
struct GroupDetailSheet: View {
    let group: Catalog.Group; let cat: String
    @Environment(\.presentationMode) private var pm
    var body: some View {
        NavStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.m) {
                    HStack(spacing: Space.m) {
                        RemoteIcon(url: group.icon, name: group.name, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(group.name).font(.headline).foregroundStyle(Brand.ink)
                            Text(cat).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if let n = group.notes, !n.isEmpty { Text(n).font(.footnote) }
                    if let r = group.risk, !r.isEmpty { Text(L("误判拦截风险：{}", r)).font(.footnote).foregroundStyle(.secondary) }
                }
                .padding(Space.l).frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(PinkBackground())
            .navigationTitle(group.name).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L("完成")) { pm.wrappedValue.dismiss() } } }
        }
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
                Text(store.profileNameIsCustom ? L("自定义") : L("自动"))
                    .font(.caption2.weight(.bold)).foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(store.profileNameIsCustom ? Color.orange : Brand.pink, in: Capsule())
                Text(store.profileNameIsCustom ? L("手动名称，不随客户端变化") : L("随所选客户端自动变化")).font(.caption2).foregroundStyle(.secondary)
            }
            // 未聚焦时永远直接显示 store 里的当前名字，避免本地缓存过期
            TextField(L("配置名称"), text: Binding(get: { focused ? text : store.profileName }, set: { text = $0 }))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focused)
                .submitLabel(.done)
                .onSubmit { focused = false }
                .onChangeValue(of: focused) { f in
                    if f { text = store.profileName } else { store.profileName = text }
                }
            if store.profileNameIsCustom {
                Button(L("恢复自动名称（{}）", store.autoProfileName)) { focused = false; store.profileName = "" }
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
            Text(L("当前选择：{} · {}", platformLabel, store.clientInfo?.name ?? "—"))
                .font(.caption.weight(.semibold)).foregroundStyle(Brand.pink)
            PairGrid(items: store.clientsForPlatform, spacing: 8, height: 52) { c in
                let on = store.client == c.id
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) { store.setClient(c.id) }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: on ? "checkmark.circle.fill" : "circle").font(.footnote)
                        Text(c.name).font(.footnote.weight(.semibold)).lineLimit(2).minimumScaleFactor(0.85).multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .foregroundStyle(on ? Color.white : Brand.ink)
                    .background(on ? Brand.pink : Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(PressableStyle())
            }
        }
    }
    private var platformLabel: String { store.platform == "windows" ? "Windows" : (store.platform == "android" ? "Android" : "iOS") }
}


// MARK: - 订阅改名

/// 改名编辑上下文（保存动作由调用处给定）
struct SubRenameContext: Identifiable {
    let id = UUID()
    let title: String
    let initial: String
    let save: (String) -> Void
}

/// 订阅名称编辑器：一个输入框 + 保存 / 清除名称。
struct SubRenameSheet: View {
    let ctx: SubRenameContext
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    var body: some View {
        NavStack {
            ZStack {
                PinkBackground()
                VStack(spacing: 12) {
                    PlainCard {
                        Text(L("给这条订阅起个名字：App 列表、历史里都会显示；生成配置时订阅来源也用这个名称（订阅不写进配置的客户端只在 App 里显示）。留空保存 = 清除名称。")).font(.caption).foregroundStyle(.secondary)
                        TextField(L("例如：主力机场"), text: $text)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle(ctx.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L("取消")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button(L("保存")) { ctx.save(text); dismiss() } }
            }
            .onAppear { text = ctx.initial }
        }
    }
}
