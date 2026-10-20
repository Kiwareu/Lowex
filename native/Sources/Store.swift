import SwiftUI
import Foundation
import UIKit

/// 方案以 [String: Any] 保存，字段与网页版 / 引擎一致，方案 JSON 可互通。
final class Store: ObservableObject {
    let engine = Engine.shared
    @Published var catalog: Catalog
    @Published var state: [String: Any] {
        didSet {
            if !result.text.isEmpty || result.error != nil { result = GenResult(text: "", name: "", warnings: []); validationIssues = [] }
            scheduleSave()
        }
    }
    @Published var result = GenResult(text: "", name: "", warnings: [])
    @Published var recommendNote = ""
    @Published var recommendList: [[String: Any]] = []
    @Published var tab: AppTab = .home
    @Published var generating = false
    @Published var pasteNote = ""
    @Published var showDisclaimer = false
    @Published var showSplash = true
    @Published var showAppearance = false
    @Published var celebrate = 0
    @Published var remoteURL = ""
    @Published var qrNote = ""
    @Published var validationIssues: [Engine.ValidationIssue] = []
    // 远程 JS（独立模块，与生成配置互不影响；存在 UserDefaults，不进方案 state，避免污染生成）
    @Published var remoteJsMode = false
    @Published var remoteJsURL = ""
    @Published var remoteJsSHA256 = ""
    @Published var remoteJsName = ""
    @Published var remoteJsMITM = ""
    @Published var remoteJsConfirmSensitive = false
    @Published var remoteJsKind = "" // config-override / config-overwrite / http-rewrite（空=自动取当前客户端第一个支持的）
    // 脚本库：用户自己收藏的脚本（UserDefaults 持久化，字段 id/name/url/author/sourceKind/desc/kind）
    @Published var libraryCustom: [[String: String]] = []
    private var needsDisclaimer = false

    private let key = "lowex.native.state.v3"
    private let disclaimerKey = "lowex.native.disclaimer.accepted.v1"

