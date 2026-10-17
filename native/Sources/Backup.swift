import SwiftUI
import UniformTypeIdentifiers

/// Lowex 设置备份 / 恢复（本地 JSON 文件，不依赖 iCloud）。
/// 默认只含设置；订阅 URL 从不写入备份。可选包含手动节点（含密码，务必妥善保管）。
struct BackupView: View {
    @EnvironmentObject var store: Store
    @State private var includeNodes = false
    @State private var exporting = false
    @State private var sharing = false
    @State private var importing = false
    @State private var note = ""

    private var backupText: String {
        var s = store.state
        s["subs"] = []; s["nodesText"] = ""
        if !includeNodes { s["manualNodes"] = [] }
        let wrap: [String: Any] = ["lowexBackup": 1, "app": store.versionLabel, "state": s]
        let d = (try? JSONSerialization.data(withJSONObject: wrap, options: [.prettyPrinted, .sortedKeys])) ?? Data()
        return String(data: d, encoding: .utf8) ?? "{}"
    }

    var body: some View {
        PageChrome(title: L("备份与恢复")) {
            PlainCard {
                Text(L("Lowex 设置备份")).font(.headline)
                Text(L("把当前选择（系统、客户端、分组、选项、配置名）存成一个 JSON 文件，换机或重装后导入恢复。订阅链接不会写进备份。"))
                    .font(.footnote).foregroundStyle(.secondary)
                Toggle(L("同时备份手动节点（含密码，请妥善保管）"), isOn: $includeNodes).font(.subheadline)
                HStack {
                    Button { exporting = true } label: { Label(L("导出备份"), systemImage: "square.and.arrow.up") }.buttonStyle(.borderedProminent).tint(Brand.pink)
                    Button { importing = true } label: { Label(L("导入备份"), systemImage: "square.and.arrow.down") }.buttonStyle(.bordered)
                    Button { sharing = true } label: { Label(L("分享"), systemImage: "square.and.arrow.up.on.square") }.buttonStyle(.bordered)
                }
                if !note.isEmpty { Text(note).font(.caption).foregroundStyle(.secondary) }
            }
            PlainCard {
                Text(L("说明")).font(.headline)
                Text(L("• 只读取 Lowex 自己导出的文件，未知字段会被忽略。\n• 恢复后会按所选系统 / 客户端自动校正不支持的选项。\n• 生成的配置本身（含订阅 URL）请在「生成」页导出、分享或扫码。"))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $sharing) { ActivityView(items: [backupText]) }
        .fileExporter(isPresented: $exporting, document: ConfigDocument(text: backupText), contentType: .json,
                      defaultFilename: "Lowex-backup") { r in
            switch r { case .success: note = L("已保存备份到「文件」"); case .failure(let e): note = L("保存失败：{}", e.localizedDescription) }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json, .plainText]) { r in
            switch r {
            case .failure(let e): note = L("导入失败：{}", e.localizedDescription)
            case .success(let url):
                let ok = url.startAccessingSecurityScopedResource(); defer { if ok { url.stopAccessingSecurityScopedResource() } }
                guard let d = try? Data(contentsOf: url), let o = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any],
                      (o["lowexBackup"] as? Int) != nil, let st = o["state"] as? [String: Any] else { note = L("不是 Lowex 备份文件"); return }
                note = store.restore(from: st)
            }
        }
    }
}

extension Store {
    /// 从备份恢复：只接受已知键，之后按平台 / 客户端校正。
    func restore(from st: [String: Any]) -> String {
        var s = state
        for k in ["platform", "client", "location", "network", "regions", "groups", "apps", "customDomains", "opts", "profileName", "profileNameCustom", "nodeMode"] {
            if let v = st[k] { s[k] = v }
        }
        if let ml = st["manualNodes"] as? [[String: Any]], !ml.isEmpty {
            s["manualNodes"] = ml
            for m in ml { if let id = m["id"] as? String, let p = m["pass"] as? String { SecretStore.set(p, id: id) } }
        }
        s["subs"] = []; s["nodesText"] = ""
        state = s
        reconcile(silent: true)
        save()
        return L("已恢复：{}", clientInfo?.name ?? client)
    }
}
