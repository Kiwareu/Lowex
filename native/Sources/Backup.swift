import SwiftUI
import UniformTypeIdentifiers

/// 偏好（外观 / 语言 / 规则页显示方式）的备份与恢复。壁纸图片不在备份里。
enum PrefsBackup {
    static let keys = ["ap.mode", "ap.accent", "ap.radius", "ap.glass", "ap.speed", "ap.font", "ap.haptics", "ap.perf", "ap.density", "lowex.lang.choice.v1",
                       "ap.bgstyle", "ap.bgkind", "ap.bgangle", "ap.drift", "ap.bg1", "ap.bg2", "ap.bg3", "ap.wpdim"]
    static func snapshot() -> [String: Any] {
        var d: [String: Any] = [:]
        for k in keys { if let v = UserDefaults.standard.object(forKey: k) { d[k] = v } }
        return d
    }
    static func apply(_ d: [String: Any]) {
        let ap = Appearance.shared
        if let v = d["ap.mode"] as? String, let m = Appearance.Mode(rawValue: v) { ap.mode = m }
        if let v = d["ap.accent"] as? Int { ap.accentIndex = v }
        if let v = d["ap.radius"] as? Double { ap.cornerRadius = CGFloat(v) }
        if let v = d["ap.glass"] as? Double { ap.glassIntensity = v }
        if let v = d["ap.speed"] as? Double { ap.gradientSpeed = v }
        if let v = d["ap.font"] as? String, let f = Appearance.FontStyle(rawValue: v) { ap.fontStyle = f }
        if let v = d["ap.haptics"] as? Bool { ap.haptics = v }
        if let v = d["ap.perf"] as? Bool { ap.performanceMode = v }
        if let v = d["ap.density"] as? String, let m = LayoutDensity(rawValue: v) { LayoutPrefs.shared.density = m }
        if let v = d["lowex.lang.choice.v1"] as? String, let l = AppLang(rawValue: v) { Lang.shared.choice = l }
        if let v = d["ap.bgstyle"] as? String, let b = Appearance.BgStyle(rawValue: v) { ap.bgStyle = b }
        if let v = d["ap.bgkind"] as? String, let b = Appearance.BgKind(rawValue: v) { ap.bgKind = b }
        if let v = d["ap.bgangle"] as? Double { ap.bgAngle = v }
        if let v = d["ap.drift"] as? Double { ap.bgDrift = v }
        if let v = d["ap.bg1"] as? String { ap.bgHex1 = v }
        if let v = d["ap.bg2"] as? String { ap.bgHex2 = v }
        if let v = d["ap.bg3"] as? String { ap.bgHex3 = v }
        if let v = d["ap.wpdim"] as? Double { ap.wallpaperDim = v }
    }
}

/// 远程覆写设置 + 脚本库自定义条目（存在 UserDefaults 里）的备份与恢复。
enum RemoteBackup {
    static let keys = ["lowex.remoteJs.mode.v1", "lowex.remoteJs.url.v1", "lowex.remoteJs.sha256.v1", "lowex.remoteJs.name.v1",
                       "lowex.remoteJs.mitm.v1", "lowex.remoteJs.confirmSensitive.v1", "lowex.remoteJs.kind.v1", "lowex.library.custom.v1"]
    static func snapshot() -> [String: Any] {
        var d: [String: Any] = [:]
        for k in keys { if let v = UserDefaults.standard.object(forKey: k) { d[k] = v } }
        return d
    }
    static func apply(_ d: [String: Any], store: Store) {
        for k in keys { if let v = d[k] { UserDefaults.standard.set(v, forKey: k) } }
        store.loadRemoteJs()
    }
}

/// Lowex 备份 / 恢复（本地 JSON 文件，不依赖 iCloud，不经过任何服务器）。
/// v3：按类别组织（方案设置 / 订阅与历史 / 节点 / 生成历史 / 外观偏好 / 远程覆写），导出与导入都可逐类勾选。
/// v1 / v2 旧备份仍可导入（没有类别清单时按文件实际内容推断）。
struct BackupView: View {
    @EnvironmentObject var store: Store
    @ObservedObject private var hs = HistoryStore.shared
    @State private var exportFile: ShareFile?
    @State private var shareFile: ShareFile?
    @State private var importing = false
    @State private var note = ""
    @State private var pending: [String: Any]?
    @State private var pendingInfo = ""
    @State private var pendingParts: [String] = []
    @State private var restoreSel: Set<String> = []
    @State private var confirmRestore = false
    // 导出类别勾选（默认全选 = 完整备份）
    @State private var exSettings = true
    @State private var exSubs = true
    @State private var exNodes = true
    @State private var exHistory = true
    @State private var exPrefs = true
    @State private var exRemote = true
    static let formatVersion = 3