    init() {
        IconCache.purgeIfUpgraded()
        Engine.shared.setIconsReady(UserDefaults.standard.stringArray(forKey: Store.iconsReadyKey) ?? [])
        let cat = Engine.shared.catalog()
        catalog = cat
        Store.refreshReadyIcons()
        let accepted = UserDefaults.standard.bool(forKey: disclaimerKey)
        needsDisclaimer = !accepted
        if let d = UserDefaults.standard.data(forKey: key),
           let s = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] {
            var merged = s
            // 订阅 / 粘贴的节点单独存在沙盒私有文件里（见 save()），这里读回来：重启后不再丢失
            let sec = LocalFile.read(Store.secretFile).flatMap { (try? JSONSerialization.jsonObject(with: $0)) as? [String: Any] }
            merged["subs"] = (sec?["subs"] as? [[String: Any]]) ?? []
            merged["nodesText"] = (sec?["nodesText"] as? String) ?? ""
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
            // v1.7.0：DNSPod 官方不再公开 1.12.12.12 的 IP 接入，旧设置里的该地址换成 doh.pub
            if let cn = o["dnsCn"] as? [String], cn.contains("https://1.12.12.12/dns-query") {
                o["dnsCn"] = cn.map { $0 == "https://1.12.12.12/dns-query" ? "https://doh.pub/dns-query" : $0 }
            }
            merged["opts"] = o
            if let ml = merged["manualNodes"] as? [[String: Any]] {
                merged["manualNodes"] = ml.map { var m = $0; m["pass"] = SecretStore.get(m["id"] as? String ?? ""); return m }
            }
            state = merged
            reconcile(silent: true)
        } else {
            let first = cat.clients.first(where: { $0.id == "shadowrocket" })?.id
                ?? cat.clients.first?.id ?? "shadowrocket"
            state = Engine.shared.initialState(client: first, platform: "ios")
        }
        loadRemoteJs()
        loadSubHistory()
    }

    static let iconsReadyKey = "lowex.icons.ready.v1"
    /// 启动时列出 github.com/Kiwareu/Lowex-Icons 的 icons/ 目录，已上传的组图标会替换旧图 / 占位图（失败时静默沿用上次结果）
    static func refreshReadyIcons() {
        guard let url = URL(string: "https://api.github.com/repos/Kiwareu/Lowex-Icons/contents/icons") else { return }
        var req = URLRequest(url: url, timeoutInterval: 10)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: req) { data, resp, _ in
            guard (resp as? HTTPURLResponse)?.statusCode == 200, let data,
                  let arr = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] else { return }
            let ids = arr.compactMap { $0["name"] as? String }
                .filter { $0.hasSuffix(".png") && !$0.hasPrefix("_") }
                .map { String($0.dropLast(4)) }
            DispatchQueue.main.async {
                UserDefaults.standard.set(ids, forKey: iconsReadyKey)
                Engine.shared.setIconsReady(ids)
            }
        }.resume()
    }

    /// 切换界面语言后：重新取目录（组名 / 说明等由引擎提供的文案按新语言翻译）
    func reloadLanguage() {
        catalog = engine.catalog()
        objectWillChange.send()
    }

    func finishSplash() {
        showSplash = false
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
        Haptics.selection()
        var s = state; s[k] = v; state = s; save()
    }
    var opts: [String: Any] { state["opts"] as? [String: Any] ?? [:] }
    func setOpts(_ d: [String: Any]) {
        Haptics.selection()
        var o = opts
        for (k, v) in d { o[k] = v }
        var s = state; s["opts"] = o; state = s; save()
    }
    func setOpt(_ k: String, _ v: Any) {
        Haptics.selection()
        var o = opts; o[k] = v
        var s = state; s["opts"] = o; state = s; save()
    }
    static let secretFile = "nodes-private.json"
    private var saveWork: DispatchWorkItem?
    /// 合并连续修改（如输入框逐字输入），稍后一次写盘；进入后台时会立刻 flush
    func scheduleSave() {
        saveWork?.cancel()
        let w = DispatchWorkItem { [weak self] in self?.save() }
        saveWork = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: w)
    }
    func flushSave() { saveWork?.cancel(); save(); LocalFile.flush() }
    func save() {
        var s = state
        let secret: [String: Any] = ["subs": (s["subs"] as? [[String: Any]]) ?? [], "nodesText": (s["nodesText"] as? String) ?? ""]
        if JSONSerialization.isValidJSONObject(secret), let d = try? JSONSerialization.data(withJSONObject: secret) { LocalFile.write(d, Store.secretFile) }
        s["subs"] = []
        s["nodesText"] = ""
        // 手动节点密码不进 UserDefaults：单独存钥匙串（见 SecretStore）
        if let ml = s["manualNodes"] as? [[String: Any]] {
            s["manualNodes"] = ml.map { var m = $0; m["pass"] = nil; return m }
        }
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
        // sing-box 系在手机上只有 TUN 入站，没有本地混合端口 / 局域网监听
        if (feature == "localPort" || feature == "allowLan"), family == "singbox", isMobilePlatform { return false }
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
            ("icons", "icons"), ("ipv6", "ipv6"), ("tun", "tun"), ("fakeIp", "fakeIp"), ("blockQuic", "quic"), ("stun", "stun"), ("cnDnsMode", "cnDnsMode"),
            ("allowLan", "allowLan"), ("wifiCalling", "wifi")]
        var reset: [String] = []
        for (k, f) in map where !supports(f) {
            // sing-box 的 failover 开关 = 分层预设 A/B 选择（A 降级为地区-自动），有实际意义，不重置
            if k == "failover" && family == "singbox" { continue }
            if let d = defOpts[k], "\(o[k] ?? "")" != "\(d)" { o[k] = d; reset.append(k) }
            else if o[k] == nil, let d = defOpts[k] { o[k] = d }
        }
        if !supports("wifi") { o["wifiCalling"] = false }
        s["opts"] = o
        if !nodeModeChoice, (s["nodeMode"] as? String) == "app" { s["nodeMode"] = "config" }
        if !reset.isEmpty { notes.append(L("{} 个当前客户端不支持的选项已恢复默认", reset.count)) }
        // 按应用规则：进程名只属于 Windows，包名只属于 Android
        let apps = (s["apps"] as? [[String: Any]]) ?? []
        let kept = apps.filter { a in
            switch a["kind"] as? String {
            case "process": return platform == "windows" && (clientInfo?.processRules ?? false)
            case "package": return platform == "android" && (clientInfo?.processRules ?? false)
            default: return true
            }
        }
        if kept.count != apps.count { s["apps"] = kept; notes.append(L("{} 条不适用本系统的按应用规则已移除", apps.count - kept.count)) }
        // 模块只属于支持模块的客户端
        if !engine.supportsModules(client: client), let m = s["modules"] as? [Any], !m.isEmpty {
            s["modules"] = []; notes.append(L("模块已清空（当前客户端不支持）"))
        }
        state = s
        result = GenResult(text: "", name: "", warnings: [])
        pasteNote = ""
        qrNote = ""
        if !silent {
            recommendNote = notes.isEmpty ? "" : L("已按「{}」调整：", clientInfo?.name ?? client) + notes.joined(separator: "；") + "。"
        }
        save()
    }
    var buildNumber: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?" }
    var shortVersion: String { var v = appVersion; while v.hasSuffix(".0") { v.removeLast(2) }; return v }
    var versionLabel: String { "v\(shortVersion)" }
    var appVersion: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.1.0" }

    /// 当前客户端是否把订阅 URL 写进配置文件
    var embedsSub: Bool { clientInfo?.embedsSubscription ?? false }
    var family: String { clientInfo?.family ?? "" }

    var nodeModeHint: String {
        switch family {
        case "shadowrocket":
            return L("Shadowrocket 特殊：节点/订阅必须在 App「首页」单独添加，本配置只写规则与策略组（用正则按地区名收纳首页节点）。此处粘贴不会写进 .conf。")
        case "singbox":
            return L("sing-box / Karing 无订阅字段：请粘贴节点链接（ss://、vmess://、vless://、trojan:// 等）或订阅正文；单独的 https 订阅 URL 无法写进 JSON。")
        case "surge":
            return L("Surge：订阅 URL 会写成 policy-path；节点链接会展开进 [Proxy]。也可导入后在 Surge 里再加订阅。")
        case "qx":
            return L("Quantumult X：订阅写在 [server_remote]；节点写在 [server_local]。")
        case "loon":
            return L("Loon：订阅写在 [Remote Proxy]；节点写在 [Proxy]。")
        case "stash", "mihomo":
            return L("Clash / Mihomo / Stash：订阅写成 proxy-providers；节点展开进 proxies。")
        case "egern":
            return L("Egern：订阅用 external 策略组收纳；节点展开进配置。")
        default:
            return L("粘贴节点链接、订阅正文或（若客户端支持）订阅 URL。生成时按该客户端语法写入。")
        }
    }

    // MARK: 服务分组
    var groupState: [String: [String: Any]] { state["groups"] as? [String: [String: Any]] ?? [:] }
    func isOn(_ g: Catalog.Group) -> Bool { (groupState[g.id]?["on"] as? Bool) ?? g.defOn }
    func policy(_ g: Catalog.Group) -> String { (groupState[g.id]?["policy"] as? String) ?? g.def }
    func setGroup(_ g: Catalog.Group, on: Bool? = nil, policy: String? = nil) {
        Haptics.selection()
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
    /// 订阅历史（防误删：用户贴过的订阅 URL，持久化，可逐条恢复；最多 30 条）
    private let subHistoryKey = "lowex.subs.history.v1"
    @Published var subHistory: [String] = []
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
                pasteNote = L("已复制 {} 条订阅 URL 到剪贴板。请打开 Shadowrocket 首页 → 右上角 + → 用「类型：Subscribe」添加。本 conf 不会包含这些 URL。", urls.count)
            } else if !body.isEmpty {
                UIPasteboard.general.string = body.joined(separator: "\n")
                pasteNote = L("已复制节点正文到剪贴板。请在 Shadowrocket 首页手动添加；本 conf 只含规则与策略组。")
            } else {
                pasteNote = L("没有可识别内容。")
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
                pasteNote = L("sing-box / Karing 不能把订阅 URL 写进 JSON。请先在别处下载订阅，把节点链接或 base64 正文粘贴到这里。")
                return
            }
            if !body.isEmpty {
                let joined = body.joined(separator: "\n")
                let old = (s["nodesText"] as? String) ?? ""
                s["nodesText"] = old.isEmpty ? joined : old + "\n" + joined
            }
            s["subs"] = []
            state = s
            if !urls.isEmpty { pasteNote = L("其中 {} 条订阅 URL 已忽略（sing-box / Karing 不能写订阅 URL）。", urls.count); return }
            let nLinks = ((s["nodesText"] as? String) ?? "").split(whereSeparator: \.isNewline).filter { $0.contains("://") }.count
            pasteNote = L("已写入节点正文") + (nLinks > 0 ? L("（约 {} 条链接）", nLinks) : "") + L("，生成时展开进 outbounds。")
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
        if embedsSub && !urls.isEmpty { parts.append(L("{} 条订阅 URL（将写进配置）", urls.count)) }
        let nLinks = ((s["nodesText"] as? String) ?? "").split(whereSeparator: \.isNewline).filter { $0.contains("://") }.count
        if nLinks > 0 { parts.append(L("约 {} 条节点链接", nLinks)) }
        else if !body.isEmpty { parts.append(L("节点正文")) }
        pasteNote = parts.isEmpty ? L("没有可识别内容。") : L("已写入 ") + parts.joined(separator: " · ") + "。"
    }

    func clearNodes() {
        var s = state; s["subs"] = []; s["nodesText"] = ""; state = s
        pasteNote = L("已清空节点与订阅。")
        result = GenResult(text: "", name: "", warnings: [])
    }

    /// 只清除已生成的结果（选项、节点、订阅都保留）
    func clearResult() {
        result = GenResult(text: "", name: "", warnings: [])
        validationIssues = []
        remoteURL = ""
        qrNote = ""
    }

    /// 清除结果并把规则 / 分组 / 功能选项恢复默认（保留节点、订阅、手动节点、客户端与配置名）
    func resetSelections() {
        restoreDefaults()
        remoteURL = ""
        qrNote = ""
    }

    /// 全部恢复默认：选项、节点、订阅、手动节点、历史记录都清空（外观与语言不动）
    func resetEverything() {
        for m in manualNodes { if let id = m["id"] as? String { SecretStore.remove(id) } }
        HistoryStore.shared.clear()
        var fresh = engine.initialState(client: client, platform: platform)
        fresh["manualNodes"] = []
        state = fresh
        result = GenResult(text: "", name: "", warnings: [])
        validationIssues = []
        pasteNote = ""; remoteURL = ""; qrNote = ""
        recommendNote = L("已恢复全部默认设置。")
        flushSave()
    }

    func restoreDefaults() {
        let c = client
        var fresh = engine.initialState(client: c, platform: platform)
        fresh["profileName"] = str("profileName")
        fresh["manualNodes"] = state["manualNodes"] ?? []
        fresh["profileNameCustom"] = state["profileNameCustom"] ?? false
        fresh["subs"] = state["subs"] ?? []
        fresh["nodesText"] = state["nodesText"] ?? ""
        fresh["favoriteGroups"] = state["favoriteGroups"] ?? []
        state = fresh
        result = GenResult(text: "", name: "", warnings: [])
        validationIssues = []
        pasteNote = ""
        recommendNote = L("已恢复默认选项（保留客户端与配置名）。")
        save()
    }

    // MARK: 推荐 / 生成
    /// 校验错误（非警告）存在时，导出与导入必须阻止（警告不阻止）
    var hasValidationErrors: Bool { validationIssues.contains { $0.isError } }
    func applyPreset(_ id: String) {
        guard let patched = engine.applyPreset(id: id, state: state) else {
            recommendNote = L("预设应用失败。")
            return
        }
        var s = patched
        s["subs"] = state["subs"] ?? []
        s["nodesText"] = state["nodesText"] ?? ""
        s["manualNodes"] = state["manualNodes"] ?? []
        s["platform"] = state["platform"] ?? "ios"
        state = s
        reconcile(silent: true)
        recommendNote = L("已应用预设。")
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
        recommendList = (r["list"] as? [[String: Any]]) ?? []
        let n = recommendList.count
        recommendNote = L("已按所选网络与地区应用 {} 项推荐。", n)
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
        validationIssues = (result.error == nil && !result.text.isEmpty) ? engine.validateConfig(family: family, text: result.text) : []
        if result.error == nil, !result.text.isEmpty {
            let ext = (result.name as NSString).pathExtension
            let base = pn.isEmpty ? "lowex" : pn
            result.name = ext.isEmpty ? base : "\(base).\(ext)"
            celebrate += 1
            recordHistory()
        }
    }

    // MARK: 远程 JS（独立模块，与生成配置互不影响）
    func saveRemoteJs() {
        let d = UserDefaults.standard
        d.set(remoteJsMode, forKey: "lowex.remoteJs.mode.v1")
        d.set(remoteJsURL, forKey: "lowex.remoteJs.url.v1")
        d.set(remoteJsSHA256, forKey: "lowex.remoteJs.sha256.v1")
        d.set(remoteJsName, forKey: "lowex.remoteJs.name.v1")
        d.set(remoteJsMITM, forKey: "lowex.remoteJs.mitm.v1")
        d.set(remoteJsConfirmSensitive, forKey: "lowex.remoteJs.confirmSensitive.v1")
        d.set(remoteJsKind, forKey: "lowex.remoteJs.kind.v1")
    }
    private func loadRemoteJs() {
        let d = UserDefaults.standard
        remoteJsMode = d.bool(forKey: "lowex.remoteJs.mode.v1")
        remoteJsURL = d.string(forKey: "lowex.remoteJs.url.v1") ?? ""
        remoteJsSHA256 = d.string(forKey: "lowex.remoteJs.sha256.v1") ?? ""
        remoteJsName = d.string(forKey: "lowex.remoteJs.name.v1") ?? ""
        remoteJsMITM = d.string(forKey: "lowex.remoteJs.mitm.v1") ?? ""
        remoteJsConfirmSensitive = d.bool(forKey: "lowex.remoteJs.confirmSensitive.v1")
        remoteJsKind = d.string(forKey: "lowex.remoteJs.kind.v1") ?? ""
        libraryCustom = UserDefaults.standard.array(forKey: "lowex.library.custom.v1") as? [[String: String]] ?? []
    }
    /// 脚本库：添加用户收藏（id 用 UUID）
    func addLibraryCustom(name: String, url: String, author: String, sourceKind: String, desc: String, kind: String) {
        var e: [String: String] = [:]
        e["id"] = UUID().uuidString
        e["name"] = name
        e["url"] = url
        e["author"] = author
        e["sourceKind"] = sourceKind // "original" 原创 / "shared" 分享
        e["desc"] = desc
        e["kind"] = kind
        libraryCustom.append(e)
        UserDefaults.standard.set(libraryCustom, forKey: "lowex.library.custom.v1")
    }
    func removeLibraryCustom(id: String) {
        libraryCustom.removeAll { $0["id"] == id }
        UserDefaults.standard.set(libraryCustom, forKey: "lowex.library.custom.v1")
    }
    var presetMode: String { engine.presetMode(state: state) }
    var remoteJsSupport: Engine.RemoteJsSupport { engine.remoteJsSupport(client: client) }
    /// 当前选中的覆写类型：用户显式选的优先，否则取当前客户端第一个支持的
    var remoteJsActiveKind: String {
        let sup = remoteJsSupport
        if !remoteJsKind.isEmpty, sup.kinds.contains(where: { $0.kind == remoteJsKind && $0.supported }) { return remoteJsKind }
        return sup.kinds.first(where: { $0.supported })?.kind ?? ""
    }
    var quicTierText: String {
        switch engine.tiers(client: client).quic {
        case "precise": return L("精确拦境外：境内 QUIC 不受影响")
        case "global-drop": return L("只能全局丢：国内 QUIC 也会一起丢，浏览器回落 TCP")
        case "not-generated": return L("该客户端不生成 QUIC 规则")
        default: return ""
        }
    }
    var stunTierText: String {
        switch engine.tiers(client: client).stun {
        case "port": return L("按端口逐个拦（3478-3479 / 5349 / 19302-19309）")
        case "protocol": return L("按 PROTOCOL,STUN（全端口）")
        case "drop-only": return L("仅丢 UDP（QX udp_drop_list）")
        default: return ""
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

    /// 同时支持「写入配置」与「在客户端 App 内自己添加」的客户端（QX、Shadowrocket）
    var nodeModeChoice: Bool { clientInfo?.placement == "both" }
    var nodeMode: String { nodeModeChoice && str("nodeMode") == "app" ? "app" : "config" }
    var appMode: Bool { nodeMode == "app" }
    /// 当前模式下「如何导入到客户端」的步骤（来自调研数据）
    var importHow: String? {
        let h = appMode ? clientInfo?.howApp : clientInfo?.howConfig
        if let h, !h.isEmpty { return h }
        return clientInfo?.importHint
    }
    func setNodeMode(_ m: String) {
        Haptics.selection()
        var s = state; s["nodeMode"] = m; state = s
        pasteNote = ""; save()
    }
    var unsupportedOptionNames: [String] {
        let all: [(String, String)] = [(L("故障转移"), "failover"), (L("广告拦截"), "ads"), (L("拦截追踪器"), "trackers"), (L("拦截遥测"), "telemetry"),
            (L("策略组图标"), "icons"), (L("关闭 IPv6"), "ipv6"), ("TUN", "tun"), ("fake-ip", "fakeIp"), (L("QUIC 拦截"), "quic"), (L("STUN 防护"), "stun"),
            (L("局域网连接"), "allowLan"), (L("Wi-Fi 通话"), "wifi")]
        return all.filter { ($0.1 == "failover" && family == "singbox") ? false : !supports($0.1) }.map { $0.0 }
    }

    // MARK: 手动节点（SOCKS5 / HTTP / HTTPS）
    var manualNodes: [[String: Any]] { state["manualNodes"] as? [[String: Any]] ?? [] }
    private func commitManual(_ list: [[String: Any]]) {
        var s = state; s["manualNodes"] = list; state = s; save()
    }
    func upsertManual(_ n: [String: Any]) {
        var list = manualNodes
        let id = n["id"] as? String ?? UUID().uuidString
        var m = n; m["id"] = id
        SecretStore.set(m["pass"] as? String ?? "", id: id)
        if let i = list.firstIndex(where: { ($0["id"] as? String) == id }) { list[i] = m } else { list.append(m) }
        commitManual(list)
    }
    func removeManual(_ id: String) {
        SecretStore.remove(id)
        commitManual(manualNodes.filter { ($0["id"] as? String) != id })
    }
    func toggleManual(_ id: String) {
        commitManual(manualNodes.map { var m = $0; if (m["id"] as? String) == id { m["on"] = !((m["on"] as? Bool) ?? true) }; return m })
    }
    func manualIssue(_ n: [String: Any]) -> String? { engine.manualIssue(client: client, node: n) }
    var manualActiveCount: Int { manualNodes.filter { (($0["on"] as? Bool) ?? true) && manualIssue($0) == nil }.count }
    var manualBlockedCount: Int { manualNodes.filter { (($0["on"] as? Bool) ?? true) && manualIssue($0) != nil }.count }
    var manualCaps: Engine.ManualCap? { engine.manualMatrix().first { $0.id == client } }

    /// 只收订阅 URL（A 区）
    func addSubscriptions(_ raw: String) {
        let lines = raw.split(whereSeparator: \.isNewline).map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let urls = lines.filter { $0.lowercased().hasPrefix("http://") || $0.lowercased().hasPrefix("https://") }
        let other = lines.count - urls.count
        if urls.isEmpty { pasteNote = L("没有识别到 http(s):// 订阅 URL") + (other > 0 ? L("；节点链接请粘贴到下面的「节点链接」区。") : "。"); return }
        recordSubHistory(urls)
        applyPaste(urls.joined(separator: "\n"))
        if other > 0 { pasteNote += L("（另有 {} 行不是订阅 URL，已忽略，节点链接请放到「节点链接」区。）", other) }
    }
    func removeSub(_ i: Int) {
        var s = state; var cur = (s["subs"] as? [[String: Any]]) ?? []
        guard cur.indices.contains(i) else { return }
        cur.remove(at: i); s["subs"] = cur; state = s
    }
    private func loadSubHistory() {
        subHistory = UserDefaults.standard.stringArray(forKey: subHistoryKey) ?? []
    }
    private func saveSubHistory() {
        UserDefaults.standard.set(subHistory, forKey: subHistoryKey)
    }
    /// 记录用户贴过的订阅 URL：去重、最新在前、最多 30 条（无论客户端家族都记录）
    func recordSubHistory(_ urls: [String]) {
        var h = subHistory
        for u in urls { h.removeAll { $0 == u }; h.insert(u, at: 0) }
        subHistory = Array(h.prefix(30))
        saveSubHistory()
    }
    /// 从历史恢复一条订阅到上方列表
    func restoreSub(_ url: String) {
        let urls = subs.compactMap { $0["url"] as? String }
        if urls.contains(url) { pasteNote = L("该订阅已在列表中"); return }
        if family == "shadowrocket" {
            UIPasteboard.general.string = url
            pasteNote = L("已复制订阅 URL 到剪贴板。请打开 Shadowrocket 首页 → 右上角 + → 用「类型：Subscribe」添加。")
            return
        }
        var s = state; var cur = (s["subs"] as? [[String: Any]]) ?? []
        cur.append(["name": "", "url": url])
        s["subs"] = cur; state = s
        pasteNote = L("已恢复导入 1 条订阅")
    }
    func removeSubHistory(at i: Int) {
        guard subHistory.indices.contains(i) else { return }
        subHistory.remove(at: i); saveSubHistory()
    }
    func clearSubHistory() { subHistory = []; saveSubHistory() }
    func clearNodeText() { var s = state; s["nodesText"] = ""; state = s; pasteNote = L("已清空节点链接。") }

    // MARK: 流程进度
    var hasNodes: Bool { !nodesText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !subs.isEmpty || manualActiveCount > 0 }
    var stepClientDone: Bool { clientInfo != nil && (clientInfo?.platforms.contains(platform) ?? false) }
    /// Shadowrocket 的节点在 App 内添加，这一步对本 App 视为「无需」，计为完成
    var stepNodesDone: Bool { (family == "shadowrocket" || appMode) ? true : hasNodes }
    var stepRulesDone: Bool { catalog.groups.contains { isOn($0) } }
    var stepGenerateDone: Bool { !result.text.isEmpty }
    var activeStep: Int { !stepClientDone ? 1 : (!stepNodesDone ? 2 : (!stepRulesDone ? 3 : 4)) }
    var stepRulesHint: String {
        let on = catalog.groups.filter { isOn($0) }.count
        return L("{}/{} 分组开", on, catalog.groups.count)
    }
}
