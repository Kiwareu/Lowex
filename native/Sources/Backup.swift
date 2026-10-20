import SwiftUI
import UniformTypeIdentifiers

/// 偏好（外观 / 语言 / 规则页显示方式）的备份与恢复。壁纸图片不在备份里。
enum PrefsBackup {
    static let keys = ["ap.mode", "ap.accent", "ap.radius", "ap.glass", "ap.speed", "ap.font", "ap.haptics", "ap.perf", "ap.density", "lowex.lang.choice.v1"]
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
    }
}

/// Lowex 完整备份 / 恢复（本地 JSON 文件，不依赖 iCloud，不经过任何服务器）。
/// v2：包含全部设置与选择、订阅链接、粘贴的节点、手动节点（含密码）、外观偏好和尚未删除的历史记录。
struct BackupView: View {
    @EnvironmentObject var store: Store
    @ObservedObject private var hs = HistoryStore.shared
    @State private var exportFile: ShareFile?
    @State private var shareFile: ShareFile?
    @State private var importing = false
    @State private var note = ""
    @State private var pending: [String: Any]?
    @State private var pendingInfo = ""
    @State private var confirmRestore = false
    static let formatVersion = 2

    private var backupObject: [String: Any] {
        store.flushSave()
        var s = store.state
        // 保险：确保订阅 / 节点 / 手动节点（含密码）都在
        s["subs"] = store.subs
        s["nodesText"] = store.nodesText
        s["manualNodes"] = store.manualNodes
        return ["lowexBackup": Self.formatVersion, "app": store.versionLabel, "build": store.buildNumber,
                "created": ISO8601DateFormatter().string(from: Date()),
                "state": s, "prefs": PrefsBackup.snapshot(), "history": hs.exportObject()]
    }
    private var backupText: String {
        let d = (try? JSONSerialization.data(withJSONObject: backupObject, options: [.prettyPrinted, .sortedKeys])) ?? Data()
        return String(data: d, encoding: .utf8) ?? "{}"
    }
    private var fileName: String {
        let f = DateFormatter(); f.dateFormat = "yyyyMMdd-HHmm"; f.locale = Locale(identifier: "en_US_POSIX")
        return "Lowex-backup-\(f.string(from: Date())).json"
    }

    var body: some View {
        PageChrome(title: L("备份与恢复")) {
            PlainCard {
                Text(L("完整备份")).font(.headline)
                Text(L("把所有设置与选择（系统、客户端、分组、地区、选项、配置名）、订阅链接、粘贴的节点、手动节点、外观偏好，以及还没删除的历史记录，存成一个 JSON 文件。换机或重装后导入即可恢复。"))
                    .font(.footnote).foregroundStyle(.secondary)
                Label(L("备份文件含订阅链接和节点密码，等同于账号凭据：只放在你信任的地方，不要发给别人或传到公开网盘。Lowex 不会把它上传到任何服务器。"), systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundStyle(.orange)
                Text(L("当前将备份：{} 个订阅 · {} 个手动节点 · {} 条历史记录", store.subs.count, store.manualNodes.count, hs.entries.count))
                    .font(.caption2).foregroundStyle(.secondary)
                HStack {
                    Button { if let u = TempFile.make(name: fileName, text: backupText, fallback: "Lowex-backup.json") { exportFile = ShareFile(url: u) } else { note = L("写临时文件失败") } } label: { Label(L("导出备份"), systemImage: "square.and.arrow.up") }
                        .buttonStyle(.borderedProminent).tint(Brand.pink)
                    Button { importing = true } label: { Label(L("导入备份"), systemImage: "square.and.arrow.down") }.buttonStyle(.bordered)
                    Button { if let u = TempFile.make(name: fileName, text: backupText, fallback: "Lowex-backup.json") { shareFile = ShareFile(url: u) } else { note = L("写临时文件失败") } } label: { Label(L("分享"), systemImage: "square.and.arrow.up.on.square") }.buttonStyle(.bordered)
                }
                if !note.isEmpty { Text(note).font(.caption).foregroundStyle(.secondary) }
            }
            PlainCard {
                Text(L("说明")).font(.headline)
                Text(L("• 只读取 Lowex 自己导出的文件；会先校验格式，未知字段会被忽略。\n• 导入时先显示备份内容，再让你选择「覆盖」或「合并」，确认后才会改动。\n• 恢复后会按所选系统 / 客户端自动校正不支持的选项。\n• 壁纸图片不在备份里。\n• 旧版（v1）备份仍可导入。"))
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
                case .success(let info): pending = o; pendingInfo = info; confirmRestore = true
                }
            }
        }
        .overlay {
            if confirmRestore {
                GlassConfirm(title: L("导入备份"),
                    message: pendingInfo + "\n" + L("覆盖：用备份替换当前设置、订阅、节点和历史。合并：设置以备份为准，订阅 / 节点 / 历史取并集。"),
                    actions: [
                        .init(title: L("覆盖当前数据"), destructive: true) { if let p = pending { note = store.applyBackup(p, replace: true) } },
                        .init(title: L("合并到当前数据"), destructive: false) { if let p = pending { note = store.applyBackup(p, replace: false) } },
                    ],
                    dismiss: { confirmRestore = false; pending = nil })
            }
        }
    }
}

