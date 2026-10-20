import SwiftUI
import UIKit

// MARK: - 更多（轻量：模块 / 防泄漏 / 作者分享 / 关于）
struct MoreView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var lang: Lang
    @State private var confirmReset = false
    @State private var resetNote = ""
    var body: some View {
        NavStack {
            ZStack {
                PinkBackground()
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        Text(L("更多"))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Brand.ink)
                            .padding(.top, 6)

                        moreSection(L("外观与偏好"))
                        Button { store.showAppearance = true } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "paintpalette.fill").foregroundStyle(Brand.pink).frame(width: 28)
                                Text(L("自定义外观与主题")).foregroundStyle(Brand.ink)
                                Spacer()
                                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Brand.pink.opacity(0.8))
                            }
                            .padding(Space.l).frame(minHeight: Space.tap).contentShape(Rectangle()).softCard()
                        }.buttonStyle(PressableStyle())
                        HStack(spacing: 12) {
                            Image(systemName: "globe").foregroundStyle(Brand.pink).frame(width: 28)
                            Text(L("界面语言")).foregroundStyle(Brand.ink)
                            Spacer()
                            Picker("", selection: Binding(get: { lang.choice }, set: { lang.choice = $0 })) {
                                ForEach(AppLang.allCases) { Text($0.label).tag($0) }
                            }
                            .pickerStyle(.menu).tint(Brand.pink)
                        }
                        .padding(.horizontal, Space.l).padding(.vertical, 6).frame(minHeight: Space.tap).softCard()

                        moreSection(L("工具"))
                        navCard(L("防泄漏检查清单"), icon: "shield.lefthalf.filled", dest: LeakView())
                        if store.engine.supportsModules(client: store.client) {
                            navCard(L("模块与脚本"), icon: "puzzlepiece.extension", dest: ModulesView())
                        }
                        navCard(L("远程 JS 覆写 / 重写"), icon: "link", dest: RemoteJsView())
                        navCard(L("作者自用规则分享"), icon: "person.crop.circle.badge.checkmark", dest: SharedView())
                        navCard(L("历史记录"), icon: "clock.arrow.circlepath", dest: HistoryView())
                        navCard(L("备份与恢复 Lowex 设置"), icon: "externaldrive.badge.icloud", dest: BackupView())
                        Button { confirmReset = true } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.counterclockwise").foregroundStyle(Brand.pink).frame(width: 28)
                                Text(L("恢复默认设置")).foregroundStyle(Brand.ink)
                                Spacer()
                            }
                            .padding(Space.l).frame(minHeight: Space.tap).contentShape(Rectangle()).softCard()
                        }.buttonStyle(PressableStyle())
                        if !resetNote.isEmpty { Text(resetNote).font(.caption).foregroundStyle(Brand.pink).padding(.leading, 4) }

                        moreSection(L("关于"))
                        navCard(L("关于 Lowex"), icon: "info.circle", dest: AboutView())
                        navCard(L("免责声明"), icon: "exclamationmark.shield.fill", dest: DisclaimerView())
                        Link(destination: URL(string: "https://github.com/Kiwareu/Lowex")!) {
                            HStack(spacing: 12) {
                                Image(systemName: "chevron.left.forwardslash.chevron.right").foregroundStyle(Brand.pink).frame(width: 28)
                                Text(L("GitHub 项目主页")).foregroundStyle(Brand.ink)
                                Spacer()
                                Image(systemName: "arrow.up.right").font(.footnote.weight(.semibold)).foregroundStyle(Brand.pink.opacity(0.8))
                            }
                            .padding(Space.l).frame(minHeight: Space.tap).contentShape(Rectangle()).softCard()
                        }.buttonStyle(PressableStyle())

                        VStack(spacing: 2) {
                            Text(L("本机生成 · 不上传")).font(.caption2).foregroundStyle(.secondary)
                            Text(store.versionLabel).font(.caption2.monospaced()).foregroundStyle(.secondary.opacity(0.7)).padding(8).fpsSecret()
                        }
                        .frame(maxWidth: .infinity).padding(.top, Space.m)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
                .scrollTailCompat()
                BottomFade()
            }
            .hideNavBar()
        }
        .overlay {
            if confirmReset {
                GlassConfirm(title: L("恢复默认设置"),
                    message: L("Lowex 会记住你所有的选择；这里可以把它们恢复成默认。外观与语言不受影响。建议先到「备份与恢复」导出一份备份。"),
                    actions: [
                        .init(title: L("只重置选项（保留节点、订阅、历史）"), destructive: false) { store.resetSelections(); resetNote = L("已重置选项，节点、订阅与历史保留") },
                        .init(title: L("全部重置（含节点、订阅、历史）"), destructive: true) { store.resetEverything(); resetNote = L("已恢复全部默认设置") },
                    ],
                    dismiss: { confirmReset = false })
            }
        }
    }

    private func moreSection(_ t: String) -> some View {
        Text(t).font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            .padding(.top, Space.s).padding(.leading, 4)
    }

    private func navCard<V: View>(_ title: String, icon: String, dest: V) -> some View {
        NavigationLink {
            dest
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundStyle(Brand.pink).frame(width: 28)
                Text(title).foregroundStyle(Brand.ink)
                Spacer()
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Brand.pink.opacity(0.8))
            }
            .padding(Space.l)
            .frame(minHeight: Space.tap)
            .contentShape(Rectangle())
            .softCard()
        }
        .buttonStyle(PressableStyle())
    }
}