    struct PartDef: Identifiable { let key: String; let label: String; let detail: String; var id: String { key } }
    static let partDefs: [PartDef] = [
        PartDef(key: "settings", label: "方案设置与选项", detail: "系统、客户端、分组、地区、全部生成选项、配置名"),
        PartDef(key: "subs", label: "订阅链接与历史", detail: "订阅链接（含自定义名称）和订阅历史记录"),
        PartDef(key: "nodes", label: "节点", detail: "粘贴的节点链接正文与手动添加的节点（含密码）"),
        PartDef(key: "history", label: "配置生成历史", detail: "生成过的配置文件历史记录"),
        PartDef(key: "prefs", label: "外观与偏好", detail: "主题、背景、强调色、字体、语言等偏好（壁纸图片除外）"),
        PartDef(key: "remote", label: "远程覆写与脚本库", detail: "远程覆写设置与脚本库里你自加的条目"),
    ]

    private var exportSel: Set<String> {
        var s: Set<String> = []
        if exSettings { s.insert("settings") }
        if exSubs { s.insert("subs") }
        if exNodes { s.insert("nodes") }
        if exHistory { s.insert("history") }
        if exPrefs { s.insert("prefs") }
        if exRemote { s.insert("remote") }
        return s
    }

    private func backupObject(parts: Set<String>) -> [String: Any] {
        store.flushSave()
        var o: [String: Any] = ["lowexBackup": Self.formatVersion, "app": store.versionLabel, "build": store.buildNumber,
                                "created": ISO8601DateFormatter().string(from: Date()), "parts": parts.sorted()]
        if parts.contains("settings") || parts.contains("subs") || parts.contains("nodes") {
            var s: [String: Any] = [:]
            if parts.contains("settings") {
                for (k, v) in store.state where !["subs", "nodesText", "manualNodes"].contains(k) { s[k] = v }
            }
            if parts.contains("subs") { s["subs"] = store.subs }
            if parts.contains("nodes") { s["nodesText"] = store.nodesText; s["manualNodes"] = store.manualNodes }
            o["state"] = s
        }
        if parts.contains("subs") { o["subHistory"] = store.exportSubHistory() }
        if parts.contains("prefs") { o["prefs"] = PrefsBackup.snapshot() }
        if parts.contains("history") { o["history"] = hs.exportObject() }
        if parts.contains("remote") { o["remote"] = RemoteBackup.snapshot() }
        return o
    }
    private func backupText(parts: Set<String>) -> String {
        let d = (try? JSONSerialization.data(withJSONObject: backupObject(parts: parts), options: [.prettyPrinted, .sortedKeys])) ?? Data()
        return String(data: d, encoding: .utf8) ?? "{}"
    }
    private var fileName: String {
        let f = DateFormatter(); f.dateFormat = "yyyyMMdd-HHmm"; f.locale = Locale(identifier: "en_US_POSIX")
        return "Lowex-backup-\(f.string(from: Date())).json"
    }
    private func makeFile() -> ShareFile? {
        if exportSel.isEmpty { note = L("至少勾选一类再导出"); return nil }
        if let u = TempFile.make(name: fileName, text: backupText(parts: exportSel), fallback: "Lowex-backup.json") { return ShareFile(url: u) }
        note = L("写临时文件失败"); return nil
    }

    private func partBinding(_ key: String) -> Binding<Bool> {
        switch key {
        case "settings": return $exSettings
        case "subs": return $exSubs
        case "nodes": return $exNodes
        case "history": return $exHistory
        case "prefs": return $exPrefs
        default: return $exRemote
        }
    }
    private func partCount(_ key: String) -> String {
        switch key {
        case "subs": return L("{} 条", store.subs.count + store.subHistory.count)
        case "nodes": return L("{} 个手动节点", store.manualNodes.count)
        case "history": return L("{} 条", hs.entries.count)
        case "remote": return L("{} 条自加脚本", store.libraryCustom.count)
        default: return ""
        }
    }

