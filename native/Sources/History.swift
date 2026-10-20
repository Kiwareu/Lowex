import SwiftUI
import UIKit

// MARK: - 历史记录（本地保存，随备份导出 / 导入）
struct HistoryVersion: Codable, Identifiable, Equatable {
    var id: String
    var time: Date
    var kind: String        // generate 首次生成 / regenerate 重新生成 / edit 手动编辑
    var name: String
    var text: String
    var summary: String     // 选项摘要
    var settings: String    // 生成时的设置快照（JSON，不含订阅 / 节点 / 密码）
}

struct HistoryEntry: Codable, Identifiable, Equatable {
    var id: String
    var key: String
    var created: Date
    var updated: Date
    var client: String
    var clientName: String
    var platform: String
    var versions: [HistoryVersion]
    var latest: HistoryVersion? { versions.last }
}

final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()
    @Published private(set) var entries: [HistoryEntry] = []
    private let file = "history.json"
    private let maxEntries = 60
    private let maxVersions = 20

    private static var encoder: JSONEncoder { let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; return e }
    private static var decoder: JSONDecoder { let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d }

    private init() {
        if let d = LocalFile.read(file), let e = try? Self.decoder.decode([HistoryEntry].self, from: d) { entries = e }
    }

    private func persist() {
        if let d = try? Self.encoder.encode(entries) { LocalFile.write(d, file) }
    }

    /// 生成成功后调用：同一客户端 + 平台 + 文件名的记录合并成一条，每次内容变化记为一个新版本。
    func record(client: String, clientName: String, platform: String, name: String, text: String, summary: String, settings: String) {
        let key = "\(client)|\(platform)|\(name)"
        let now = Date()
        var list = entries
        if let i = list.firstIndex(where: { $0.key == key }) {
            var e = list.remove(at: i)
            if e.versions.last?.text == text {
                if var last = e.versions.popLast() { last.summary = summary; last.settings = settings; e.versions.append(last) }
            } else {
                e.versions.append(HistoryVersion(id: UUID().uuidString, time: now, kind: "regenerate", name: name, text: text, summary: summary, settings: settings))
                if e.versions.count > maxVersions { e.versions.removeFirst(e.versions.count - maxVersions) }
            }
            e.updated = now
            list.insert(e, at: 0)
        } else {
            let v = HistoryVersion(id: UUID().uuidString, time: now, kind: "generate", name: name, text: text, summary: summary, settings: settings)
            list.insert(HistoryEntry(id: UUID().uuidString, key: key, created: now, updated: now, client: client, clientName: clientName, platform: platform, versions: [v]), at: 0)
            if list.count > maxEntries { list.removeLast(list.count - maxEntries) }
        }
        entries = list
        persist()
    }

    func entry(_ id: String) -> HistoryEntry? { entries.first { $0.id == id } }

    /// 把手动编辑后的文本存成新版本
    func addEdit(_ id: String, text: String) {
        guard let i = entries.firstIndex(where: { $0.id == id }), let last = entries[i].versions.last, last.text != text else { return }
        var e = entries[i]
        e.versions.append(HistoryVersion(id: UUID().uuidString, time: Date(), kind: "edit", name: last.name, text: text, summary: last.summary, settings: last.settings))
        if e.versions.count > maxVersions { e.versions.removeFirst(e.versions.count - maxVersions) }
        e.updated = Date()
        entries[i] = e
        persist()
    }
    func deleteVersion(_ entryId: String, _ versionId: String) {
        guard let i = entries.firstIndex(where: { $0.id == entryId }) else { return }
        var e = entries[i]
        e.versions.removeAll { $0.id == versionId }
        if e.versions.isEmpty { entries.remove(at: i) } else { entries[i] = e }
        persist()
    }
    func delete(_ id: String) { entries.removeAll { $0.id == id }; persist() }
    func clear() { entries = []; persist() }

    // MARK: 备份用
    func exportObject() -> Any {
        guard let d = try? Self.encoder.encode(entries), let o = try? JSONSerialization.jsonObject(with: d) else { return [] }
        return o
    }
    /// replace = true：整体替换；否则按记录 id 合并（同 id 取更新时间较新者）
    func importObject(_ obj: Any, replace: Bool) -> Int {
        guard JSONSerialization.isValidJSONObject(obj), let d = try? JSONSerialization.data(withJSONObject: obj),
              let incoming = try? Self.decoder.decode([HistoryEntry].self, from: d) else { return 0 }
        if replace { entries = incoming } else {
            var map = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
            for e in incoming { if let old = map[e.id], old.updated >= e.updated { continue }; map[e.id] = e }
            entries = map.values.sorted { $0.updated > $1.updated }
        }
        if entries.count > maxEntries { entries = Array(entries.prefix(maxEntries)) }
        persist()
        return incoming.count
    }

    static func kindLabel(_ k: String) -> String {
        switch k {
        case "edit": return L("手动编辑")
        case "regenerate": return L("重新生成")
        default: return L("首次生成")
        }
    }
    static func dateText(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short; f.locale = Lang.shared.resolved.locale
        return f.string(from: d)
    }
}