// MARK: 内联：按 App（嵌在规则页）
struct AppsInline: View {
    @EnvironmentObject var store: Store
    @State private var q = ""
    @State private var policy = "PROXY"
    @State private var extraDom = ""
    @State private var note = ""
    @State private var online: [(String, String)] = []
    @State private var busy = false

    var hits: [Catalog.AppEntry] {
        let k = q.trimmingCharacters(in: .whitespaces).lowercased()
        if k.isEmpty { return Array(store.catalog.apps.prefix(24)) }
        return Array(store.catalog.apps.filter {
            $0.n.lowercased().contains(k) || ($0.en ?? "").lowercased().contains(k) || ($0.pkg ?? "").lowercased().contains(k)
        }.prefix(40))
    }
    var added: [[String: Any]] { store.state["apps"] as? [[String: Any]] ?? [] }

    var body: some View {
        PlainCard {
            Text(store.platform == "ios"
                 ? L("iOS 无法真按 App 分流：会改为设服务组出口或按域名分流。")
                 : (store.platform == "windows" ? L("Windows：可按进程名（.exe）/ 域名 / 服务组分流。") : L("Android：可按包名 / 域名 / 服务组分流。")))
                .font(.caption).foregroundStyle(.secondary)
            PolicyPicker(policy: $policy)
            TextField(L("搜索 App"), text: $q)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
            TextField(L("附加域名（可选）"), text: $extraDom)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
            Button(busy ? L("搜索中…") : L("App Store 在线搜索")) { Task { await searchOnline() } }
                .buttonStyle(.bordered).disabled(q.isEmpty || busy)
            if !note.isEmpty { Text(note).font(.footnote).foregroundStyle(Brand.pink) }
        }

        if !online.isEmpty {
            PlainCard {
                Text("App Store").font(.headline)
                ForEach(Array(online.enumerated()), id: \.offset) { _, item in
                    HStack {
                        Text(item.0).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Button(L("添加")) {
                            add(Catalog.AppEntry(n: item.0, en: item.0, pkg: nil, bid: item.1, dom: [], g: nil))
                        }.buttonStyle(.bordered)
                    }
                }
            }
        }

        PlainCard {
            Text(L("内置库（{}）", store.catalog.apps.count)).font(.headline)
            ForEach(hits) { a in
                HStack {
                    VStack(alignment: .leading) {
                        Text(a.n)
                        if let e = a.en, e != a.n {
                            Text(e).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button(L("添加")) { add(a) }.buttonStyle(.bordered)
                }
            }
        }

        if !added.isEmpty {
            PlainCard {
                Text(L("已添加")).font(.headline)
                ForEach(Array(added.enumerated()), id: \.offset) { i, a in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(a["label"] as? String ?? "")
                            Text("\(a["kind"] as? String ?? "") · \(a["policy"] as? String ?? "")")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(role: .destructive) { remove(i) } label: { Image(systemName: "trash") }
                    }
                }
            }
        }
    }

    func appendApp(_ kind: String, _ value: String, _ label: String) {
        var a = added
        if a.contains(where: { ($0["kind"] as? String) == kind && ($0["value"] as? String) == value }) { return }
        a.append(["id": UUID().uuidString, "kind": kind, "value": value, "label": label, "policy": policy])
        store.set("apps", a)
    }
    func remove(_ i: Int) { var a = added; a.remove(at: i); store.set("apps", a) }
    func add(_ a: Catalog.AppEntry) {
        let platform = store.platform
        let extra = extraDom.split(whereSeparator: { " ,\n".contains($0) }).map(String.init)
        let doms = a.dom + extra
        if platform == "windows", let x = a.exe, store.clientInfo?.processRules ?? false {
            appendApp("process", x, a.n); note = L("已按进程名添加：{}", a.n); return
        }
        if platform == "android", let p = a.pkg {
            appendApp("package", p, a.n); note = L("已按包名添加：{}", a.n); return
        }
        if let g = a.g, doms.isEmpty || extra.isEmpty,
           let grp = store.catalog.groups.first(where: { $0.id == g }) {
            store.setGroup(grp, on: true, policy: policy)
            note = L("已把服务组「{}」出口改为所选", grp.name); return
        }
        if !doms.isEmpty {
            for d in doms { appendApp("domain", d, "\(a.n) · \(d)") }
            note = L("已按域名添加：{}", a.n); return
        }
        note = L("没有已知域名：请填附加域名后再添加")
    }
    func searchOnline() async {
        busy = true; defer { busy = false }
        guard let t = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?term=\(t)&entity=software&limit=10&country=us") else { return }
        do {
            let (d, _) = try await URLSession.shared.data(from: url)
            let j = try JSONSerialization.jsonObject(with: d) as? [String: Any]
            online = (j?["results"] as? [[String: Any]] ?? []).map {
                ($0["trackName"] as? String ?? "", $0["bundleId"] as? String ?? "")
            }
            note = online.isEmpty ? L("没有找到") : ""
        } catch {
            note = L("在线搜索失败。内置库仍可用。")
        }
    }
}

// MARK: 内联：自定义域名
struct DomainsInline: View {
    @EnvironmentObject var store: Store
    @State private var text = ""
    @State private var policy = "PROXY"
    var list: [[String: Any]] { store.state["customDomains"] as? [[String: Any]] ?? [] }