    var body: some View {
        PageChrome(title: L("备份与恢复")) {
            PlainCard {
                Text(L("导出备份")).font(.headline)
                Text(L("勾选要备份的类别，存成一个 JSON 文件。全部勾选就是完整备份：软件里你留下的设置、订阅、节点、历史和偏好都在里面。换机或重装后导入即可恢复。"))
                    .font(.footnote).foregroundStyle(.secondary)
                Label(L("备份文件含订阅链接和节点密码，等同于账号凭据：只放在你信任的地方，不要发给别人或传到公开网盘。Lowex 不会把它上传到任何服务器。"), systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundStyle(.orange)
                ForEach(Self.partDefs) { pd in
                    Toggle(isOn: partBinding(pd.key)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(L(pd.label)).font(.subheadline)
                                Text(L(pd.detail)).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(partCount(pd.key)).font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
                HStack {
                    Button(L("全选")) { exSettings = true; exSubs = true; exNodes = true; exHistory = true; exPrefs = true; exRemote = true }.font(.caption)
                    Button(L("全不选")) { exSettings = false; exSubs = false; exNodes = false; exHistory = false; exPrefs = false; exRemote = false }.font(.caption)
                    Spacer()
                }
                HStack {
                    Button { if let f = makeFile() { exportFile = f } } label: { Label(L("导出备份"), systemImage: "square.and.arrow.up") }
                        .buttonStyle(.borderedProminent).tint(Brand.pink)
                    Button { importing = true } label: { Label(L("导入备份"), systemImage: "square.and.arrow.down") }.buttonStyle(.bordered)
                    Button { if let f = makeFile() { shareFile = f } } label: { Label(L("分享"), systemImage: "square.and.arrow.up.on.square") }.buttonStyle(.bordered)
                }
                if !note.isEmpty { Text(note).font(.caption).foregroundStyle(.secondary) }
            }
            PlainCard {
                Text(L("说明")).font(.headline)
                Text(L("• 只读取 Lowex 自己导出的文件；会先校验格式，未知字段会被忽略。\n• 导入时先显示备份包含的类别，逐类勾选后，再选「覆盖」或「合并」，确认后才会改动。\n• 恢复后会按所选系统 / 客户端自动校正不支持的选项。\n• 壁纸图片不在备份里。\n• 旧版（v1 / v2）备份仍可导入。"))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .sheet(item: $shareFile) { ActivityView(items: [$0.url]) }
        .sheet(item: $exportFile) { f in
            DocumentExporter(url: f.url) { ok in exportFile = nil; note = ok ? L("已保存备份到「文件」") : L("已取消") }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json, .plainText]) { r in
            switch r {
            case .failure(let e): note = L("导入失败：{}", e.localizedDescription)
            case .success(let url):
                let ok = url.startAccessingSecurityScopedResource(); defer { if ok { url.stopAccessingSecurityScopedResource() } }
                guard let d = try? Data(contentsOf: url), let o = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { note = L("不是 Lowex 备份文件"); return }
                switch Store.validateBackup(o) {
                case .failure(let e): note = e.message
                case .success(let info):
                    pending = o; pendingInfo = info
                    pendingParts = Store.presentParts(o)
                    restoreSel = Set(pendingParts)
                    confirmRestore = true
                }
            }
        }
        .overlay {
            if confirmRestore {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                        .onTapGesture { confirmRestore = false; pending = nil }
                    VStack(spacing: 0) {
                        Text(L("导入备份")).font(.headline).foregroundStyle(Brand.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 18).padding(.top, 16)
                        Text(pendingInfo).font(.footnote).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 18).padding(.top, 6)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L("恢复哪些类别：")).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            ForEach(Self.partDefs.filter { pendingParts.contains($0.key) }) { pd in
                                Toggle(isOn: Binding(get: { restoreSel.contains(pd.key) }, set: { on in if on { restoreSel.insert(pd.key) } else { restoreSel.remove(pd.key) } })) {
                                    Text(L(pd.label)).font(.subheadline)
                                }
                            }
                            Text(L("覆盖：所选类别用备份替换当前数据。合并：设置以备份为准，订阅 / 节点 / 历史取并集。")).font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 18).padding(.top, 10)
                        VStack(spacing: 6) {
                            restoreButton(L("覆盖所选类别"), destructive: true) { if let p = pending { note = store.applyBackup(p, replace: true, parts: restoreSel) } }
                            restoreButton(L("合并所选类别"), destructive: false) { if let p = pending { note = store.applyBackup(p, replace: false, parts: restoreSel) } }
                            Button { confirmRestore = false; pending = nil } label: {
                                Text(L("取消")).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.ink)
                                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.secondary.opacity(0.14)))
                            }.buttonStyle(.plain)
                        }
                        .padding(16)
                    }
                    .frame(maxWidth: 320)
                    .popupGlass()
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    private func restoreButton(_ title: String, destructive: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            if restoreSel.isEmpty { note = L("至少勾选一类再恢复") ; return }
            action(); confirmRestore = false; pending = nil
        } label: {
            Text(title).font(.subheadline.weight(.semibold))
                .foregroundStyle(destructive ? Color.red : Brand.pink)
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(destructive ? Color.red.opacity(0.10) : Color.secondary.opacity(0.10)))
        }.buttonStyle(.plain)
    }
}

