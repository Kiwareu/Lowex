import SwiftUI
import Foundation
import UIKit

/// 方案以 [String: Any] 保存，字段与网页版 / 引擎一致，方案 JSON 可互通。
final class Store: ObservableObject {
    let engine = Engine.shared
    let catalog: Catalog
    @Published var state: [String: Any] {
        didSet { if !result.text.isEmpty || result.error != nil { result = GenResult(text: "", name: "", warnings: []) } }
    }
    @Published var result = GenResult(text: "", name: "", warnings: [])
    @Published var recommendNote = ""
    @Published var tab: AppTab = .home
    @Published var generating = false
    @Published var pasteNote = ""
    @Published var showDisclaimer = false
    @Published var showSplash = true
    @Published var showAppearance = false
    @Published var celebrate = 0
    @Published var remoteURL = ""
    @Published var qrNote = ""
    private var needsDisclaimer = false

    private let key = "lowex.native.state.v3"
    private let disclaimerKey = "lowex.native.disclaimer.accepted.v1"

    init() {
        let cat = Engine.shared.catalog()
        catalog = cat
        let accepted = UserDefaults.standard.bool(forKey: disclaimerKey)
        needsDisclaimer = !accepted
        if let d = UserDefaults.standard.data(forKey: key),
           let s = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] {
            var merged = s
            merged["subs"] = []
            merged["nodesText"] = ""
            let plats = ["windows", "ios", "android"]
            if let pf = merged["platform"] as? String, plats.contains(pf) == false { merged["platform"] = "ios" }
            if merged["platform"] == nil { merged["platform"] = "ios" }
            let pf = merged["platform"] as? String ?? "ios"
            if let c = merged["client"] as? String,
               cat.clients.first(where: { $0.id == c })?.platforms.contains(pf) == true {
            } else {
                merged["client"] = cat.clients.first(where: { $0.platforms.contains(pf) })?.id ?? "shadowrocket"
            }
            // 旧版本把自动生成的名字也存了下来：没有「手动改过」标记就丢弃，改回跟随客户端
            if (merged["profileNameCustom"] as? Bool) != true { merged["profileName"] = "" }
            // 任何形如「Lowex-<某客户端名>」的旧名字都是自动生成的，一律丢弃
            if let pn = merged["profileName"] as? String, !pn.isEmpty {
                let autos = Set(cat.clients.flatMap { c -> [String] in
                    var short = c.name
                    for (l, r) in [("(", ")"), ("（", "）")] {
                        while let a = short.range(of: l), let b = short.range(of: r, range: a.upperBound..<short.endIndex) { short.removeSubrange(a.lowerBound..<b.upperBound) }
                    }
                    return ["Lowex-" + c.name, "Lowex-" + short, "Lowex-" + short.replacingOccurrences(of: " ", with: ""), "Lowex-" + c.id]
                })
                if autos.contains(pn) || pn.hasPrefix("Lowex-Shadowrocket") { merged["profileName"] = ""; merged["profileNameCustom"] = false }
            }
            // 缺失的选项补默认值（旧版本升级）
            let base = Engine.shared.initialState(client: merged["client"] as? String ?? "shadowrocket", platform: pf)
            var o = (base["opts"] as? [String: Any]) ?? [:]
            for (k, v) in (merged["opts"] as? [String: Any]) ?? [:] { o[k] = v }
            merged["opts"] = o
            state = merged
            reconcile(silent: true)
        } else {
            let first = cat.clients.first(where: { $0.id == "shadowrocket" })?.id
                ?? cat.clients.first?.id ?? "shadowrocket"
            state = Engine.shared.initialState(client: first, platform: "ios")
        }
    }

    func finishSplash() {
        withAnimation(.easeOut(duration: 0.45)) { showSplash = false }
        if needsDisclaimer { DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.showDisclaimer = true } }
    }

    func acceptDisclaimer() {
        needsDisclaimer = false
        UserDefaults.standard.set(true, forKey: disclaimerKey)
        showDisclaimer = false
    }

    // MARK: 读写
    func str(_ k: String) -> String { state[k] as? String ?? "" }
    func set(_ k: String, _ v: Any) {
        var s = state; s[k] = v; state = s; save()
    }
    var opts: [String: Any] { state["opts"] as? [String: Any] ?? [:] }
    func setOpt(_ k: String, _ v: Any) {
        var o = opts; o[k] = v
        var s = state; s["opts"] = o; state = s; save()
    }
    func save() {
        var s = state
        s["subs"] = []
        s["nodesText"] = ""
        if let d = try? JSONSerialization.data(withJSONObject: s) {
            UserDefaults.standard.set(d, forKey: key)
        }
    }

    var client: String { str("client") }
    var clientInfo: Catalog.Client? { catalog.clients.first { $0.id == client } }
    var platform: String { let p = str("platform"); return p.isEmpty ? "ios" : p }
    var isMobilePlatform: Bool { platform == "ios" || platform == "android" }
    var clientsForPlatform: [Catalog.Client] { catalog.clients.filter { $0.platforms.contains(platform) } }
    func supports(_ feature: String) -> Bool {
        if feature == "wifi" && !isMobilePlatform { return false }
        return engine.supports(client: client, feature: feature)
    }
    func setPlatform(_ p: String) {
        guard p != platform else { return }
        var s = state; s["platform"] = p
        if clientInfo?.platforms.contains(p) != true,
           let c = catalog.clients.first(where: { $0.platforms.contains(p) }) { s["client"] = c.id }
        state = s
        reconcile()
    }
    func setClient(_ id: String) {
        guard id != client else { return }
        var s = state; s["client"] = id; state = s
        reconcile()
    }

    /// 切换系统 / 客户端后：把依赖它们的状态重新对齐（不支持的选项回默认、不适用的按应用规则移除、清空旧结果）。
    func reconcile(silent: Bool = false) {
        var notes: [String] = []
        var s = state
        let base = engine.initialState(client: client, platform: platform)
        let defOpts = (base["opts"] as? [String: Any]) ?? [:]
        var o = (s["opts"] as? [String: Any]) ?? [:]
        let map: [(String, String)] = [("failover", "failover"), ("ads", "ads"), ("trackers", "trackers"), ("telemetry", "telemetry"),
            ("icons", "icons"), ("ipv6", "ipv6"), ("tun", "tun"), ("fakeIp", "fakeIp"), ("blockQuic", "quic"), ("stun", "stun"),
            ("allowLan", "allowLan"), ("wifiCalling", "wifi")]
        var reset: [String] = []
        for (k, f) in map where !supports(f) {
            if let d = defOpts[k], "\(o[k] ?? "")" != "\(d)" { o[k] = d; reset.append(k) }
            else if o[k] == nil, let d = defOpts[k] { o[k] = d }
        }
        if !supports("wifi") { o["wifiCalling"] = false }
        s["opts"] = o
        if !reset.isEmpty { notes.append("\(reset.count) 个当前客户端不支持的选项已恢复默认") }
        // 按应用规则：进程名只属于 Windows，包名只属于 Android
        let apps = (s["apps"] as? [[String: Any]]) ?? []
        let kept = apps.filter { a in
            switch a["kind"] as? String {
            case "process": return platform == "windows" && (clientInfo?.processRules ?? false)
            case "package": return platform == "android" && (clientInfo?.processRules ?? false)
            default: return true
            }
        }
        if kept.count != apps.count { s["apps"] = kept; notes.append("\(apps.count - kept.count) 条不适用本系统的按应用规则已移除") }
        // 模块只属于支持模块的客户端
        if !engine.supportsModules(client: client), let m = s["modules"] as? [Any], !m.isEmpty {
            s["modules"] = []; notes.append("模块已清空（当前客户端不支持）")
        }
        state = s
        result = GenResult(text: "", name: "", warnings: [])
        pasteNote = ""
        qrNote = ""
        if !silent {
            recommendNote = notes.isEmpty ? "" : "已按「\(clientInfo?.name ?? client)」调整：" + notes.joined(separator: "；") + "。"
        }
        save()
    }
    var buildNumber: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?" }
    var versionLabel: String { "v1.0.0 · App \(appVersion) (build \(buildNumber))" }
    var appVersion: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "3.6.0" }

    /// 当前客户端是否把订阅 URL 写进配置文件
    var embedsSub: Bool { clientInfo?.embedsSubscription ?? false }
    var family: String { clientInfo?.family ?? "" }

    var nodeModeHint: String {
        switch family {
        case "shadowrocket":
            return "小火箭特殊：节点/订阅必须在 App「首页」单独添加，本配置只写规则与策略组（用正则按地区名收纳首页节点）。此处粘贴不会写进 .conf。"
        case "singbox":
            return "sing-box / Karing 无订阅字段：请粘贴节点链接（ss://、vmess://、vless://、trojan:// 等）或订阅正文；单独的 https 订阅 URL 无法写进 JSON。"
        case "surge":
            return "Surge：订阅 URL 会写成 policy-path；节点链接会展开进 [Proxy]。也可导入后在 Surge 里再加订阅。"
        case "qx":
            return "Quantumult X：订阅写在 [server_remote]；节点写在 [server_local]。"
        case "loon":
            return "Loon：订阅写在 [Remote Proxy]；节点写在 [Proxy]。"
        case "stash", "mihomo":
            return "Clash / Mihomo / Stash：订阅写成 proxy-providers；节点展开进 proxies。"
        case "egern":
            return "Egern：订阅用 external 策略组收纳；节点展开进配置。"
        default:
            return "粘贴节点链接、订阅正文或（若客户端支持）订阅 URL。生成时按该客户端语法写入。"
        }
    }

    // MARK: 服务分组
    var groupState: [String: [String: Any]] { state["groups"] as? [String: [String: Any]] ?? [:] }
    func isOn(_ g: Catalog.Group) -> Bool { (groupState[g.id]?["on"] as? Bool) ?? g.defOn }
    func policy(_ g: Catalog.Group) -> String { (groupState[g.id]?["policy"] as? String) ?? g.def }
    func setGroup(_ g: Catalog.Group, on: Bool? = nil, policy: String? = nil) {
        var gs = groupState
        gs[g.id] = ["on": on ?? isOn(g), "policy": policy ?? self.policy(g)]
        var s = state; s["groups"] = gs; state = s; save()
    }

    var favoriteIds: [String] {
        get { state["favoriteGroups"] as? [String] ?? [] }
        set { set("favoriteGroups", newValue) }
    }
    func toggleFavorite(_ id: String) {
        var f = favoriteIds
        if let i = f.firstIndex(of: id) { f.remove(at: i) } else { f.append(id) }
        favoriteIds = f
    }

    // MARK: 地区
    var regions: [String] { state["regions"] as? [String] ?? [] }
    func toggleRegion(_ id: String) {
        var r = regions
        if let i = r.firstIndex(of: id) { r.remove(at: i) } else { r.append(id) }
        set("regions", r)
    }

    // MARK: 配置名称
    /// 自动名：Lowex-客户端名（去掉括号注释与空格，适合作文件名）
    var autoProfileName: String {
        var n = clientInfo?.name ?? client
        for (l, r) in [("(", ")"), ("（", "）")] {
            while let a = n.range(of: l), let b = n.range(of: r, range: a.upperBound..<n.endIndex) { n.removeSubrange(a.lowerBound..<b.upperBound) }
        }
        n = n.replacingOccurrences(of: " ", with: "")
        return "Lowex-" + n
    }
    var profileNameIsCustom: Bool { (state["profileNameCustom"] as? Bool) == true && !str("profileName").isEmpty }
    var profileName: String {
        get { profileNameIsCustom ? str("profileName") : autoProfileName }
        set {
            let v = newValue.trimmingCharacters(in: .whitespaces)
            var s = state
            if v.isEmpty || v == autoProfileName { s["profileName"] = ""; s["profileNameCustom"] = false }
            else { s["profileName"] = newValue; s["profileNameCustom"] = true }
            state = s; save()
        }
    }

    // MARK: 节点 / 订阅
    var nodesText: String {
        get { str("nodesText") }
        set { var s = state; s["nodesText"] = newValue; state = s }
    }
    var subs: [[String: Any]] { state["subs"] as? [[String: Any]] ?? [] }

    /// 智能粘贴：按客户端能力决定订阅 URL 是否写入方案。
    func applyPaste(_ raw: String) {
        let lines = raw.split(whereSeparator: \.isNewline).map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        var urls: [String] = []
        var body: [String] = []
        for line in lines {
            let low = line.lowercased()
            if low.hasPrefix("http://") || low.hasPrefix("https://") {
                urls.append(line)
            } else {
                body.append(line)
            }
        }
        if body.isEmpty && urls.isEmpty && !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            body = [raw.trimmingCharacters(in: .whitespacesAndNewlines)]
        }
        var s = state

        if family == "shadowrocket" {
            // 不写入配置；仅提示用户去 App 添加
            if !urls.isEmpty {
                UIPasteboard.general.string = urls.joined(separator: "\n")
                pasteNote = "已复制 \(urls.count) 条订阅 URL 到剪贴板。请打开小火箭首页 → 右上角 + → 用「类型：Subscribe」添加。本 conf 不会包含这些 URL。"
            } else if !body.isEmpty {
                UIPasteboard.general.string = body.joined(separator: "\n")
                pasteNote = "已复制节点正文到剪贴板。请在小火箭首页手动添加；本 conf 只含规则与策略组。"
            } else {
                pasteNote = "没有可识别内容。"
            }
            // 清空，避免误以为写进了方案
            s["subs"] = []
            s["nodesText"] = ""
            state = s
            return
        }

        if family == "singbox" {
            // URL 对 sing-box 无用；只收节点正文
            if !urls.isEmpty && body.isEmpty {
                pasteNote = "sing-box / Karing 不能把订阅 URL 写进 JSON。请先在别处下载订阅，把节点链接或 base64 正文粘贴到这里。"
                return
            }
            if !body.isEmpty {
                let joined = body.joined(separator: "\n")
                let old = (s["nodesText"] as? String) ?? ""
                s["nodesText"] = old.isEmpty ? joined : old + "\n" + joined
            }
            s["subs"] = []
            state = s
            if !urls.isEmpty { pasteNote = "其中 \(urls.count) 条订阅 URL 已忽略（sing-box / Karing 不能写订阅 URL）。"; return }
            let nLinks = ((s["nodesText"] as? String) ?? "").split(whereSeparator: \.isNewline).filter { $0.contains("://") }.count
            pasteNote = "已写入节点正文" + (nLinks > 0 ? "（约 \(nLinks) 条链接）" : "") + "，生成时展开进 outbounds。"
            return
        }

        if embedsSub && !urls.isEmpty {
            var cur = (s["subs"] as? [[String: Any]]) ?? []
            for u in urls where !cur.contains(where: { ($0["url"] as? String) == u }) { cur.append(["name": "", "url": u]) }
            s["subs"] = cur
        }
        if !body.isEmpty {
            let joined = body.joined(separator: "\n")
            let old = (s["nodesText"] as? String) ?? ""
            s["nodesText"] = old.isEmpty ? joined : old + "\n" + joined
        }
        if !embedsSub { s["subs"] = [] }
        state = s
        var parts: [String] = []
        if embedsSub && !urls.isEmpty { parts.append("\(urls.count) 条订阅 URL（将写进配置）") }
        let nLinks = ((s["nodesText"] as? String) ?? "").split(whereSeparator: \.isNewline).filter { $0.contains("://") }.count
        if nLinks > 0 { parts.append("约 \(nLinks) 条节点链接") }
        else if !body.isEmpty { parts.append("节点正文") }
        pasteNote = parts.isEmpty ? "没有可识别内容。" : "已写入 " + parts.joined(separator: " · ") + "。"
    }

    func clearNodes() {
        var s = state; s["subs"] = []; s["nodesText"] = ""; state = s
        pasteNote = "已清空节点与订阅。"
        result = GenResult(text: "", name: "", warnings: [])
    }

    func restoreDefaults() {
        let c = client
        var fresh = engine.initialState(client: c, platform: platform)
        fresh["profileName"] = str("profileName")
        fresh["profileNameCustom"] = state["profileNameCustom"] ?? false
        state = fresh
        result = GenResult(text: "", name: "", warnings: [])
        pasteNote = ""
        recommendNote = "已恢复默认选项（保留客户端与配置名）。"
        save()
    }

    // MARK: 推荐 / 生成
    func applyPreset(_ id: String) {
        guard let patched = engine.applyPreset(id: id, state: state) else {
            recommendNote = "预设应用失败。"
            return
        }
        var s = patched
        s["subs"] = state["subs"] ?? []
        s["nodesText"] = state["nodesText"] ?? ""
        s["platform"] = state["platform"] ?? "ios"
        state = s
        reconcile(silent: true)
        recommendNote = "已应用预设。"
    }

    func applyRecommend() {
        let r = engine.recommend(network: str("network"), location: str("location"), platform: str("platform"))
        if let patch = r["patch"] as? [String: Any] {
            var o = opts
            for (k, v) in patch { o[k] = v }
            var s = state; s["opts"] = o; state = s
        }
        if let regs = r["regionsOn"] as? [String] {
            var s = state; s["regions"] = regs; state = s
        }
        let n = (r["list"] as? [[String: Any]])?.count ?? 0
        recommendNote = "已按所选网络与地区应用 \(n) 项推荐。"
        save()
    }

    func generate() {
        generating = true
        defer { generating = false }
        // 文件名用配置名
        let pn = profileName.components(separatedBy: CharacterSet(charactersIn: "/\\:*?\"<>|")).joined(separator: "-")
        if let ext = clientInfo?.fileExt {
            // engine names from client; we rename after
            _ = ext
        }
        result = engine.generate(state: state)
        if result.error == nil, !result.text.isEmpty {
            let ext = (result.name as NSString).pathExtension
            let base = pn.isEmpty ? "lowex" : pn
            result.name = ext.isEmpty ? base : "\(base).\(ext)"
            celebrate += 1
        }
    }

    var adsMode: String {
        if let v = opts["ads"] as? String { return v }
        if let b = opts["ads"] as? Bool { return b ? "lite" : "off" }
        return "lite"
    }
    var blockFlags: String {
        var f: [String] = []
        if adsMode != "off" { f.append("ads:" + adsMode) }
        if (opts["trackers"] as? Bool) ?? true { f.append("trackers") }
        if (opts["telemetry"] as? Bool) ?? true { f.append("telemetry") }
        return f.joined(separator: " · ")
    }

    // MARK: 流程进度
    var hasNodes: Bool { !nodesText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !subs.isEmpty }
    var stepClientDone: Bool { clientInfo != nil && (clientInfo?.platforms.contains(platform) ?? false) }
    /// 小火箭的节点在 App 内添加，这一步对本 App 视为「无需」，计为完成
    var stepNodesDone: Bool { family == "shadowrocket" ? true : hasNodes }
    var stepRulesDone: Bool { catalog.groups.contains { isOn($0) } }
    var stepGenerateDone: Bool { !result.text.isEmpty }
    var activeStep: Int { !stepClientDone ? 1 : (!stepNodesDone ? 2 : (!stepRulesDone ? 3 : 4)) }
    var stepRulesHint: String {
        let on = catalog.groups.filter { isOn($0) }.count
        return "\(on)/\(catalog.groups.count) 分组开"
    }
}