    var body: some View {
        PlainCard {
            Text(L("每行一个域名（example.com 匹配自身与子域名）。")).font(.caption).foregroundStyle(.secondary)
            TextEditor(text: $text)
                .frame(minHeight: 80)
                .hideScrollBG()
                .textInputAutocapitalization(.never).autocorrectionDisabled()
            PolicyPicker(policy: $policy)
            Button(L("添加")) {
                var l = list
                for d in text.split(whereSeparator: { " ,\n".contains($0) }).map({ String($0).lowercased() }) where !d.isEmpty {
                    l.append(["domain": d, "policy": policy])
                }
                store.set("customDomains", l); text = ""
            }
            .buttonStyle(.borderedProminent).tint(Brand.pink)
        }
        if !list.isEmpty {
            PlainCard {
                Text(L("已添加（{}）", list.count)).font(.headline)
                ForEach(Array(list.enumerated()), id: \.offset) { i, c in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(c["domain"] as? String ?? "")
                            Text(c["policy"] as? String ?? "").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if i > 0 { Button { move(i, -1) } label: { Image(systemName: "arrow.up") } }
                        if i < list.count - 1 { Button { move(i, 1) } label: { Image(systemName: "arrow.down") } }
                        Button(role: .destructive) {
                            var l = list; l.remove(at: i); store.set("customDomains", l)
                        } label: { Image(systemName: "trash") }
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }
    func move(_ i: Int, _ d: Int) { var l = list; l.swapAt(i, i + d); store.set("customDomains", l) }
}

// MARK: 内联：Wi-Fi 通话（写入 opts + wifi 状态，参与生成）
struct WifiInline: View {
    @EnvironmentObject var store: Store
    @State private var q = ""
    @State private var mcc = ""
    @State private var mnc = ""
    @State private var carriers: [Carrier] = []

    var wifi: [String: Any] { store.state["wifi"] as? [String: Any] ?? [:] }
    var ids: [String] { wifi["ids"] as? [String] ?? [] }
    var shown: [Carrier] {
        let k = q.lowercased()
        let l = k.isEmpty ? carriers : carriers.filter {
            $0.n.lowercased().contains(k) || $0.cn.contains(q) || $0.c.lowercased() == k || $0.mcc == k
        }
        return Array(l.prefix(60))
    }

    var body: some View {
        PlainCard {
            Toggle(L("启用 Wi-Fi 通话规则"), isOn: Binding(
                get: { (store.opts["wifiCalling"] as? Bool) ?? false },
                set: { store.setOpt("wifiCalling", $0) }
            ))
            .tint(Brand.pink)
            Text(L("运营商 ePDG / IMS 域名直连，避免通话被代理。选择会写入生成配置。"))
                .font(.caption).foregroundStyle(.secondary)
            WifiCallNote()
        }
        PlainCard {
            Text(L("自定义 MCC / MNC")).font(.headline)
            HStack {
                TextField("MCC", text: $mcc).keyboardType(.numberPad)
                TextField("MNC", text: $mnc).keyboardType(.numberPad)
                Button(L("添加")) {
                    guard !mcc.isEmpty, !mnc.isEmpty else { return }
                    var w = wifi
                    var c = w["custom"] as? [[String: String]] ?? []
                    c.append(["mcc": mcc, "mnc": mnc]); w["custom"] = c
                    if w["ids"] == nil { w["ids"] = [String]() }
                    if w["extra"] == nil { w["extra"] = "" }
                    store.set("wifi", w); store.setOpt("wifiCalling", true)
                    mcc = ""; mnc = ""
                }
                .buttonStyle(.bordered)
            }
        }
        PlainCard {
            TextField(L("搜索运营商 / 国家"), text: $q).textInputAutocapitalization(.never)
            ForEach(shown) { c in
                Toggle(isOn: Binding(get: { ids.contains(c.id) }, set: { on in
                    var w = wifi; var l = ids
                    if on { l.append(c.id) } else { l.removeAll { $0 == c.id } }
                    w["ids"] = l
                    if w["custom"] == nil { w["custom"] = [[String: String]]() }
                    if w["extra"] == nil { w["extra"] = "" }
                    store.set("wifi", w)
                    if on { store.setOpt("wifiCalling", true) }
                })) {
                    VStack(alignment: .leading) {
                        Text("\(c.cn) · \(c.n)")
                        Text("MCC \(c.mcc) / MNC \(c.mnc)" + (c.st == "dns" ? L(" · 已验证") : L(" · 未验证")))
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .tint(Brand.pink)
            }
        }
        .onAppear { if carriers.isEmpty { carriers = store.engine.carriers() } }
    }
}

/// 按 App / 自定义域名 / Wi-Fi 通话的出口选择（系统菜单样式，已紧凑）。
/// 选项与规则页出口弹窗对齐：全部节点（自动/手动）+ 全部地区（故转/自动/手动）；选中未启用的地区会自动启用。
struct PolicyPicker: View {
    @EnvironmentObject var store: Store
    @Binding var policy: String
    var body: some View {
        Picker(L("出口"), selection: $policy) {
            Text(L("代理")).tag("PROXY"); Text(L("直连")).tag("DIRECT"); Text(L("拦截")).tag("REJECT")
            Text(L("全部 · 自动")).tag("ALL/a"); Text(L("全部 · 手动")).tag("ALL/m")
            ForEach(store.catalog.regions) { r in
                Text(L("{} · {}", r.name, L("故转"))).tag("R:\(r.id)")
                Text(L("{} · {}", r.name, L("自动"))).tag("R:\(r.id)/a")
                Text(L("{} · {}", r.name, L("手动"))).tag("R:\(r.id)/m")
            }
        }
        .pickerStyle(.menu)
        .onChange(of: policy) { p in
            if p.hasPrefix("R:") {
                let id = String(p.dropFirst(2).split(separator: "/").first ?? "")
                if !id.isEmpty && !store.regions.contains(id) { store.toggleRegion(id) }
            }
        }
    }
}

// MARK: 防泄漏
struct LeakView: View {
    @EnvironmentObject var store: Store
    @State private var items: [LeakItem] = []
    @State private var leakScore: (Int, String)? = nil
    var body: some View {
        PageChrome(title: L("防泄漏检查")) {
            PlainCard {
                Text(L("根据当前客户端与选项检查 IP / DNS / WebRTC 等风险。"))
                    .font(.footnote).foregroundStyle(.secondary)
                if let sc = leakScore {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(sc.0)").font(.system(size: 44, weight: .bold, design: .rounded)).foregroundStyle(Brand.pink)
                        Text(L("/ 100  综合防泄漏分")).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Text(sc.1).font(.caption2).foregroundStyle(.secondary)
                }
            }
            ForEach(items) { it in
                PlainCard {
                    HStack {
                        Text(it.title).font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(it.status).font(.caption2)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.primary.opacity(0.08), in: Capsule())
                    }
                    Text(it.group).font(.caption2).foregroundStyle(.secondary)
                    Text(it.why).font(.footnote)
                    if let h = it.how, !h.isEmpty {
                        Text(L("做法：") + h).font(.footnote).foregroundStyle(Brand.pink)
                    }
                }
            }
            PlainCard {
                Text(L("自测网站")).font(.headline)
                Link("browserleaks.com/ip", destination: URL(string: "https://browserleaks.com/ip")!)
                Link("browserleaks.com/dns", destination: URL(string: "https://browserleaks.com/dns")!)
                Link("ipleak.net", destination: URL(string: "https://ipleak.net")!)
            }
        }
        .onAppear { items = store.engine.leak(state: store.state); leakScore = store.engine.leakScore(state: store.state) }
    }
}

// MARK: 模块
struct ModulesView: View {
    @EnvironmentObject var store: Store
    @State private var url = ""
    @State private var name = ""
    @State private var msg = ""
    var mods: [[String: Any]] { store.state["modules"] as? [[String: Any]] ?? [] }

    var body: some View {
        PageChrome(title: L("模块与脚本")) {
            PlainCard {
                Text(L("导入去广告 / 增强分流模块。不推荐、不内置任何解锁付费 VIP 脚本。"))
                    .font(.footnote).foregroundStyle(.secondary)
                TextField(L("名称"), text: $name)
                TextField(L("https://…模块链接"), text: $url)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                Button(L("拉取并添加")) { Task { await add() } }
                    .buttonStyle(.borderedProminent).tint(Brand.pink)
                    .disabled(url.isEmpty)
                if !msg.isEmpty { Text(msg).font(.footnote).foregroundStyle(Brand.pink) }
            }
            ForEach(Array(mods.enumerated()), id: \.offset) { i, m in
                PlainCard {
                    HStack {
                        Text(m["name"] as? String ?? L("模块")).font(.subheadline.weight(.semibold))
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { (m["on"] as? Bool) ?? true },
                            set: { v in var l = mods; l[i]["on"] = v; store.set("modules", l) }
                        )).labelsHidden().tint(Brand.pink)
                        Button(role: .destructive) {
                            var l = mods; l.remove(at: i); store.set("modules", l)
                        } label: { Image(systemName: "trash") }
                        .buttonStyle(.borderless)
                    }
                    let info = store.engine.modInfo(
                        name: m["name"] as? String ?? "",
                        url: m["url"] as? String ?? "",
                        content: m["content"] as? String ?? "")
                    Text(L("格式 {} · 重写 {} · 脚本 {}", info["fmt"] as? String ?? "?", info["rw"] as? Int ?? 0, info["sc"] as? Int ?? 0))
                        .font(.caption).foregroundStyle(.secondary)
                    ForEach(info["blocked"] as? [String] ?? [], id: \.self) {
                        Text(L("已拦截：{}", $0)).font(.caption).foregroundStyle(.red)
                    }
                }
            }
        }
    }
    func add() async {
        msg = L("拉取中…")
        guard let u = URL(string: url.trimmingCharacters(in: .whitespaces)) else { msg = L("链接无效"); return }
        do {
            let (d, _) = try await URLSession.shared.data(from: u)
            let text = String(decoding: d, as: UTF8.self)
            var l = mods
            l.append(["id": UUID().uuidString, "name": name.isEmpty ? u.lastPathComponent : name,
                      "url": u.absoluteString, "content": text, "kind": "other", "on": true])
            store.set("modules", l); msg = L("已添加"); url = ""; name = ""
        } catch {
            msg = L("拉取失败：{}", error.localizedDescription)
        }
    }
}

// MARK: 远程 JS（独立模块，不写进配置文件，与生成配置互不影响）
struct RemoteJsView: View {
    @EnvironmentObject var store: Store
    @State private var showTemplate = false
    @State private var toast = ""
    @State private var showAddForm = false
    @State private var addName = ""
    @State private var addUrl = ""
    @State private var addAuthor = ""
    @State private var addSourceKind = 1 // 0 原创 / 1 分享
    @State private var addDesc = ""
    @State private var addKind = 0 // 0 config-override / 1 config-overwrite / 2 http-rewrite
    /// kind 的中文显示名
    func remoteJsKindName(_ kind: String) -> String {
        switch kind {
        case "config-override": return L("覆写配置链接")
        case "config-overwrite": return L("配置级 JS 覆写")
        case "http-rewrite": return L("HTTP 重写")
        default: return kind
        }
    }
    func libraryKindName(_ kind: String) -> String {
        switch kind {
        case "config-override": return L("覆写配置")
        case "config-overwrite": return L("JS 配置覆写")
        case "http-rewrite": return L("HTTP 重写")
        default: return kind
        }
    }
    /// 脚本库行（引擎种子 + 用户收藏，同一结构）
    struct LibraryRow: Identifiable {
        let id: String
        let name: String
        let url: String
        let sha256: String
        let kind: String
        let desc: String
        let sourceKind: String // "original" 原创 / "shared" 分享
        let author: String
        let authorUrl: String // 作者 GitHub 仓库链接（查看/更新用）
        let pendingMerge: Bool
        let custom: Bool // 用户自己收藏的
    }
    var libraryRows: [LibraryRow] {
        let seed = store.engine.remoteJsLibrary(client: store.client).compactMap { d -> LibraryRow? in
            guard let id = d["id"] as? String, let name = d["name"] as? String else { return nil }
            let src = d["source"] as? [String: Any]
            return LibraryRow(id: id, name: name, url: d["url"] as? String ?? "",
                              sha256: d["sha256"] as? String ?? "", kind: d["kind"] as? String ?? "",
                              desc: d["desc"] as? String ?? "",
                              sourceKind: src?["kind"] as? String ?? "shared",
                              author: src?["author"] as? String ?? "",
                              authorUrl: src?["authorUrl"] as? String ?? "",
                              pendingMerge: d["pendingMerge"] as? Bool ?? false, custom: false)
        }
        let mine = store.libraryCustom.map { d in
            LibraryRow(id: d["id"] ?? UUID().uuidString, name: d["name"] ?? "", url: d["url"] ?? "",
                       sha256: "", kind: d["kind"] ?? "", desc: d["desc"] ?? "",
                       sourceKind: d["sourceKind"] ?? "shared", author: d["author"] ?? "", authorUrl: "",
                       pendingMerge: false, custom: true)
        }
        return seed + mine
    }
    /// 来源仓库链接：优先条目自带的 authorUrl；原创走 Lowex 仓库 remote-scripts；否则从 raw 链接推导
    func repoLink(for row: LibraryRow) -> String {
        if !row.authorUrl.isEmpty { return row.authorUrl }
        if row.sourceKind == "original" && !row.custom { return "https://github.com/Kiwareu/Lowex/tree/main/remote-scripts" }
        let prefix = "https://raw.githubusercontent.com/"
        if row.url.hasPrefix(prefix) {
            let parts = row.url.dropFirst(prefix.count).split(separator: "/")
            if parts.count >= 2 { return "https://github.com/\(parts[0])/\(parts[1])" }
        }
        return ""
    }
    func repoShort(_ url: String) -> String {
        var t = url
        if t.hasPrefix("https://") { t = String(t.dropFirst(8)) }
        if t.hasPrefix("github.com/") { t = String(t.dropFirst(11)) }
        return t
    }
    func attributionText(for row: LibraryRow) -> String {
        if row.custom {
            let label = row.sourceKind == "original" ? L("原创") : L("分享")
            let author = row.author.isEmpty ? L("（待填写）") : row.author
            return "「\(row.name)」\n" + L("链接：") + row.url + "\n" + L("来源：") + "\(author)（\(label)）" + "\n" + L("SHA256：未锁定")
        }
        return store.engine.remoteJsLibraryAttribution(id: row.id)["text"] ?? ""
    }
    var body: some View {
        PageChrome(title: L("远程覆写 / 脚本重写")) {
            PlainCard {
                Text(L("远程覆写 / 脚本是独立功能：与「生成配置」互不影响，可同时使用；覆写内容不会写进配置文件。"))
                    .font(.footnote).foregroundStyle(.secondary)
                let sup = store.remoteJsSupport
                Text(L("当前客户端支持情况")).font(.subheadline.weight(.semibold))
                ForEach(sup.kinds, id: \.kind) { k in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: k.supported ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundStyle(k.supported ? Brand.pink : .secondary)
                            Text(remoteJsKindName(k.kind)).font(.caption.weight(.semibold))
                            Text(k.supported ? L("支持") : L("不支持")).font(.caption2)
                                .foregroundStyle(k.supported ? Brand.pink : .secondary)
                        }
                        Text(k.note).font(.caption2).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
                Toggle(L("启用远程覆写"), isOn: Binding(
                    get: { store.remoteJsMode },
                    set: { store.remoteJsMode = $0; store.saveRemoteJs() }
                )).tint(Brand.pink).disabled(!sup.anySupported)
                if !sup.anySupported {
                    Text(L("当前客户端三种类型都不支持，已禁用。")).font(.caption2).foregroundStyle(.secondary)
                }
            }
            if store.remoteJsSupport.anySupported {
                let activeKind = store.remoteJsActiveKind
                PlainCard {
                    Text(L("远程覆写引用")).font(.headline)
                    Text(L("在客户端里添加链接即可使用（以所选类型的客户端入口为准）。脚本库「填入引用」可一键填好。"))
                        .font(.caption2).foregroundStyle(.secondary)
                    ChoiceTabs(options: store.remoteJsSupport.kinds.filter { $0.supported }.map { ($0.kind, remoteJsKindName($0.kind)) },
                               selection: Binding(get: { store.remoteJsActiveKind }, set: { store.remoteJsKind = $0; store.saveRemoteJs() }))
                    TextField(activeKind == "config-override" ? L("https://… .yaml 覆写链接") : L("https://… .js 链接"), text: $store.remoteJsURL)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    if activeKind != "config-override" {
                        TextField(L("SHA256 锁定（可选，不填也能用）"), text: $store.remoteJsSHA256)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                        Text(L("不填也能用，但作者更新脚本后 App 不会察觉——只用你信任的来源；脚本库里原创脚本的哈希可一键填入。"))
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    TextField(L("名称（可选）"), text: $store.remoteJsName)
                    if activeKind == "http-rewrite" {
                        TextField(L("MITM hostname（逗号分隔，只写必需域名，绝不写 *）"), text: $store.remoteJsMITM)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                        Toggle(L("MITM 含敏感域名（支付 / 账号类），我已显式确认"), isOn: $store.remoteJsConfirmSensitive).tint(Brand.pink)
                    }
                    if !toast.isEmpty { Text(toast).font(.footnote).foregroundStyle(Brand.pink) }
                }
                PlainCard {
                    Text(L("自建模板")).font(.headline)
                    Text(L("不要直接用网上不明作者的脚本。把模板复制到你自己的 GitHub 仓库，填 URL + 该文件的 SHA256。"))
                        .font(.caption).foregroundStyle(.secondary)
                    Button { showTemplate.toggle() } label: {
                        Label(showTemplate ? L("收起模板") : L("查看模板"), systemImage: "eye").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    if showTemplate {
                        ScrollView {
                            Text(store.engine.remoteJsTemplate(kind: store.remoteJsActiveKind))
                                .font(.caption2.monospaced()).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 220)
                    }
                    Button {
                        UIPasteboard.general.string = store.engine.remoteJsTemplate(kind: store.remoteJsActiveKind)
                        toast = L("模板已复制")
                    } label: {
                        Label(L("复制自建模板"), systemImage: "doc.on.doc").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).tint(Brand.pink)
                }
                PlainCard {
                    Text(L("脚本库")).font(.headline)
                    Text(L("点「复制链接」即用；每条都标了作者和来源仓库链接，想看更新去作者仓库。"))
                        .font(.caption).foregroundStyle(.secondary)
                    ForEach(libraryRows) { row in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(row.name).font(.headline)
                                Spacer()
                                Text(libraryKindName(row.kind))
                                    .font(.caption2).foregroundStyle(.secondary)
                                    .padding(.horizontal, 6).padding(.vertical, 3)
                                    .background(Color.secondary.opacity(0.12))
                                    .clipShape(Capsule())
                                Text(row.sourceKind == "original" ? L("原创") : L("分享 · ") + (row.author.isEmpty ? L("未知作者") : row.author))
                                    .font(.caption2).padding(.horizontal, 8).padding(.vertical, 3)
                                    .background((row.sourceKind == "original" ? Brand.pink : Color.orange).opacity(0.15))
                                    .foregroundStyle(row.sourceKind == "original" ? Brand.pink : Color.orange)
                                    .clipShape(Capsule())
                            }
                            if !row.desc.isEmpty {
                                Text(row.desc).font(.footnote).foregroundStyle(.secondary)
                            }
                            if !row.url.isEmpty {
                                Text(row.url).font(.caption2.monospaced())
                                    .lineLimit(1).truncationMode(.middle).foregroundStyle(.secondary)
                            }
                            if !repoLink(for: row).isEmpty {
                                HStack(spacing: 2) {
                                    Text(L("来源仓库：")).font(.caption2).foregroundStyle(.secondary)
                                    if let u = URL(string: repoLink(for: row)) {
                                        Link(repoShort(repoLink(for: row)), destination: u).font(.caption2)
                                    }
                                }
                            }
                            if row.pendingMerge {
                                Text(L("待分支合并到 main 后链接生效")).font(.caption2).foregroundStyle(.orange)
                            }
                            if row.sourceKind == "shared" && row.sha256.isEmpty {
                                Text(L("未哈希锁定：仅复制链接，请在客户端里自行核验来源后使用")).font(.caption2).foregroundStyle(.orange)
                            }
                            if row.kind == "config-override" {
                                Text(L("在代理软件的 覆写/Override 里添加配置链接")).font(.caption2).foregroundStyle(Brand.pink)
                            }
                            HStack(spacing: 10) {
                                Button {
                                    UIPasteboard.general.string = row.url
                                    toast = L("链接已复制")
                                } label: {
                                    Label(L("复制链接"), systemImage: "link").font(.caption)
                                }.buttonStyle(.bordered).disabled(row.url.isEmpty)
                                Button {
                                    UIPasteboard.general.string = attributionText(for: row)
                                    toast = L("来源标注已复制")
                                } label: {
                                    Label(L("复制来源标注"), systemImage: "quote.bubble").font(.caption)
                                }.buttonStyle(.bordered)
                                // 覆写配置链接（.yaml）在代理软件里直接添加，不走 App 内校验，故不提供「填入引用」
                                if row.kind != "config-override" && !row.url.isEmpty {
                                    Button {
                                        store.remoteJsKind = row.kind
                                        store.remoteJsURL = row.url
                                        store.remoteJsSHA256 = row.sha256
                                        store.remoteJsName = row.name
                                        store.saveRemoteJs()
                                        toast = row.sha256.isEmpty ? L("已填入引用（未锁定：只用信任的来源）") : L("已填入引用，可去校验")
                                    } label: {
                                        Label(L("填入引用"), systemImage: "arrow.down.doc").font(.caption)
                                    }.buttonStyle(.bordered).disabled(row.pendingMerge)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                        Divider()
                    }
                    Button { showAddForm.toggle() } label: {
                        Label(showAddForm ? L("收起") : L("添加我的收藏"), systemImage: "plus").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    if showAddForm {
                        VStack(spacing: 8) {
                            TextField(L("名称"), text: $addName)
                            ChoiceTabs(options: [(0, L("覆写配置链接")), (1, L("JS 配置覆写")), (2, L("HTTP 重写"))], selection: $addKind)
                            TextField(addKind == 0 ? L("https://… .yaml 链接") : L("https://… .js 链接"), text: $addUrl)
                                .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                            TextField(L("作者"), text: $addAuthor).textInputAutocapitalization(.never).autocorrectionDisabled()
                            ChoiceTabs(options: [(0, L("原创")), (1, L("分享"))], selection: $addSourceKind)
                            TextField(L("说明（可选）"), text: $addDesc)
                            Button {
                                let u = addUrl.trimmingCharacters(in: .whitespacesAndNewlines)
                                let lu = u.lowercased()
                                let kindStr = ["config-override", "config-overwrite", "http-rewrite"][addKind]
                                let urlOk: Bool
                                if kindStr == "config-override" {
                                    urlOk = lu.hasPrefix("https") && (lu.hasSuffix(".yaml") || lu.hasSuffix(".yml"))
                                } else {
                                    urlOk = lu.hasPrefix("https") && lu.hasSuffix(".js")
                                }
                                guard urlOk else {
                                    toast = kindStr == "config-override" ? L("链接须以 https 开头、以 .yaml/.yml 结尾") : L("链接须以 https 开头、以 .js 结尾")
                                    return
                                }
                                store.addLibraryCustom(name: addName.trimmingCharacters(in: .whitespacesAndNewlines),
                                                       url: u, author: addAuthor.trimmingCharacters(in: .whitespacesAndNewlines),
                                                       sourceKind: addSourceKind == 0 ? "original" : "shared",
                                                       desc: addDesc, kind: kindStr)
                                addName = ""; addUrl = ""; addAuthor = ""; addDesc = ""
                                showAddForm = false
                                toast = L("已加入我的收藏")
                            } label: {
                                Label(L("保存到我的收藏"), systemImage: "bookmark").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent).tint(Brand.pink)
                        }
                    }
                }
            }
        }
    }
}

// MARK: 作者自用
struct SharedView: View {
    @EnvironmentObject var store: Store
    @State private var items: [[String: Any]] = []
    @State private var note = ""
    var body: some View {
        PageChrome(title: L("作者自用规则")) {
            if !note.isEmpty { PlainCard { Text(note).foregroundStyle(Brand.pink) } }
            ForEach(Array(items.enumerated()), id: \.offset) { _, e in
                PlainCard {
                    Text(e["name"] as? String ?? "").font(.headline)
                    Text(e["desc"] as? String ?? "").font(.footnote)
                    ForEach(e["notes"] as? [String] ?? [], id: \.self) {
                        Text("• " + $0).font(.caption).foregroundStyle(.secondary)
                    }
                    Button(L("加入我的方案")) { apply(e) }.buttonStyle(.bordered)
                }
            }
        }
        .onAppear { if items.isEmpty { items = store.engine.shared() } }
    }
    func apply(_ e: [String: Any]) {
        if let gs = e["groups"] as? [[String: Any]] {
            var cur = store.groupState
            for g in gs {
                if let id = g["id"] as? String {
                    cur[id] = ["on": true, "policy": g["policy"] as? String ?? "PROXY"]
                }
            }
            store.set("groups", cur)
        }
        if let ds = e["domains"] as? [[String: Any]] {
            var l = store.state["customDomains"] as? [[String: Any]] ?? []
            for d in ds where !l.contains(where: { ($0["domain"] as? String) == (d["domain"] as? String) }) {
                l.append(d)
            }
            store.set("customDomains", l)
        }
        if let ss = e["sets"] as? [[String: Any]] {
            var l = store.state["customSets"] as? [[String: Any]] ?? []
            for s in ss { var x = s; x["id"] = UUID().uuidString; l.append(x) }
            store.set("customSets", l)
        }
        if let o = e["opts"] as? [String: Any] {
            var cur = store.opts
            for (k, v) in o { cur[k] = v }
            store.set("opts", cur)
        }
        note = L("已加入「{}」。", e["name"] as? String ?? "")
    }
}

// MARK: 关于
struct AboutView: View {
    @EnvironmentObject var store: Store
    var body: some View {
        PageChrome(title: L("关于")) {
            HeroCard {
                HStack(spacing: 14) {
                    Image("BrandMark")
                        .resizable().scaledToFit()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Brand.pink.opacity(0.35), radius: 10, y: 4)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Lowex")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(LinearGradient(colors: [Brand.pink, Brand.lilac],
                                                            startPoint: .leading, endPoint: .trailing))
                        Text(L("本机生成 · 不上传"))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Text(L("Lowex 是一款在本机生成代理 / 分流配置的工具：选好客户端与选项，粘贴节点或订阅，即可导出适合各客户端的配置文件。"))
                    .font(.footnote)
                Text(L("工作方式：所有生成都在本机完成，没有服务器，不上传节点或订阅。界面使用 SwiftUI 编写，规则引擎使用 TypeScript，打包后在系统自带的 JavaScriptCore 中运行。"))
                    .font(.footnote)
                Text(L("材质：iOS 26 及以上使用系统的 Liquid Glass；更早的系统自动回退为系统模糊材质。"))
                    .font(.footnote).foregroundStyle(.secondary)
                Link(destination: URL(string: "https://github.com/Kiwareu/Lowex")!) {
                    Label(L("GitHub 项目 github.com/Kiwareu/Lowex"), systemImage: "chevron.left.forwardslash.chevron.right")
                }
                .font(.footnote)
                Link(destination: URL(string: "https://github.com/Kiwareu/Lowex-Icons")!) {
                    Label(L("图标库 github.com/Kiwareu/Lowex-Icons"), systemImage: "photo.on.rectangle")
                }
                .font(.footnote)
                Link(destination: URL(string: "https://github.com/Kiwareu/Lowex/issues")!) {
                    Label(L("反馈问题 github.com/Kiwareu/Lowex/issues"), systemImage: "bubble.left.and.exclamationmark.bubble.right")
                }
                .font(.footnote)
            }
            PlainCard {
                Text(L("使用步骤")).font(.headline)
                Text(L("1. 首页选客户端与选项\n2. 节点页粘贴节点或订阅 URL\n3. 规则页调分流 / App / Wi-Fi 通话\n4. 生成页一键导出、分享或打开客户端"))
                    .font(.footnote).foregroundStyle(.secondary)
            }
            PlainCard {
                Text(L("版本")).font(.headline)
                Text(L("{} · 引擎 {}", store.versionLabel, store.engine.version)).fpsSecret()
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}


// MARK: 免责声明
struct DisclaimerView: View {
    var body: some View {
        PageChrome(title: L("免责声明")) {
            HeroCard {
                Text(L("重要提示")).font(.title3.weight(.semibold))
                Text(L("请在使用 Lowex 前仔细阅读以下条款。继续使用即视为已知悉并同意。"))
                    .font(.footnote).foregroundStyle(.secondary)
            }
            PlainCard {
                Text(DisclaimerText.body)
                    .font(.footnote)
                    .foregroundStyle(Brand.ink.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

enum DisclaimerText {
    static var body: String {
        [
        L(L("一、性质与用途")),
        L(L("Lowex 是在用户本机运行的网络配置模板生成工具，协助用户把自己提供的节点 / 订阅与公开的分流规则整理成各类代理 / 分流客户端可读的配置文件。它不提供、不出售、不推荐任何代理服务器、节点、订阅或网络接入服务，也不内置任何订阅。")),
        "",
        L(L("二、合法使用")),
        L(L("用户应自行确保其使用符合所在地适用的法律法规、监管要求，以及所使用网络、平台与服务的条款。本项目不鼓励、不教唆、不协助任何违法或违反服务条款的行为，也不倡导规避任何服务的访问限制、付费或安全机制。因用户的使用方式、导入的节点 / 订阅或所用第三方客户端产生的一切责任，由用户自行承担。")),
        "",
        L(L("三、无担保")),
        L(L("本软件按「现状」（AS IS）和「可用」状态提供，不附带任何明示或默示的担保，包括但不限于适销性、特定用途适用性、不侵权、无错误或不中断。生成的配置可能因客户端版本、网络环境或所选选项而无效或需要调整，请在使用前自行检查。")),
        "",
        L(L("四、责任限制")),
        L(L("在适用法律允许的最大范围内，作者与贡献者不对因使用或无法使用本软件产生的任何直接、间接、附带、特殊或后果性损失负责，包括但不限于账号被冻结或封禁、资金与风控限制、数据泄露、服务中断、法律责任，即使已被告知可能发生此类损失。")),
        "",
        L(L("五、第三方内容")),
        L(L("规则、图标、客户端名称与商标属于各自权利人，仅作指示用途，与其无隶属、授权或背书关系。涉及银行、券商、支付与加密货币平台的规则分组仅是域名分流模板，不构成金融、法律或税务建议，请遵守相关平台的条款与当地法律。用户自行导入的模块、脚本、订阅与规则集由其来源方负责，使用前请自行审查。")),
        "",
        L(L("六、安全与隐私")),
        L(L("所有生成都在本机完成，没有服务器，不上传节点、订阅、配置或使用数据；手动节点的密码只保存在本机钥匙串。「防泄漏」只能降低配置层面的风险，不保证匿名、安全或不被识别。请勿在公开 Issue 中贴出节点、订阅链接或令牌。")),
        "",
        L(L("七、AI 辅助开发与测试说明")),
        L(L("本项目在开发与测试中使用了 AI 辅助工具。虽然做过自动化校验（如内核配置检查与随机选项测试），仍可能存在错误或遗漏，也没有在所有客户端、系统版本和设备上测试过；请自行验证生成结果。")),
        "",
        L(L("八、许可")),
        L(L("本软件以 MIT 许可证发布，详见仓库中的 LICENSE；第三方资源遵循各自的许可。")),
        "",
        L(L("九、联系")),
        L(L("如有疑问，请通过 GitHub 项目页的 Issues 反馈。")),
        "",
        L(L("最后更新日期：2026-10-17"))
        ].joined(separator: "\n")
    }
}


/// Wi-Fi 通话提示：规则会生成，但能否生效取决于用户自己的环境
struct WifiCallNote: View {
    @EnvironmentObject var store: Store
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(L("规则已支持并会写入配置，但 Wi-Fi 通话能否生效取决于你自己的情况：客户端、iOS 版本、运营商和所用节点。"), systemImage: "info.circle")
            if store.family == "singbox" && store.isMobilePlatform {
                Label(L("sing-box 在 iOS 上对 Wi-Fi 通话的支持有限，遇到问题请优先尝试直连并检查客户端的蜂窝网络 / 全局代理设置。"), systemImage: "exclamationmark.triangle")
            }
        }
        .font(.caption2).foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
}
