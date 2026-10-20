import SwiftUI
import UIKit
import UniformTypeIdentifiers
import CoreImage.CIFilterBuiltins

// MARK: - 文件导出
struct ConfigDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText, .json, .data] }
    static var writableContentTypes: [UTType] { [.plainText, .json, .data] }
    var text: String
    init(text: String) { self.text = text }
    init(configuration: ReadConfiguration) throws {
        text = String(data: configuration.file.regularFileContents ?? Data(), encoding: .utf8) ?? ""
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

struct ShareFile: Identifiable { let id = UUID(); let url: URL }

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// 「存储到文件」：直接把带正确扩展名的文件交给系统文件选择器导出。
/// 以前用 SwiftUI fileExporter + FileDocument：当 contentType 不在文档声明的 writableContentTypes 里时（.yaml / .conf 等动态类型就是这样），
/// 系统会退回第一个可写类型 .plainText，于是文件被存成 .txt。UIDocumentPickerViewController(forExporting:) 按文件 URL 原样导出，扩展名不会变。
struct DocumentExporter: UIViewControllerRepresentable {
    let url: URL
    var onDone: (Bool) -> Void
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let vc = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
        vc.delegate = context.coordinator
        return vc
    }
    func updateUIViewController(_ vc: UIDocumentPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onDone: onDone) }
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDone: (Bool) -> Void
        init(onDone: @escaping (Bool) -> Void) { self.onDone = onDone }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) { onDone(true) }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { onDone(false) }
    }
}

/// 「用客户端打开」：系统「打开方式」菜单，只列出声明能打开该文件的 App（Surge / Shadowrocket / Stash 等）。
final class OpenInPresenter: NSObject, UIDocumentInteractionControllerDelegate {
    static let shared = OpenInPresenter()
    private var controller: UIDocumentInteractionController?
    @discardableResult
    func present(url: URL) -> Bool {
        guard let root = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.windows.first(where: \.isKeyWindow) }).first?.rootViewController else { return false }
        var top = root
        while let p = top.presentedViewController { top = p }
        let d = UIDocumentInteractionController(url: url)
        d.delegate = self
        controller = d
        let rect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.maxY - 90, width: 1, height: 1)
        return d.presentOpenInMenu(from: rect, in: top.view, animated: true)
    }
}