extension Store {
    /// 校验备份文件格式；成功时返回给用户看的内容摘要
    static func validateBackup(_ o: [String: Any]) -> Result<String, BackupError> {
        guard let v = o["lowexBackup"] as? Int else { return .failure(BackupError(L("不是 Lowex 备份文件"))) }
        guard let st = o["state"] as? [String: Any] else { return .failure(BackupError(L("备份文件缺少设置内容，无法导入"))) }
        if v < 1 { return .failure(BackupError(L("备份版本无效"))) }
        if let pf = st["platform"] as? String, !["windows", "ios", "android", "macos", "linux"].contains(pf) { return .failure(BackupError(L("备份里的系统不受支持"))) }
        if st["opts"] != nil, !(st["opts"] is [String: Any]) { return .failure(BackupError(L("备份里的选项格式不正确"))) }
        let subs = (st["subs"] as? [Any])?.count ?? 0
        let nodes = (st["manualNodes"] as? [Any])?.count ?? 0
        let hist = (o["history"] as? [Any])?.count ?? 0
        var s = L("备份版本 v{} · {} · {}", v, (o["app"] as? String) ?? "?", (o["created"] as? String) ?? "")
        s += "\n" + L("{} 个订阅 · {} 个手动节点 · {} 条历史记录", subs, nodes, hist)
        if v > 2 { s += "\n" + L("这份备份来自更新的版本，只会读取已知内容。") }
        return .success(s)
    }
    struct BackupError: Error { let message: String; init(_ m: String) { message = m } }
}

extension Store {
    /// 应用备份。replace = true 覆盖；false 合并（设置以备份为准，订阅 / 节点 / 历史取并集）。
    func applyBackup(_ o: [String: Any], replace: Bool) -> String {
        guard let st = o["state"] as? [String: Any] else { return L("不是 Lowex 备份文件") }
        var s = state
        let keepSecretKeys: Set<String> = ["subs", "nodesText", "manualNodes"]
        for (k, v) in st where !keepSecretKeys.contains(k) { s[k] = v }
        // 订阅
        let bsubs = (st["subs"] as? [[String: Any]]) ?? []
        if replace { s["subs"] = bsubs } else {
            var cur = (s["subs"] as? [[String: Any]]) ?? []
            for x in bsubs where !cur.contains(where: { ($0["url"] as? String) == (x["url"] as? String) }) { cur.append(x) }
            s["subs"] = cur
        }
        // 节点正文
        let bt = (st["nodesText"] as? String) ?? ""
        if replace { s["nodesText"] = bt } else {
            var lines = ((s["nodesText"] as? String) ?? "").split(whereSeparator: \.isNewline).map(String.init)
            let have = Set(lines)
            for l in bt.split(whereSeparator: \.isNewline).map(String.init) where !have.contains(l) { lines.append(l) }
            s["nodesText"] = lines.joined(separator: "\n")
        }
        // 手动节点（含密码 → 钥匙串 / 私有文件）
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
        state = s
        reconcile(silent: true)
        if let prefs = o["prefs"] as? [String: Any] { PrefsBackup.apply(prefs) }
        var hn = 0
        if let h = o["history"] { hn = HistoryStore.shared.importObject(h, replace: replace) }
        flushSave()
        return L("已{}：{} · 订阅 {} · 手动节点 {} · 历史 {} 条", replace ? L("覆盖恢复") : L("合并恢复"), clientInfo?.name ?? client, subs.count, manualNodes.count, hn)
    }
}