extension Store {
    /// 当前设置的快照（JSON 字符串）：不含订阅 / 节点正文 / 手动节点（含密码）
    func settingsSnapshot() -> String {
        var s = state
        s["subs"] = []; s["nodesText"] = ""
        s["manualNodes"] = nil
        guard let d = try? JSONSerialization.data(withJSONObject: s, options: [.sortedKeys]) else { return "{}" }
        return String(data: d, encoding: .utf8) ?? "{}"
    }
    /// 选项摘要（给历史记录列表看）
    var optionsSummary: String {
        var p: [String] = []
        p.append(L("{}/{} 分组开", catalog.groups.filter { isOn($0) }.count, catalog.groups.count))
        if !regions.isEmpty { p.append(L("地区 {}", regions.joined(separator: "/"))) }
        if supports("failover"), (opts["failover"] as? Bool) ?? true { p.append(L("故转")) }
        if (opts["wifiCalling"] as? Bool) == true, supports("wifi") { p.append(L("Wi-Fi 通话")) }
        if (opts["ipv6"] as? Bool) == false, supports("ipv6") { p.append(L("关闭 IPv6")) }
        if (opts["tun"] as? Bool) == true, supports("tun") { p.append("TUN") }
        if !blockFlags.isEmpty { p.append(blockFlags) }
        return p.joined(separator: " · ")
    }
    /// 记录一次生成
    func recordHistory() {
        guard result.error == nil, !result.text.isEmpty else { return }
        HistoryStore.shared.record(client: client, clientName: clientInfo?.name ?? client, platform: platform, name: result.name,
                                   text: result.text, summary: optionsSummary, settings: settingsSnapshot())
    }
    /// 从历史版本的设置快照恢复（订阅 / 节点 / 手动节点保持当前）
    func restoreSettings(json: String) -> Bool {
        guard let d = json.data(using: .utf8), let o = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any], !o.isEmpty else { return false }
        var s = state
        for (k, v) in o where !["subs", "nodesText", "manualNodes"].contains(k) { s[k] = v }
        state = s
        reconcile(silent: true)
        save()
        return true
    }
}

// MARK: - 界面
struct HistoryView: View {
    @EnvironmentObject var store: Store
    @ObservedObject private var hs = HistoryStore.shared
    @State private var confirmClear = false

    var body: some View {
        PageChrome(title: L("历史记录")) {
            PlainCard {
                Text(L("每次生成的配置都会保存在本机（最多 60 条，每条最多保留 20 个版本）。同一客户端、同一文件名重新生成或手动编辑，会记为同一条记录的新版本。"))
                    .font(.footnote).foregroundStyle(.secondary)
                Text(L("历史里的配置可能含订阅链接和节点密码，只保存在这台设备上，不会上传。"))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            if hs.entries.isEmpty {
                PlainCard { Text(L("还没有历史记录。到「生成」页生成一份配置后会自动保存。")).font(.subheadline) }
            } else {
                ForEach(hs.entries) { e in
                    NavigationLink { HistoryDetailView(entryID: e.id) } label: { row(e) }.buttonStyle(PressableStyle())
                }
                Button(role: .destructive) { confirmClear = true } label: {
                    Label(L("清空全部历史"), systemImage: "trash").frame(maxWidth: .infinity)
                }.buttonStyle(.bordered)
            }
        }
        .overlay {
            if confirmClear {
                GlassConfirm(title: L("清空全部历史"), message: L("历史记录删除后无法恢复。"),
                    actions: [.init(title: L("清空"), destructive: true) { hs.clear() }],
                    dismiss: { confirmClear = false })
            }
        }
    }

    private func row(_ e: HistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(e.latest?.name ?? e.key).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.ink).lineLimit(2)
                Spacer()
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Brand.pink.opacity(0.8))
            }
            Text("\(e.clientName) · \(HistoryStore.dateText(e.updated))").font(.caption).foregroundStyle(.secondary)
            if let s = e.latest?.summary, !s.isEmpty { Text(s).font(.caption2).foregroundStyle(.secondary).lineLimit(2) }
            Text(L("{} 个版本", e.versions.count)).font(.caption2).foregroundStyle(Brand.pink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.l).softCard()
    }
}

struct HistoryDetailView: View {
    let entryID: String
    @EnvironmentObject var store: Store
    @ObservedObject private var hs = HistoryStore.shared
    @Environment(\.presentationMode) private var presentation
    @State private var selected = ""
    @State private var toast = ""
    @State private var shareFile: ShareFile?
    @State private var exportFile: ShareFile?
    @State private var editing = false
    @State private var editText = ""
    @State private var confirmRestore = false
    @State private var confirmDeleteEntry = false

    private var entry: HistoryEntry? { hs.entry(entryID) }
    private var version: HistoryVersion? {
        guard let e = entry else { return nil }
        return e.versions.first { $0.id == selected } ?? e.versions.last
    }

