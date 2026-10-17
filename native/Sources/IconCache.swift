import SwiftUI
import UIKit
import ImageIO

/// Disk + memory cache for remote rule/region icons. Falls back to SF Symbols so XS never shows a blank tile.
enum IconCache {
    private static let mem = NSCache<NSString, UIImage>()
    private static var dir: URL = {
        let u = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("lowex-icons", isDirectory: true)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }()

    /// 内置图标：Lowex-Icons 的 PNG 已打包进 App（BundledIcons/<文件名>），离线、即时显示，优先于网络与磁盘缓存。
    static let iconBase = "https://raw.githubusercontent.com/Kiwareu/Lowex-Icons/main/icons/"
    static func bundled(_ url: String?) -> UIImage? {
        guard let url, url.hasPrefix(iconBase) else { return nil }
        return bundledNamed(String(url.dropFirst(iconBase.count)))
    }
    private static func bundledNamed(_ name: String) -> UIImage? {
        let key = ("b:" + name) as NSString
        if let m = mem.object(forKey: key) { return m }
        let p = Bundle.main.bundleURL.appendingPathComponent("BundledIcons/" + name).path
        guard let img = thumb(path: p) else { return nil }
        mem.setObject(img, forKey: key)
        return img
    }
    /// 缩到 120px、预先解码、烘焙圆角：列表里不再有逐帧解码，也不用给每个图标再套一层 clipShape 遮罩。
    private static func thumb(path: String) -> UIImage? {
        guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil) else { return nil }
        let opts: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: 120,
                                     kCGImageSourceCreateThumbnailWithTransform: true, kCGImageSourceShouldCacheImmediately: true]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
        let size = CGSize(width: cg.width, height: cg.height)
        let fmt = UIGraphicsImageRendererFormat(); fmt.scale = 1; fmt.opaque = false
        return UIGraphicsImageRenderer(size: size, format: fmt).image { _ in
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: min(size.width, size.height) * 0.22).addClip()
            UIImage(cgImage: cg).draw(in: CGRect(origin: .zero, size: size))
        }
    }
    /// 启动时在后台线程把全部内置图标预解码进缓存（约 100 个，几十毫秒），之后列表滚动时只取缓存。
    static func warm() {
        DispatchQueue.global(qos: .userInitiated).async {
            let dir = Bundle.main.bundleURL.appendingPathComponent("BundledIcons")
            let names = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
            for n in names where n.hasSuffix(".png") { _ = bundledNamed(n) }
        }
    }

    /// 升级后清掉旧版本留下的图标缓存（含旧的占位图 / 失败记录）
    static func purgeIfUpgraded() {
        let k = "lowex.icons.cacheBuild"
        let cur = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") + "." + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "")
        guard UserDefaults.standard.string(forKey: k) != cur else { return }
        mem.removeAllObjects()
        try? FileManager.default.removeItem(at: dir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        URLCache.shared.removeAllCachedResponses()
        UserDefaults.standard.set(cur, forKey: k)
    }

    static func fileURL(for key: String) -> URL {
        let safe = key.data(using: .utf8)!.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
        return dir.appendingPathComponent(safe + ".img")
    }

    static func cached(_ key: String) -> UIImage? {
        if let m = mem.object(forKey: key as NSString) { return m }
        let f = fileURL(for: key)
        guard let d = try? Data(contentsOf: f), let img = UIImage(data: d) else { return nil }
        mem.setObject(img, forKey: key as NSString)
        return img
    }

    static func store(_ key: String, data: Data) -> UIImage? {
        guard let img = UIImage(data: data) else { return nil }
        mem.setObject(img, forKey: key as NSString)
        try? data.write(to: fileURL(for: key), options: .atomic)
        return img
    }

    /// Stable SF Symbol for a group/region when network icon fails.
    static func symbol(for name: String?, url: String?) -> String {
        let n = (name ?? "").lowercased()
        let u = (url ?? "").lowercased()
        if n.contains("香港") || u.contains("hong_kong") || n == "hk" { return "flag.fill" }
        if n.contains("台湾") || n.contains("台灣") || n == "tw" { return "flag.fill" }
        if n.contains("日本") || n == "jp" { return "flag.fill" }
        if n.contains("新加坡") || n == "sg" { return "flag.fill" }
        if n.contains("韩国") || n == "kr" { return "flag.fill" }
        if n.contains("美国") || n == "us" { return "flag.fill" }
        if n.contains("英国") || n == "uk" { return "flag.fill" }
        if n.contains("法国") || n == "fr" { return "flag.fill" }
        if n.contains("德国") || n == "de" { return "flag.fill" }
        if n.contains("欧洲") || n == "eu" { return "globe.europe.africa.fill" }
        if n.contains("ai") || n.contains("chatgpt") { return "brain.head.profile" }
        if n.contains("youtube") { return "play.rectangle.fill" }
        if n.contains("netflix") || n.contains("disney") || n.contains("流媒体") { return "film.fill" }
        if n.contains("spotify") { return "music.note" }
        if n.contains("telegram") { return "paperplane.fill" }
        if n.contains("twitter") || n.contains("社交") { return "bubble.left.and.bubble.right.fill" }
        if n.contains("github") { return "chevron.left.forwardslash.chevron.right" }
        if n.contains("google") { return "magnifyingglass" }
        if n.contains("apple") { return "apple.logo" }
        if n.contains("microsoft") { return "laptopcomputer" }
        if n.contains("银行") || n.contains("bank") || n.contains("paypal") || n.contains("fintech") { return "building.columns.fill" }
        if n.contains("加密") || n.contains("crypto") { return "bitcoinsign.circle.fill" }
        if n.contains("广告") || n.contains("ads") { return "nosign" }
        if n.contains("追踪") || n.contains("遥测") || n.contains("tracker") { return "eye.slash.fill" }
        if n.contains("游戏") || n.contains("steam") { return "gamecontroller.fill" }
        if n.contains("隐私") { return "lock.shield.fill" }
        return "square.grid.2x2.fill"
    }
}

struct RemoteIcon: View {
    let url: String?
    var name: String? = nil
    var size: CGFloat = 26
    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        if let b = IconCache.bundled(url) {
            // 内置图标：已缩放 + 预解码 + 圆角，直接画，没有遮罩、没有 task
            Image(uiImage: b).resizable().scaledToFit().frame(width: size, height: size)
        } else {
            remote
        }
    }

    private var remote: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFit()
            } else if failed || url == nil || (url?.isEmpty ?? true) {
                Image(systemName: IconCache.symbol(for: name, url: url))
                    .font(.system(size: size * 0.55))
                    .foregroundStyle(Brand.pink.opacity(0.85))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Brand.pink.opacity(0.12))
            } else {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.35))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .task(id: url) { await load() }
    }

    @MainActor
    private func load() async {
        guard let url, !url.isEmpty, let u = URL(string: url) else {
            failed = true; return
        }
        if IconCache.bundled(url) != nil { return }
        if let c = IconCache.cached(url) {
            image = c; return
        }
        do {
            var req = URLRequest(url: u, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 12)
            req.setValue("LowexNative/3.5", forHTTPHeaderField: "User-Agent")
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                failed = true; return
            }
            if let img = IconCache.store(url, data: data) {
                image = img
            } else {
                failed = true
            }
        } catch {
            failed = true
        }
    }
}