extension Store {
    /// 备份里包含哪些类别：优先用 v3 的 parts 清单；旧版按实际内容推断
    static func presentParts(_ o: [String: Any]) -> [String] {
        if let p = o["parts"] as? [String], !p.isEmpty {
            return BackupView.partDefs.map { $0.key }.filter { p.contains($0) }
        }
        var r: [String] = []
        if o["state"] != nil { r += ["settings", "subs", "nodes"] }
        if o["history"] != nil { r.append("history") }
        if o["prefs"] != nil { r.append("prefs") }
        return r
    }
    /// 校验备份文件格式；成功时返回给用户看的内容摘要
    static func validateBackup(_ o: [String: Any]) -> Result<String, BackupError> {
        guard let v = o["lowexBackup"] as? Int else { return .failure(BackupError(L("不是 Lowex 备份文件"))) }
        if v < 1 { return .failure(BackupError(L("备份版本无效"))) }
        let parts = presentParts(o)
        if parts.isEmpty { return .failure(BackupError(L("备份文件里没有可恢复的内容"))) }
        if let st = o["state"] as? [String: Any] {
            if let pf = st["platform"] as? String, !["windows", "ios", "android", "macos", "linux"].contains(pf) { return .failure(BackupError(L("备份里的系统不受支持"))) }
            if st["opts"] != nil, !(st["opts"] is [String: Any]) { return .failure(BackupError(L("备份里的选项格式不正确"))) }
        }
        let st = (o["state"] as? [String: Any]) ?? [:]
        let subs = (st["subs"] as? [Any])?.count ?? 0
        let nodes = (st["manualNodes"] as? [Any])?.count ?? 0
        let hist = (o["history"] as? [Any])?.count ?? 0
        var s = L("备份版本 v{} · {} · {}", v, (o["app"] as? String) ?? "?", (o["created"] as? String) ?? "")
        let labels = parts.map { k in BackupView.partDefs.first(where: { $0.key == k })?.label ?? k }
        s += "\n" + L("包含：{}", labels.map { L($0) }.joined(separator: "、"))
        s += "\n" + L("{} 个订阅 · {} 个手动节点 · {} 条历史记录", subs, nodes, hist)
        if v > 3 { s += "\n" + L("这份备份来自更新的版本，只会读取已知内容。") }
        return .success(s)
    }
    struct BackupError: Error { let message: String; init(_ m: String) { message = m } }
}