    var body: some View {
        PageChrome(title: L("历史详情")) {
            if let e = entry, let v = version {
                PlainCard {
                    Text(v.name).font(.headline).lineLimit(3)
                    Text("\(e.clientName) · \(e.platform) · \(L("{} 字符", v.text.count))").font(.caption).foregroundStyle(.secondary)
                    Text(L("首次生成 {}", HistoryStore.dateText(e.created))).font(.caption2).foregroundStyle(.secondary)
                    if !v.summary.isEmpty { Text(v.summary).font(.caption2).foregroundStyle(.secondary) }
                }
                PlainCard {
                    Text(L("修改记录（点选查看）")).font(.headline)
                    ForEach(Array(e.versions.reversed())) { x in
                        Button { selected = x.id } label: {
                            HStack {
                                Image(systemName: x.id == v.id ? "largecircle.fill.circle" : "circle").foregroundStyle(Brand.pink)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(HistoryStore.kindLabel(x.kind)).font(.footnote.weight(.semibold)).foregroundStyle(Brand.ink)
                                    Text("\(HistoryStore.dateText(x.time)) · \(L("{} 字符", x.text.count))").font(.caption2).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }.contentShape(Rectangle())
                        }.buttonStyle(.plain)
                    }
                }
                PlainCard {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        btn(L("复制"), "doc.on.doc") { UIPasteboard.general.string = v.text; toast = L("已复制到剪贴板") }
                        btn(L("保存到「文件」"), "folder") { exportFile = TempFile.make(name: v.name, text: v.text).map { ShareFile(url: $0) }; if exportFile == nil { toast = L("写临时文件失败") } }
                        btn(L("系统分享"), "square.and.arrow.up") { shareFile = TempFile.make(name: v.name, text: v.text).map { ShareFile(url: $0) }; if shareFile == nil { toast = L("写临时文件失败") } }
                        btn(L("编辑"), "pencil") { editText = v.text; editing = true }
                        btn(L("恢复此版本的设置"), "arrow.uturn.backward") { confirmRestore = true }
                        btn(L("删除此版本"), "minus.circle") { hs.deleteVersion(e.id, v.id); selected = "" ; if hs.entry(e.id) == nil { presentation.wrappedValue.dismiss() } }
                    }
                    Button(role: .destructive) { confirmDeleteEntry = true } label: {
                        Label(L("删除整条记录"), systemImage: "trash").frame(maxWidth: .infinity)
                    }.buttonStyle(.bordered)
                    if !toast.isEmpty { Text(toast).font(.caption).foregroundStyle(Brand.pink) }
                }
                PlainCard {
                    Text(L("内容预览")).font(.headline)
                    FullTextView(text: v.text).frame(height: 360).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            } else {
                PlainCard { Text(L("这条记录已被删除。")).font(.subheadline) }
            }
        }
        .sheet(item: $shareFile) { ActivityView(items: [$0.url]) }
        .sheet(item: $exportFile) { f in
            DocumentExporter(url: f.url) { ok in exportFile = nil; toast = ok ? L("已保存到「文件」") : L("已取消") }
        }
        .sheet(isPresented: $editing) {
            NavStack {
                VStack(spacing: 8) {
                    Text(L("编辑后保存为新版本，原版本保留。")).font(.footnote).foregroundStyle(.secondary).padding(.horizontal)
                    TextEditor(text: $editText)
                        .font(.system(size: 12, design: .monospaced)).padding(6)
                        .background(Color.secondary.opacity(0.1)).cornerRadius(8).padding(.horizontal)
                    HStack {
                        Button(L("取消")) { editing = false }.buttonStyle(.bordered)
                        Button(L("保存为新版本")) { hs.addEdit(entryID, text: editText); selected = ""; editing = false }
                            .buttonStyle(.borderedProminent).tint(Brand.pink)
                    }.padding(.bottom, 8)
                }
                .padding(.top, 12)
                .hideNavBar()
            }
        }
        .overlay {
            if confirmRestore {
                GlassConfirm(title: L("恢复此版本的设置"),
                    message: L("会用这个版本生成时的选项覆盖当前选项（客户端、分组、地区、功能开关等）；订阅、节点和手动节点不变。"),
                    actions: [.init(title: L("恢复"), destructive: false) {
                        if let v = version, store.restoreSettings(json: v.settings) { toast = L("已恢复设置，订阅与节点保持不变；到「生成」页重新生成即可"); store.tab = .generate }
                        else { toast = L("这个版本没有可恢复的设置") }
                    }],
                    dismiss: { confirmRestore = false })
            }
        }
        .overlay {
            if confirmDeleteEntry {
                GlassConfirm(title: L("删除整条记录"), message: "",
                    actions: [.init(title: L("删除"), destructive: true) { hs.delete(entryID); presentation.wrappedValue.dismiss() }],
                    dismiss: { confirmDeleteEntry = false })
            }
        }
    }

    private func btn(_ title: String, _ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: { Haptics.light(); action() }) {
            Label(title, systemImage: icon).font(.caption.weight(.semibold)).lineLimit(2).minimumScaleFactor(0.8)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity, minHeight: 36)
        }.buttonStyle(.bordered)
    }
}