enum QR {
    static func image(_ s: String) -> UIImage? {
        let f = CIFilter.qrCodeGenerator()
        f.message = Data(s.utf8); f.correctionLevel = "L"
        guard let out = f.outputImage?.transformed(by: CGAffineTransform(scaleX: 8, y: 8)),
              let cg = CIContext().createCGImage(out, from: out.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

// MARK: - 导入链接（scheme 均来自各客户端官方 / 项目文档，见 docs/IMPORT-SCHEMES.md）
struct ImportScheme {
    let appName: String
    let open: String                 // 仅唤起 App
    let build: ((String, String) -> String)?   // (远程配置 URL, 名称) → 一键导入链接
    let note: String
}

enum ClientOpen {
    private static func enc(_ s: String) -> String {
        var cs = CharacterSet.alphanumerics; cs.insert(charactersIn: "-._~")
        return s.addingPercentEncoding(withAllowedCharacters: cs) ?? s
    }
    static func scheme(for client: String) -> ImportScheme? {
        switch client {
        case "surge":
            return ImportScheme(appName: "Surge", open: "surge:///", build: { u, _ in "surge:///install-config?url=\(enc(u))" }, note: L("官方手册：surge:///install-config?url=（URL 需百分号编码）"))
        case "loon":
            return ImportScheme(appName: "Loon", open: "loon://", build: { u, _ in "loon://import?sub=\(enc(u))" }, note: L("官方文档：loon://import?sub=（远程配置）"))
        case "stash":
            return ImportScheme(appName: "Stash", open: "stash://", build: { u, _ in "stash://install-config?url=\(enc(u))" }, note: L("官方文档 stash.wiki：stash://install-config?url=（URL 需编码）"))
        case "egern":
            return ImportScheme(appName: "Egern", open: "egern://", build: { u, n in "egern:/profiles/new?name=\(enc(n))&url=\(enc(u))" }, note: L("官方文档：egern:/profiles/new?name=&url="))
        case "shadowrocket":
            return ImportScheme(appName: "Shadowrocket", open: "shadowrocket://", build: { u, _ in "shadowrocket://config/add/\(u)" }, note: L("社区手册 LOWERTOP/Shadowrocket：shadowrocket://config/add/{url}；官方未公开文档，未在真机验证，失败请用「用 Shadowrocket 打开文件」"))
        case "qx":
            return ImportScheme(appName: "Quantumult X", open: "quantumult-x://", build: nil, note: L("官方 scheme 只支持导入资源片段（节点/分流/重写），不支持整份配置；请用分享或复制后在 设置→配置文件 粘贴"))
        case "singbox":
            return ImportScheme(appName: "sing-box", open: "sing-box://", build: { u, n in "sing-box://import-remote-profile?url=\(enc(u))#\(enc(n))" }, note: L("官方文档：sing-box://import-remote-profile?url="))
        case "karing":
            return ImportScheme(appName: "Karing", open: "karing://", build: { u, n in "karing://install-config?url=\(enc(u))&name=\(enc(n))" }, note: L("官方文档：karing://install-config?url=&name="))
        case "clashmi":
            return ImportScheme(appName: "Clash Mi", open: "clash://", build: { u, n in "clash://install-config?url=\(enc(u))&name=\(enc(n))" }, note: L("同 Karing 系：clash://install-config?url="))
        case "clashparty":
            return ImportScheme(appName: "Clash Party", open: "mihomo://", build: { u, n in "mihomo://install-config?url=\(enc(u))&name=\(enc(n))" }, note: L("Clash Party 文档：mihomo://install-config?url=&name="))
        case "verge", "cmfa":
            let name = client == "verge" ? "Clash Verge" : "ClashMeta for Android"
            return ImportScheme(appName: name, open: "clash://", build: { u, _ in "clash://install-config?url=\(enc(u))" }, note: L("Clash 通用：clash://install-config?url=（Verge Rev 文档已确认）"))
        case "flclash":
            return ImportScheme(appName: "FlClash", open: "flclash://", build: { u, _ in "flclash://install-config?url=\(enc(u))" }, note: L("FlClash README：clash:// / clashmeta:// / flclash:// 均可"))
        default: return nil
        }
    }
    static func hint(for client: String) -> String? {
        switch client {
        case "shadowrocket": return L("Shadowrocket：先在首页加节点 / 订阅，再导入 conf。策略组靠正则收纳，conf 内不含节点。")
        case "surge": return L("Surge：配置 → 新建 → 从文件 / 粘贴导入。")
        case "qx": return L("Quantumult X：设置 → 配置文件 → 下载 / 编辑，粘贴或导入。")
        case "loon": return L("Loon：配置 → 新建 → 本地文件。")
        case "stash", "clashmi": return L("Clash / Mihomo / Stash：配置 → 从文件导入 YAML。")
        case "singbox", "karing": return L("sing-box / Karing：导入 JSON；节点须已在 Lowex 展开。")
        default: return nil
        }
    }
}

// MARK: - 生成页
struct GenerateView: View {
    @EnvironmentObject var store: Store
    @State private var showPreview = false
    @State private var shareFile: ShareFile?
    @State private var toast = ""
    @State private var exportFile: ShareFile?
    @State private var qrImage: UIImage?
    @State private var qrCaption = ""
    @State private var showQR = false
    @State private var confirmClear = false

    var body: some View {
        PageChrome(title: L("生成")) {
            HeroCard {
                Text(L("④ 生成与导出")).font(.title3.weight(.semibold))
                summaryBlock
                Button {
                    toast = ""
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) { store.generate() }
                    if store.result.error == nil && !store.result.text.isEmpty { toast = L("已生成 {}", store.result.name) }
                } label: {
                    Label(store.generating ? (store.fetchingSubs ? L("正在拉取订阅…") : L("生成中…")) : L("生成配置"), systemImage: "sparkles").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(Brand.pink)
                .disabled(store.generating)
                Button(role: .destructive) { confirmClear = true } label: {
                    Label(L("清除配置"), systemImage: "trash").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(store.generating)

                if let e = store.result.error { Text(e).foregroundStyle(.red).font(.footnote) }
                ForEach(store.result.warnings, id: \.self) { w in
                    Text("• \(w)").font(.caption).foregroundStyle(.orange)
                }
                if !store.validationIssues.isEmpty {
                    Text(L("校验结果")).font(.subheadline.weight(.semibold))
                    ForEach(store.validationIssues) { issue in
                        Text("• \(issue.msg)").font(.caption).foregroundStyle(issue.isError ? .red : .orange)
                    }
                }
                if store.hasValidationErrors {
                    Text(L("校验发现错误，导出与导入已阻止：请先修正上面列出的错误，再导出。"))
                        .font(.caption).foregroundStyle(.red)
                }
            }

            if !store.result.text.isEmpty {
                exportCard
                importCard
                if showPreview {
                    PlainCard {
                        Text(L("完整预览（{} 字符，可滚动 / 长按选择 / 复制）", store.result.text.count)).font(.headline)
                        FullTextView(text: store.result.text)
                            .frame(height: 420)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            } else {
                PlainCard {
                    Text(L("还没有生成结果")).font(.subheadline.weight(.medium))
                    Text(store.family == "shadowrocket"
                         ? L("Shadowrocket 可直接生成：配置只含规则与策略组。请先在 App 首页加好节点。")
                         : L("即使不粘贴节点也可以生成（部分客户端会留订阅占位）；导入后再补节点。"))
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            if !toast.isEmpty { Text(toast).font(.footnote).foregroundStyle(Brand.pink) }
        }
        .onChangeValue(of: store.result.text) { n in if n.isEmpty { toast = ""; showPreview = false } }
        .overlay {
            if confirmClear {
                GlassConfirm(title: L("清除配置"),
                    message: L("「只清除生成结果」不改你的选择；「重置」会把规则、分组、功能开关恢复默认，节点、订阅、手动节点和配置名不动。"),
                    actions: [
                        .init(title: L("只清除生成结果"), destructive: false) { withAnimation { store.clearResult(); toast = L("已清除生成结果") } },
                        .init(title: L("清除并重置规则 / 分组选项（保留节点与订阅）"), destructive: true) { withAnimation { store.resetSelections(); toast = L("已重置选项，节点与订阅保留") } },
                    ],
                    dismiss: { confirmClear = false })
            }
        }
        .sheet(item: $shareFile) { ActivityView(items: [$0.url]) }
        .sheet(isPresented: $showQR) {
            VStack(spacing: 14) {
                Text(L("二维码")).font(.headline)
                if let q = qrImage { Image(uiImage: q).interpolation(.none).resizable().scaledToFit().frame(maxWidth: 300).padding(10).background(Color.white) }
                Text(qrCaption).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
                Button(L("关闭")) { showQR = false }.buttonStyle(.bordered)
            }
            .padding(24).detentsCompat()
        }
        .sheet(item: $exportFile) { f in
            DocumentExporter(url: f.url) { ok in
                exportFile = nil
                toast = ok ? L("已保存到「文件」") : L("已取消")
            }
        }
    }

    /// 文件名保证带该客户端的扩展名（yaml / conf / json）
    private var fileName: String {
        let n = store.result.name.isEmpty ? "lowex" : store.result.name
        let want = store.clientInfo?.fileExt ?? "conf"
        return (n as NSString).pathExtension.lowercased() == want ? n : (n as NSString).deletingPathExtension + "." + want
    }
    private func prepareSave() {
        if let u = TempFile.make(name: fileName, text: store.result.text) { exportFile = ShareFile(url: u) }
        else { toast = L("写临时文件失败") }
    }

    private var exportCard: some View {
        PlainCard {
            Text(L("导出")).font(.headline)
            Text(L("文件 {} · {} 字符", fileName, store.result.text.count)).font(.caption).foregroundStyle(.secondary)
            if store.hasValidationErrors {
                Text(L("校验有错误，导出已阻止（预览仍可看）。")).font(.caption).foregroundStyle(.red)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                actionBtn(L("复制全部"), icon: "doc.on.doc", disabled: store.hasValidationErrors) { UIPasteboard.general.string = store.result.text; toast = L("已复制到剪贴板") }
                actionBtn(L("系统分享"), icon: "square.and.arrow.up", disabled: store.hasValidationErrors) { prepareShare() }
                actionBtn(L("保存到「文件」"), icon: "folder", disabled: store.hasValidationErrors) { prepareSave() }
                actionBtn(showPreview ? L("收起预览") : L("完整预览"), icon: "eye") { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showPreview.toggle() } }
                actionBtn(L("配置二维码"), icon: "qrcode", disabled: store.hasValidationErrors) { showConfigQR() }
                actionBtn(L("复制文件名"), icon: "textformat", disabled: store.hasValidationErrors) { UIPasteboard.general.string = store.result.name; toast = L("已复制文件名") }
            }
            Text(L("二维码仅在配置较小（约 2.4KB 内）时可用；大配置请用文件 / 分享，或填下方在线地址生成导入二维码。"))
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    private var importCard: some View {
        PlainCard {
            Text(L("导入到客户端")).font(.headline)
            if let hint = store.importHow ?? ClientOpen.hint(for: store.client) {
                Text(hint).font(.caption2).foregroundStyle(.secondary)
            }
            if let sc = ClientOpen.scheme(for: store.client) {
                Text(L("一键导入需要配置的在线（https）地址：scheme 无法携带整份本地文件。把导出的文件放到你自己的 GitHub Gist / 对象存储 / 私有服务后，把直链填到这里。"))
                    .font(.caption2).foregroundStyle(.secondary)
                TextField(L("https://… 配置直链（可选）"), text: $store.remoteURL)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    .padding(10).background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                let link = linkURL(sc)
                if store.platform == "ios" {
                    if link != nil {
                        Button { openLink(link, sc) } label: {
                            Label(L("一键导入到 {}", sc.appName), systemImage: "arrow.up.forward.app").frame(maxWidth: .infinity)
                        }.buttonStyle(.borderedProminent).tint(Brand.pink)
                        .disabled(store.hasValidationErrors)
                    } else {
                        Text(L("还没有填配置直链：下面的「用 {} 打开文件」会把配置文件本身交给它，由它的导入页处理；只「唤起」App 不会进入导入页。", sc.appName))
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 10) {
                        if link == nil {
                            Button { openFile(sc) } label: {
                                Label(L("用 {} 打开文件", sc.appName), systemImage: "square.and.arrow.down.on.square").frame(maxWidth: .infinity)
                            }.buttonStyle(.borderedProminent).tint(Brand.pink)
                            .disabled(store.hasValidationErrors)
                        } else {
                            Button { openFile(sc) } label: {
                                Label(L("用 {} 打开文件", sc.appName), systemImage: "square.and.arrow.down.on.square").frame(maxWidth: .infinity)
                            }.buttonStyle(.bordered).tint(Brand.pink)
                            .disabled(store.hasValidationErrors)
                        }
                        Button { UIPasteboard.general.string = store.result.text; openRoot(sc, copied: true) } label: {
                            Label(L("复制并打开"), systemImage: "doc.on.clipboard").frame(maxWidth: .infinity)
                        }.buttonStyle(.bordered)
                        .disabled(store.hasValidationErrors)
                    }
                } else {
                    Text(L("当前为 {} 配置：请把文件传到目标设备；下面的链接可复制到目标设备上打开。", store.platform == "windows" ? "Windows" : "Android"))
                        .font(.caption2).foregroundStyle(.secondary)
                }
                if let l = link {
                    HStack(spacing: 10) {
                        actionBtn(L("复制导入链接"), icon: "link", disabled: store.hasValidationErrors) { UIPasteboard.general.string = l; toast = L("已复制导入链接") }
                        actionBtn(L("导入链接二维码"), icon: "qrcode", disabled: store.hasValidationErrors) { qrImage = QR.image(l); qrCaption = L("用目标设备扫码 / 打开：\n{}", sc.appName); showQR = qrImage != nil }
                    }
                }
                Text(sc.note).font(.caption2).foregroundStyle(.secondary)
            } else {
                Text(L("此客户端没有公开的导入 URL scheme，请使用上方导出方式。")).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private func linkURL(_ sc: ImportScheme) -> String? {
        let u = store.remoteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard u.lowercased().hasPrefix("http"), let b = sc.build else { return nil }
        return b(u, store.profileName.isEmpty ? "Lowex" : store.profileName)
    }
    private func openFile(_ sc: ImportScheme) {
        guard let u = TempFile.make(name: fileName, text: store.result.text) else { toast = L("写临时文件失败"); return }
        if !OpenInPresenter.shared.present(url: u) {
            // 没有 App 声明能打开这类文件：退回系统分享面板
            shareFile = ShareFile(url: u)
            toast = L("系统没有列出可直接打开的 App，已改用分享面板")
        }
    }
    private func openLink(_ link: String?, _ sc: ImportScheme) {
        guard let link else { openRoot(sc, copied: false); return }
        guard let url = URL(string: link) else { toast = L("链接无效"); return }
        UIApplication.shared.open(url) { ok in
            DispatchQueue.main.async { toast = ok ? L("已交给 {}", sc.appName) : L("无法打开 {}，请确认已安装", sc.appName) }
        }
    }
    private func openRoot(_ sc: ImportScheme, copied: Bool) {
        guard let url = URL(string: sc.open) else { return }
        UIApplication.shared.open(url) { ok in
            DispatchQueue.main.async {
                toast = ok ? (copied ? L("已复制配置并打开 {}，请在 App 内粘贴 / 新建配置", sc.appName) : L("已打开 {}；未填在线地址，请改用分享或复制导入", sc.appName))
                           : L("无法打开 {}，请确认已安装", sc.appName)
            }
        }
    }
    private func showConfigQR() {
        let t = store.result.text
        guard t.utf8.count <= 2400 else { toast = L("配置太大（{} 字节），无法做成二维码", t.utf8.count); return }
        qrImage = QR.image(t); qrCaption = L("配置内容二维码（{} 字节）", t.utf8.count); showQR = qrImage != nil
    }
    private func prepareShare() {
        if let u = TempFile.make(name: fileName, text: store.result.text) { shareFile = ShareFile(url: u) }
        else { toast = L("写临时文件失败") }
    }

    private var summaryBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label((store.platform == "windows" ? "Windows" : (store.platform == "android" ? "Android" : "iOS")) + " · " + (store.clientInfo?.name ?? store.client), systemImage: "app.badge")
            Label(L("配置名 {}", store.profileName), systemImage: "doc.badge.gearshape")
            Label(store.family == "shadowrocket" ? L("节点：请在 Shadowrocket 首页添加")
                  : (store.stepNodesDone ? L("已含节点 / 订阅") : L("未粘贴节点（仍可生成）")),
                  systemImage: store.stepNodesDone ? "checkmark.circle" : "info.circle")
            Label(store.stepRulesHint, systemImage: "list.bullet")
            if store.appMode { Label(L("节点：在客户端 App 内自己添加（配置不含订阅/节点）"), systemImage: "app.badge") }
            if !store.manualNodes.isEmpty && !store.appMode { Label(L("手动节点 {} 个可写入", store.manualActiveCount) + (store.manualBlockedCount > 0 ? L("，{} 个当前客户端写不出", store.manualBlockedCount) : ""), systemImage: "network") }
            if store.supports("failover"), (store.opts["failover"] as? Bool) ?? true { Label(L("故障转移（故转）已开"), systemImage: "arrow.triangle.branch") }
            if (store.opts["wifiCalling"] as? Bool) == true, store.supports("wifi") { Label(L("Wi-Fi 通话已开"), systemImage: "phone.connection") }
            if !store.blockFlags.isEmpty { Label(L("拦截：") + store.blockFlags, systemImage: "hand.raised") }
        }
        .font(.caption).foregroundStyle(.secondary)
    }

    private func actionBtn(_ title: String, icon: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: { Haptics.light(); action() }) {
            Label(title, systemImage: icon).font(.caption.weight(.semibold)).lineLimit(2).minimumScaleFactor(0.8).multilineTextAlignment(.center).frame(maxWidth: .infinity, minHeight: 36)
        }
        .buttonStyle(.bordered)
        .disabled(disabled)
    }
}


/// 用 UITextView 显示完整配置：TextKit 只排版可见区域，数万行也流畅；等宽、可选择、可滚动。
struct FullTextView: UIViewRepresentable {
    let text: String
    func makeUIView(context: Context) -> UITextView {
        let v = UITextView()
        v.isEditable = false
        v.isSelectable = true
        v.alwaysBounceVertical = true
        v.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        v.backgroundColor = UIColor.secondarySystemBackground
        v.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        v.layoutManager.allowsNonContiguousLayout = true
        return v
    }
    func updateUIView(_ v: UITextView, context: Context) {
        if v.text != text { v.text = text; v.setContentOffset(.zero, animated: false) }
    }
}
