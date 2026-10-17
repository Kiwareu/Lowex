import SwiftUI

// MARK: - 更多（轻量：模块 / 防泄漏 / 作者分享 / 关于）
struct MoreView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var lang: Lang
    var body: some View {
        NavigationStack {
            ZStack {
                PinkBackground()
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        Text(L("更多"))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Brand.ink)
                            .padding(.top, 6)

                        PlainCard {
                            Text(L("主流程已移到首页 / 节点 / 规则 / 生成。这里只放辅助项。"))
                                .font(.footnote).foregroundStyle(.secondary)
                        }

                        Button { store.showAppearance = true } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "paintpalette.fill").foregroundStyle(Brand.pink).frame(width: 28)
                                Text(L("外观与主题（壁纸 / 玻璃 / 颜色）")).foregroundStyle(Brand.ink)
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(14).softCard()
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
                        .padding(14).softCard()
                        navCard(L("防泄漏检查清单"), icon: "shield.lefthalf.filled", dest: LeakView())
                        if store.engine.supportsModules(client: store.client) {
                            navCard(L("模块与脚本"), icon: "puzzlepiece.extension", dest: ModulesView())
                        }
                        navCard(L("作者自用规则分享"), icon: "person.crop.circle.badge.checkmark", dest: SharedView())
                        navCard(L("备份与恢复 Lowex 设置"), icon: "externaldrive.badge.icloud", dest: BackupView())
                        navCard(L("免责声明"), icon: "exclamationmark.shield.fill", dest: DisclaimerView())
                        navCard(L("关于 Lowex"), icon: "info.circle", dest: AboutView())
                        Link(destination: URL(string: "https://github.com/Kiwareu/Lowex")!) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                Text(L("GitHub 项目主页")).font(.subheadline.weight(.medium))
                                Spacer()
                                Image(systemName: "arrow.up.right").font(.caption)
                            }
                            .padding(14).frame(maxWidth: .infinity)
                            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
                .scrollBounceBehavior(.basedOnSize)
                .contentMargins(.bottom, 56, for: .scrollContent)
                BottomFade()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func navCard<V: View>(_ title: String, icon: String, dest: V) -> some View {
        NavigationLink {
            dest
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundStyle(Brand.pink).frame(width: 28)
                Text(title).foregroundStyle(Brand.ink)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            .padding(14)
            .softCard()
        }
        .buttonStyle(.plain)
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
                        Text(item.0).lineLimit(1)
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
                .scrollContentBackground(.hidden)
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

struct PolicyPicker: View {
    @EnvironmentObject var store: Store
    @Binding var policy: String
    var body: some View {
        Picker(L("出口"), selection: $policy) {
            Text(L("代理")).tag("PROXY"); Text(L("直连")).tag("DIRECT"); Text(L("拦截")).tag("REJECT")
            ForEach(store.catalog.regions.filter { store.regions.contains($0.id) }) {
                Text(L("{} 节点", $0.name)).tag("R:\($0.id)")
            }
        }
        .pickerStyle(.menu)
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
                        Text(L("原生 SwiftUI · 引擎 {}", store.engine.version))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Text(L("界面为原生 SwiftUI；规则引擎与网页版同一份。iOS 26 起用系统 Liquid Glass，iOS 18–25 为系统材质。所有生成只在本机完成，不上传。"))
                    .font(.footnote)
                Link(destination: URL(string: "mailto:wenx@xewol.com")!) {
                    Label(L("联系作者 wenx@xewol.com"), systemImage: "envelope")
                }
                .font(.footnote)
                Link(destination: URL(string: "https://github.com/Kiwareu/Lowex")!) {
                    Label(L("GitHub 项目 github.com/Kiwareu/Lowex"), systemImage: "chevron.left.forwardslash.chevron.right")
                }
                .font(.footnote)
                Link(destination: URL(string: "https://github.com/Kiwareu/Lowex-Icons")!) {
                    Label(L("图标库 github.com/Kiwareu/Lowex-Icons"), systemImage: "photo.on.rectangle")
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
                Text(L("{} · 引擎 {}", store.versionLabel, store.engine.version))
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
        L(L("Lowex 是一款在用户本机运行的网络配置模板生成工具，用于协助用户整理、生成各类网络代理 / 分流客户端的配置文件结构（规则、策略组、DNS 等）。本软件不提供任何代理服务器、节点、订阅内容或翻墙服务，亦不引导、怂恿或协助用户从事违反中华人民共和国法律法规的行为。")),
        "",
        L(L("二、合法合规（尤其适用于中国大陆用户）")),
        L(L("用户应自行确保其使用行为符合所在地法律法规及监管要求。作者明确声明：不参与、不提倡、不协助任何规避国家法律监管、破坏网络秩序或未经授权访问境外网络资源的行为。因用户自身用途、导入的节点/订阅、或第三方客户端使用方式所产生的一切法律责任，由用户自行承担。")),
        "",
        L(L("三、内容边界")),
        L(L("1. Lowex 仅生成本地配置模板与规则思路，不上传用户方案、节点或订阅。")),
        L(L("2. 「作者自用规则分享」等示例仅含结构与思路，不含任何私人订阅地址、服务器、密钥或节点。")),
        L(L("3. 模块与脚本入口供用户自行导入公开资源；本软件不内置、不推荐用于解锁商业付费内容或破解类脚本。")),
        "",
        L(L("四、无担保")),
        L(L("本软件按「现状」提供，不作适销性、特定用途适用性或无错误的明示或默示担保。生成的配置可能因客户端版本、网络环境或用户选项而无效或需调整；作者不对直接或间接损失负责。")),
        "",
        L(L("五、联系")),
        L(L("如有疑问，可联系作者：wenx@xewol.com。")),
        "",
        L(L("最后更新日期：2026-10-16"))
        ].joined(separator: "\n")
    }
}