extension Store {
    /// 兼容旧调用：全部类别
    func applyBackup(_ o: [String: Any], replace: Bool) -> String { applyBackup(o, replace: replace, parts: Set(BackupView.partDefs.map { $0.key })) }
    /// 应用备份的所选类别。replace = true 覆盖；false 合并（设置以备份为准，订阅 / 节点 / 历史取并集）。
    func applyBackup(_ o: [String: Any], replace: Bool, parts: Set<String>) -> String {
        let st = (o["state"] as? [String: Any]) ?? [:]
        let touchState = !parts.intersection(["settings", "subs", "nodes"]).isEmpty && o["state"] != nil
        var applied: [String] = []
        if touchState {
            var s = state
            if parts.contains("settings") {
                let secretKeys: Set<String> = ["subs", "nodesText", "manualNodes"]
                for (k, v) in st where !secretKeys.contains(k) { s[k] = v }
                applied.append(L("方案设置"))
            }
            // 订阅
            if parts.contains("subs") {
                let bsubs = (st["subs"] as? [[String: Any]]) ?? []
                if replace { s["subs"] = bsubs } else {
                    var cur = (s["subs"] as? [[String: Any]]) ?? []
                    for x in bsubs where !cur.contains(where: { ($0["url"] as? String) == (x["url"] as? String) }) { cur.append(x) }
                    s["subs"] = cur
                }
                applied.append(L("订阅"))
            }
            // 节点正文 + 手动节点（含密码 → 钥匙串 / 私有文件）
            if parts.contains("nodes") {
                let bt = (st["nodesText"] as? String) ?? ""
                if replace { s["nodesText"] = bt } else {
                    var lines = ((s["nodesText"] as? String) ?? "").split(whereSeparator: \.isNewline).map(String.init)
                    let have = Set(lines)
                    for l in bt.split(whereSeparator: \.isNewline).map(String.init) where !have.contains(l) { lines.append(l) }
                    s["nodesText"] = lines.joined(separator: "\n")
                }
                let bm = (st["manualNodes"] as? [[String: Any]]) ?? []
                for m in bm { if let id = m["id"] as? String, let p = m["pass"] as? String, !p.isEmpty { SecretStore.set(p, id: id) } }
                if replace {
                    for m in manualNodes { if let id = m["id"] as? String, !bm.contains(where: { ($0["id"] as? String) == id }) { SecretStore.remove(id) } }
                    s["manualNodes"] = bm
                } else {
                    var cur = (s["manualNodes"] as? [[String: Any]]) ?? []
                    for m in bm where !cur.contains(where: { ($0["id"] as? String) == (m["id"] as? String) }) { cur.append(m) }
                    s["manualNodes"] = cur
                }
                applied.append(L("节点"))
            }
            if parts.contains("settings") {
                // 平台 / 客户端校正
                let plats = ["windows", "ios", "android", "macos", "linux"]
                if let pf = s["platform"] as? String, !plats.contains(pf) { s["platform"] = "ios" }
                if s["platform"] == nil { s["platform"] = "ios" }
                let pf = s["platform"] as? String ?? "ios"
                if let c = s["client"] as? String, catalog.clients.first(where: { $0.id == c })?.platforms.contains(pf) == true {} else {
                    s["client"] = catalog.clients.first(where: { $0.platforms.contains(pf) })?.id ?? "shadowrocket"
                }
                // 缺失的选项补默认值
                let base = engine.initialState(client: s["client"] as? String ?? "shadowrocket", platform: pf)
                var opts = (base["opts"] as? [String: Any]) ?? [:]
                for (k, v) in (s["opts"] as? [String: Any]) ?? [:] { opts[k] = v }
                s["opts"] = opts
            }
            state = s
            reconcile(silent: true)
        }
        if parts.contains("subs"), let sh = o["subHistory"] as? [[String: String]] {
            applySubHistory(sh, replace: replace)
            if !applied.contains(L("订阅")) { applied.append(L("订阅")) }
        }
        if parts.contains("prefs"), let prefs = o["prefs"] as? [String: Any] { PrefsBackup.apply(prefs); applied.append(L("外观偏好")) }
        var hn = 0
        if parts.contains("history"), let h = o["history"] { hn = HistoryStore.shared.importObject(h, replace: replace); applied.append(L("生成历史")) }
        if parts.contains("remote"), let r = o["remote"] as? [String: Any] { RemoteBackup.apply(r, store: self); applied.append(L("远程覆写")) }
        flushSave()
        return L("已{}：{}", replace ? L("覆盖恢复") : L("合并恢复"), applied.isEmpty ? L("无内容") : applied.joined(separator: "、")) + (hn > 0 ? L(" · 历史 {} 条", hn) : "")
    }
}
