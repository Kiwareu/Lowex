import SwiftUI
import PhotosUI
import UIKit

/// 外观设置：主题 / 强调色 / 圆角 / 玻璃强度 / 渐变速度 / 字体 / 壁纸。
final class Appearance: ObservableObject {
    static let shared = Appearance()
    enum Mode: String, CaseIterable, Identifiable { case system, light, dark
        var id: String { rawValue }
        var label: String { self == .system ? L("跟随系统") : (self == .light ? L("浅色") : L("深色")) } }
    enum FontStyle: String, CaseIterable, Identifiable { case rounded, standard, serif, mono
        var id: String { rawValue }
        var label: String { switch self { case .rounded: return L("圆润"); case .standard: return L("标准"); case .serif: return L("衬线"); case .mono: return L("等宽") } }
        var design: Font.Design { switch self { case .rounded: return .rounded; case .standard: return .default; case .serif: return .serif; case .mono: return .monospaced } } }

    /// 背景色系：樱粉 = 现状（主色跟随强调色）；自定义 = 用户三色
    enum BgStyle: String, CaseIterable, Identifiable {
        case sakura, aurora, ocean, twilight, lavender, honey, graphite, custom
        var id: String { rawValue }
        var label: String {
            switch self {
            case .sakura: return L("樱粉")
            case .aurora: return L("极光")
            case .ocean: return L("海洋")
            case .twilight: return L("暮光")
            case .lavender: return L("薰衣草")
            case .honey: return L("蜂蜜")
            case .graphite: return L("石墨")
            case .custom: return L("自定义")
            }
        }
    }
    /// 背景样式：网格流动 / 线性渐变 / 柔光纯色（最省电）
    enum BgKind: String, CaseIterable, Identifiable {
        case mesh, linear, solid
        var id: String { rawValue }
        var label: String { self == .mesh ? L("网格流动") : (self == .linear ? L("线性渐变") : L("柔光纯色")) }
    }

    static var swatches: [(String, Color)] = [
        (L("樱粉"), Color(red: 0.95, green: 0.28, blue: 0.56)),
        (L("紫罗兰"), Color(red: 0.56, green: 0.38, blue: 0.98)),
        (L("海蓝"), Color(red: 0.12, green: 0.50, blue: 1.0)),
        (L("薄荷"), Color(red: 0.08, green: 0.72, blue: 0.58)),
        (L("橘橙"), Color(red: 1.0, green: 0.52, blue: 0.18)),
        (L("绯红"), Color(red: 0.93, green: 0.22, blue: 0.30))
    ]

    @Published var revision = 0
    private let d = UserDefaults.standard
    var mode: Mode { didSet { d.set(mode.rawValue, forKey: "ap.mode"); bump() } }
    var accentIndex: Int { didSet { d.set(accentIndex, forKey: "ap.accent"); bump() } }
    var cornerRadius: CGFloat { didSet { d.set(Double(cornerRadius), forKey: "ap.radius"); bump() } }
    var glassIntensity: Double { didSet { d.set(glassIntensity, forKey: "ap.glass"); bump() } }
    var gradientSpeed: Double { didSet { d.set(gradientSpeed, forKey: "ap.speed"); bump() } }
    var fontStyle: FontStyle { didSet { d.set(fontStyle.rawValue, forKey: "ap.font"); bump() } }
    var haptics: Bool { didSet { d.set(haptics, forKey: "ap.haptics") } }
    /// 性能模式：静态背景 + 实心半透明卡片。未设置过时，较旧机型默认开启。
    var performanceMode: Bool { didSet { d.set(performanceMode, forKey: "ap.perf"); bump() } }
    var bgStyle: BgStyle { didSet { d.set(bgStyle.rawValue, forKey: "ap.bgstyle"); bump() } }
    var bgKind: BgKind { didSet { d.set(bgKind.rawValue, forKey: "ap.bgkind"); bump() } }
    /// 线性渐变角度（度）
    var bgAngle: Double { didSet { d.set(bgAngle, forKey: "ap.bgangle"); bump() } }
    /// 网格漂移幅度 0...1（0.5 = 现状）
    var bgDrift: Double { didSet { d.set(bgDrift, forKey: "ap.drift"); bump() } }
    /// 自定义色系三色（#RRGGBB）
    var bgHex1: String { didSet { d.set(bgHex1, forKey: "ap.bg1"); bump() } }
    var bgHex2: String { didSet { d.set(bgHex2, forKey: "ap.bg2"); bump() } }
    var bgHex3: String { didSet { d.set(bgHex3, forKey: "ap.bg3"); bump() } }
    /// 壁纸变暗程度（浅色模式基准；深色自动加深）
    var wallpaperDim: Double { didSet { d.set(wallpaperDim, forKey: "ap.wpdim"); bump() } }
    private(set) var wallpaper: UIImage?

    var accent: Color { Self.swatches[min(max(accentIndex, 0), Self.swatches.count - 1)].1 }
    var accentSoft: Color { accent.opacity(0.7) }
    var scheme: ColorScheme? { mode == .system ? nil : (mode == .light ? .light : .dark) }

    private init() {
        mode = Mode(rawValue: d.string(forKey: "ap.mode") ?? "") ?? .system
        accentIndex = d.object(forKey: "ap.accent") as? Int ?? 0
        cornerRadius = CGFloat(d.object(forKey: "ap.radius") as? Double ?? 20)
        glassIntensity = d.object(forKey: "ap.glass") as? Double ?? 0.6
        gradientSpeed = d.object(forKey: "ap.speed") as? Double ?? 0.6
        fontStyle = FontStyle(rawValue: d.string(forKey: "ap.font") ?? "") ?? .rounded
        haptics = d.object(forKey: "ap.haptics") as? Bool ?? true
        performanceMode = d.object(forKey: "ap.perf") as? Bool ?? DeviceInfo.isLowEnd
        bgStyle = BgStyle(rawValue: d.string(forKey: "ap.bgstyle") ?? "") ?? .sakura
        bgKind = BgKind(rawValue: d.string(forKey: "ap.bgkind") ?? "") ?? .mesh
        bgAngle = d.object(forKey: "ap.bgangle") as? Double ?? 45
        bgDrift = d.object(forKey: "ap.drift") as? Double ?? 0.5
        bgHex1 = d.string(forKey: "ap.bg1") ?? "#F2709C"
        bgHex2 = d.string(forKey: "ap.bg2") ?? "#9E7BFF"
        bgHex3 = d.string(forKey: "ap.bg3") ?? "#FFB08A"
        wallpaperDim = d.object(forKey: "ap.wpdim") as? Double ?? 0.12
        wallpaper = UIImage(contentsOfFile: Self.wallpaperURL.path)
    }
    private func bump() { revision += 1 }

    static var wallpaperURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("wallpaper.jpg")
    }
    func setWallpaper(data: Data) {
        guard let img = UIImage(data: data) else { return }
        let maxSide: CGFloat = 1600
        let sc = min(1, maxSide / max(img.size.width, img.size.height))
        let size = CGSize(width: img.size.width * sc, height: img.size.height * sc)
        let fmt = UIGraphicsImageRendererFormat.default(); fmt.scale = 1
        let small = UIGraphicsImageRenderer(size: size, format: fmt).image { _ in img.draw(in: CGRect(origin: .zero, size: size)) }
        try? small.jpegData(compressionQuality: 0.82)?.write(to: Self.wallpaperURL, options: .atomic)
        wallpaper = small; bump()
    }
    func clearWallpaper() {
        try? FileManager.default.removeItem(at: Self.wallpaperURL)
        wallpaper = nil; bump()
    }
    func resetAll() {
        haptics = true; performanceMode = DeviceInfo.isLowEnd; mode = .system; accentIndex = 0; cornerRadius = 20; glassIntensity = 0.6; gradientSpeed = 0.6; fontStyle = .rounded
        bgStyle = .sakura; bgKind = .mesh; bgAngle = 45; bgDrift = 0.5; bgHex1 = "#F2709C"; bgHex2 = "#9E7BFF"; bgHex3 = "#FFB08A"; wallpaperDim = 0.12
        clearWallpaper()
    }

    /// 当前色系的三色种子（主 / 辅 / 点缀）。樱粉的主色跟随强调色，与原有观感一致。
    func seeds(dark: Bool) -> (Color, Color, Color) {
        Self.seeds(style: bgStyle, dark: dark, accent: accent, hex1: bgHex1, hex2: bgHex2, hex3: bgHex3)
    }
    /// 设置页色板预览用：任意色系在浅色下的三色
    func previewSeeds(_ style: BgStyle) -> (Color, Color, Color) {
        Self.seeds(style: style, dark: false, accent: accent, hex1: bgHex1, hex2: bgHex2, hex3: bgHex3)
    }
    static func seeds(style: BgStyle, dark: Bool, accent: Color, hex1: String, hex2: String, hex3: String) -> (Color, Color, Color) {
        switch style {
        case .sakura:
            return (accent, Brand.lilac, Brand.peach)
        case .aurora:
            return dark ? (Color(red: 0.10, green: 0.45, blue: 0.35), Color(red: 0.10, green: 0.32, blue: 0.55), Color(red: 0.30, green: 0.18, blue: 0.55))
                        : (Color(red: 0.30, green: 0.85, blue: 0.65), Color(red: 0.25, green: 0.65, blue: 0.95), Color(red: 0.62, green: 0.45, blue: 1.0))
        case .ocean:
            return dark ? (Color(red: 0.05, green: 0.25, blue: 0.50), Color(red: 0.04, green: 0.38, blue: 0.45), Color(red: 0.12, green: 0.18, blue: 0.55))
                        : (Color(red: 0.15, green: 0.55, blue: 0.95), Color(red: 0.10, green: 0.80, blue: 0.85), Color(red: 0.35, green: 0.45, blue: 1.0))
        case .twilight:
            return dark ? (Color(red: 0.55, green: 0.22, blue: 0.14), Color(red: 0.45, green: 0.14, blue: 0.35), Color(red: 0.20, green: 0.12, blue: 0.45))
                        : (Color(red: 1.0, green: 0.55, blue: 0.35), Color(red: 0.85, green: 0.35, blue: 0.65), Color(red: 0.45, green: 0.30, blue: 0.85))
        case .lavender:
            return dark ? (Color(red: 0.32, green: 0.24, blue: 0.60), Color(red: 0.45, green: 0.28, blue: 0.52), Color(red: 0.20, green: 0.30, blue: 0.60))
                        : (Color(red: 0.65, green: 0.55, blue: 1.0), Color(red: 0.85, green: 0.60, blue: 0.95), Color(red: 0.45, green: 0.65, blue: 1.0))
        case .honey:
            return dark ? (Color(red: 0.60, green: 0.40, blue: 0.12), Color(red: 0.58, green: 0.28, blue: 0.14), Color(red: 0.50, green: 0.42, blue: 0.14))
                        : (Color(red: 1.0, green: 0.75, blue: 0.30), Color(red: 1.0, green: 0.55, blue: 0.35), Color(red: 0.95, green: 0.85, blue: 0.40))
        case .graphite:
            return dark ? (Color(red: 0.20, green: 0.26, blue: 0.38), Color(red: 0.24, green: 0.28, blue: 0.36), Color(red: 0.14, green: 0.20, blue: 0.32))
                        : (Color(red: 0.55, green: 0.65, blue: 0.80), Color(red: 0.65, green: 0.70, blue: 0.78), Color(red: 0.45, green: 0.55, blue: 0.70))
        case .custom:
            return (Self.color(fromHex: hex1), Self.color(fromHex: hex2), Self.color(fromHex: hex3))
        }
    }
    /// 背景不透明底色（盖住下层页面，与网格合成的基调一致）
    func baseColor(dark: Bool) -> Color {
        if bgStyle == .sakura { return dark ? Color(red: 0.082, green: 0.051, blue: 0.129) : Color(red: 1, green: 0.949, blue: 0.969) }
        let s1 = seeds(dark: dark).0
        return dark ? Self.mix(s1, .black, 0.86) : Self.mix(s1, .white, 0.90)
    }
    /// 一键主题预设：模式 + 强调色 + 背景色系一起换
    func applyPreset(_ name: String) {
        bgKind = .mesh
        switch name {
        case "aurora": mode = .dark; accentIndex = 2; bgStyle = .aurora
        case "ocean": mode = .dark; accentIndex = 2; bgStyle = .ocean
        case "honey": mode = .light; accentIndex = 4; bgStyle = .honey
        default: mode = .system; accentIndex = 0; bgStyle = .sakura
        }
    }
    // MARK: 颜色工具
    static func mix(_ a: Color, _ b: Color, _ t: Double) -> Color {
        let ua = UIColor(a), ub = UIColor(b)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        ua.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        ub.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let k = CGFloat(min(max(t, 0), 1))
        return Color(red: Double(r1 + (r2 - r1) * k), green: Double(g1 + (g2 - g1) * k), blue: Double(b1 + (b2 - b1) * k))
    }
    static func color(fromHex hex: String) -> Color {
        var h = hex.trimmingCharacters(in: .whitespaces)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let v = UInt32(h, radix: 16) else { return .pink }
        return Color(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }
    static func hex(from color: Color) -> String {
        let u = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        u.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(round(r * 255)), Int(round(g * 255)), Int(round(b * 255)))
    }
}

// MARK: - 设置页

/// 规则页列表密度：独立的小对象，改它只刷新规则页，不会像 Appearance.revision 那样重建整个界面树。
final class LayoutPrefs: ObservableObject {
    static let shared = LayoutPrefs()
    @Published var density: LayoutDensity {
        didSet { UserDefaults.standard.set(density.rawValue, forKey: "ap.density") }
    }
    private init() {
        density = LayoutDensity(rawValue: UserDefaults.standard.string(forKey: "ap.density") ?? "") ?? .compact
    }
}

/// 规则页列表的显示密度
enum LayoutDensity: String, CaseIterable, Identifiable {
    case single = "single"
    case dual = "dual"
    case compact = "compact"
    case category = "category"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .single: return L("单列平铺")
        case .dual: return L("双列")
        case .compact: return L("紧凑")
        case .category: return L("按分类")
        }
    }
}

struct AppearanceView: View {
    @ObservedObject private var ap = Appearance.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showPicker = false
    @State private var radius = Double(Appearance.shared.cornerRadius)
    @State private var glass = Appearance.shared.glassIntensity
    @State private var speed = Appearance.shared.gradientSpeed
    @State private var drift = Appearance.shared.bgDrift
    @State private var angle = Appearance.shared.bgAngle
    @State private var wpdim = Appearance.shared.wallpaperDim

    var body: some View {
        NavStack {
            ZStack {
                PinkBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        PlainCard {
                            Text(L("主题")).font(.headline)
                            Picker(L("主题"), selection: Binding(get: { ap.mode }, set: { ap.mode = $0 })) {
                                ForEach(Appearance.Mode.allCases) { Text($0.label).tag($0) }
                            }.pickerStyle(.segmented)
                        }
                        PlainCard {
                            Text(L("强调色")).font(.headline)
                            HStack(spacing: 12) {
                                ForEach(0..<Appearance.swatches.count, id: \.self) { i in
                                    Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { ap.accentIndex = i } } label: {
                                        Circle().fill(Appearance.swatches[i].1).frame(width: 34, height: 34)
                                            .overlay { if ap.accentIndex == i { Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.white) } }
                                    }.buttonStyle(PressableStyle())
                                }
                            }
                        }
                        PlainCard {
                            Text(L("主题预设")).font(.headline)
                            Text(L("一键搭配：主题模式 + 强调色 + 背景色系。之后还能在下面单独微调。")).font(.caption2).foregroundStyle(.secondary)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                presetChip("sakura", L("樱花物语"))
                                presetChip("aurora", L("极光之夜"))
                                presetChip("ocean", L("深海静谧"))
                                presetChip("honey", L("柑橘晨光"))
                            }
                        }
                        PlainCard {
                            Text(L("背景")).font(.headline)
                            Text(L("背景色系")).font(.subheadline)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Appearance.BgStyle.allCases) { st in
                                        let ps = ap.previewSeeds(st)
                                        Button { ap.bgStyle = st } label: {
                                            VStack(spacing: 4) {
                                                Circle().fill(LinearGradient(colors: [ps.0, ps.1, ps.2], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                    .frame(width: 36, height: 36)
                                                    .overlay { if ap.bgStyle == st { Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.white) } }
                                                    .overlay { Circle().strokeBorder(ap.bgStyle == st ? Brand.pink : Color.clear, lineWidth: 2).padding(-3) }
                                                Text(st.label).font(.caption2).foregroundStyle(Brand.ink)
                                            }
                                        }.buttonStyle(PressableStyle())
                                    }
                                }.padding(.vertical, 2)
                            }
                            if ap.bgStyle == .custom {
                                ColorPicker(L("主色"), selection: colorBinding(\.bgHex1), supportsOpacity: false)
                                ColorPicker(L("辅色"), selection: colorBinding(\.bgHex2), supportsOpacity: false)
                                ColorPicker(L("点缀色"), selection: colorBinding(\.bgHex3), supportsOpacity: false)
                            }
                            Text(L("背景样式")).font(.subheadline).padding(.top, 4)
                            ChoiceTabs(options: Appearance.BgKind.allCases.map { ($0, $0.label) },
                                       selection: Binding(get: { ap.bgKind }, set: { ap.bgKind = $0 }))
                            if ap.bgKind == .linear {
                                slider(L("渐变角度"), value: $angle, range: 0...360, text: "\(Int(angle))°") { ap.bgAngle = angle }
                            }
                            Text(ap.wallpaper != nil ? L("当前设了壁纸，背景设置在移除壁纸后生效。") : L("柔光纯色最省电；网格流动是原来的动态效果。")).font(.caption2).foregroundStyle(.secondary)
                        }
                        PlainCard {
                            Toggle(L("触感反馈"), isOn: Binding(get: { ap.haptics }, set: { ap.haptics = $0; if $0 { Haptics.light() } }))
                            Text(L("按钮、开关、选择与生成成功时的轻微震动。")).font(.caption2).foregroundStyle(.secondary)
                        }
                        PlainCard {
                            Toggle(L("性能模式"), isOn: Binding(get: { ap.performanceMode }, set: { ap.performanceMode = $0 }))
                            Text(L("关闭背景动画，并用更轻量的玻璃质感卡片，滚动更流畅，外观几乎不变。iPhone XS 等较旧机型默认开启。")).font(.caption2).foregroundStyle(.secondary)
                        }
                        PlainCard {
                            Text(L("字体")).font(.headline)
                            ChoiceTabs(options: Appearance.FontStyle.allCases.map { ($0, $0.label) },
                                       selection: Binding(get: { ap.fontStyle }, set: { ap.fontStyle = $0 }))
                        }
                        PlainCard {
                            slider(L("圆角"), value: $radius, range: 8...32, text: "\(Int(radius))") { ap.cornerRadius = CGFloat(radius) }
                            slider(L("玻璃 / 模糊强度"), value: $glass, range: 0...1, text: "\(Int(glass * 100))%") { ap.glassIntensity = glass }
                            slider(L("背景渐变速度（0 = 静止）"), value: $speed, range: 0...1.5, text: String(format: "%.1f×", speed)) { ap.gradientSpeed = speed }
                            slider(L("背景漂移幅度"), value: $drift, range: 0...1, text: "\(Int(drift * 100))%") { ap.bgDrift = drift }
                            Text(L("松手后生效。开启系统「减弱动态效果」时背景自动静止。")).font(.caption2).foregroundStyle(.secondary)
                        }
                        PlainCard {
                            Text(L("自定义壁纸")).font(.headline)
                            HStack {
                                Button { showPicker = true } label: {
                                    Label(L("从相册选择"), systemImage: "photo.on.rectangle").frame(maxWidth: .infinity)
                                }.buttonStyle(.borderedProminent).tint(Brand.pink)
                                if ap.wallpaper != nil {
                                    Button(role: .destructive) { ap.clearWallpaper() } label: { Text(L("移除")) }.buttonStyle(.bordered)
                                }
                            }
                            if ap.wallpaper != nil {
                                slider(L("壁纸变暗"), value: $wpdim, range: 0...0.6, text: "\(Int(wpdim * 100))%") { ap.wallpaperDim = wpdim }
                            }
                            Text(L("图片只保存在本机（已压缩到长边 1600px），不上传。")).font(.caption2).foregroundStyle(.secondary)
                        }
                        Button(role: .destructive) {
                            ap.resetAll()
                            radius = 20; glass = 0.6; speed = 0.6; drift = 0.5; angle = 45; wpdim = 0.12
                        } label: { Label(L("恢复默认外观"), systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity) }
                            .buttonStyle(.bordered)
                    }
                    .padding(16)
                }
            }
            .navigationTitle(L("自定义外观与主题"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L("完成")) { dismiss() } } }
            .sheet(isPresented: $showPicker) {
                ImagePicker { data in ap.setWallpaper(data: data) }
            }
        }
    }

    private func presetChip(_ key: String, _ label: String) -> some View {
        let style: Appearance.BgStyle = key == "aurora" ? .aurora : (key == "ocean" ? .ocean : (key == "honey" ? .honey : .sakura))
        let ps = ap.previewSeeds(style)
        return Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { ap.applyPreset(key) } } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LinearGradient(colors: [ps.0, ps.1, ps.2], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 40)
                Text(label).font(.caption.weight(.medium)).foregroundStyle(Brand.ink)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.secondary.opacity(0.08)))
        }.buttonStyle(PressableStyle())
    }

    private func colorBinding(_ kp: ReferenceWritableKeyPath<Appearance, String>) -> Binding<Color> {
        Binding(get: { Appearance.color(fromHex: ap[keyPath: kp]) }, set: { ap[keyPath: kp] = Appearance.hex(from: $0) })
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, text: String, commit: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack { Text(title).font(.subheadline); Spacer(); Text(text).font(.caption).foregroundStyle(.secondary) }
            Slider(value: value, in: range) { editing in if !editing { commit() } }.tint(Brand.pink)
        }
    }
}

// MARK: - 启动动画
/// 加载式启动序列（单一时间线）：
/// 字标淡入 → 进度立即从左到右填充（一条 timingCurve 缓动，约 0.65s，只有一个动画值 progress）
/// → 到 100% 后停顿 0.1s → 交给 Boot 用 0.2s 淡出进入首页（总长约 1 秒）。
/// 填充用 scaleEffect(x:) + mask 的矩形，只做变换，不逐帧重绘文字；引擎在后台线程加载（见 Boot），不会卡住动画。
/// 减弱动态效果：只做短淡入、短停顿、0.2s 淡出。
struct SplashView: View {
    @ObservedObject var boot: Boot
    @Environment(\.accessibilityReduceMotion) private var reduce
    @State private var appeared = false
    @State private var progress: CGFloat = 0
    private let fillDuration = 0.65

    private var fillGradient: LinearGradient {
        LinearGradient(colors: [Brand.pink, Brand.lilac], startPoint: .leading, endPoint: .trailing)
    }

    var body: some View {
        ZStack {
            PinkBackground()          // 自带不透明底色，盖住下层首页
            VStack(spacing: Space.xl) {
                Image("BrandMark")
                    .resizable().scaledToFit()
                    .frame(width: 84, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
                    .shadow(color: Brand.pink.opacity(0.35), radius: 16, y: 7)
                    .scaleEffect(appeared ? 1 : 0.8)
                ZStack {
                    wordmark.foregroundStyle(Brand.ink.opacity(0.12))
                    wordmark.foregroundStyle(fillGradient)
                        .mask(alignment: .leading) {
                            Rectangle().scaleEffect(x: max(progress, 0.001), y: 1, anchor: .leading)
                        }
                }
                pill
                Text(L("本机生成 · 不上传"))
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .compositingGroup()
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
        }
        .ignoresSafeArea()
        .task { await run() }
    }

    /// 胶囊进度条：玻璃质感轨道 + 渐变填充 + 内部高光；填充与扫光都由同一个 progress 驱动（只做变换 / 位移）
    private var pill: some View {
        let w: CGFloat = 220, h: CGFloat = 22
        return ZStack(alignment: .leading) {
            Capsule().fill(.ultraThinMaterial)
            Capsule().fill(Color.white.opacity(0.18))
            Capsule().fill(fillGradient)
                .padding(3)
                .scaleEffect(x: max(progress, 0.001), y: 1, anchor: .leading)
                .shadow(color: Brand.pink.opacity(0.45), radius: 8)
            // 扫光：宽 60 的高光沿填充区域移动，用同一个 progress 定位，并被填充区域裁剪
            LinearGradient(colors: [.clear, .white.opacity(0.65), .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: 60, height: h - 6)
                .offset(x: progress * (w - 60) - 0)
                .blendMode(.plusLighter)
                .mask(alignment: .leading) {
                    Capsule().padding(3).scaleEffect(x: max(progress, 0.001), y: 1, anchor: .leading)
                }
            // 内部上半部的玻璃高光
            Capsule().fill(LinearGradient(colors: [.white.opacity(0.45), .white.opacity(0)], startPoint: .top, endPoint: .bottom))
                .padding(.horizontal, 6).padding(.top, 2).frame(height: h / 2)
        }
        .frame(width: w, height: h)
        .overlay(Capsule().strokeBorder(LinearGradient(colors: [.white.opacity(0.75), .white.opacity(0.15)], startPoint: .top, endPoint: .bottom), lineWidth: 1))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }

    private var wordmark: some View {
        WordmarkShape().frame(height: 96)
    }

    private func run() async {
        if reduce {
            withAnimation(.easeIn(duration: 0.15)) { appeared = true; progress = 1 }
            try? await Task.sleep(nanoseconds: 350_000_000)
            while boot.store == nil { try? await Task.sleep(nanoseconds: 30_000_000) }
            boot.finish(duration: 0.2)
            return
        }
        withAnimation(.easeOut(duration: 0.25)) { appeared = true }
        withAnimation(.timingCurve(0.35, 0.0, 0.2, 1.0, duration: fillDuration)) { progress = 1 }
        try? await Task.sleep(nanoseconds: UInt64(fillDuration * 1_000_000_000))
        while boot.store == nil { try? await Task.sleep(nanoseconds: 30_000_000) }
        try? await Task.sleep(nanoseconds: 100_000_000)
        boot.finish(duration: 0.2)
    }
}

// MARK: - 烟花 + 彩纸（轻量 Canvas，约 2.8 秒，减弱动态时不播放）
struct ConfettiView: View {
    let trigger: Int
    @Environment(\.accessibilityReduceMotion) private var reduce
    private struct P { var ox: Double; var oy: Double; var vx: Double; var vy: Double; var g: Double
        var size: Double; var delay: Double; var life: Double; var rot: Double; var rs: Double; var spark: Bool; var c: Int }
    @State private var parts: [P] = []
    @State private var start = Date.distantPast
    @State private var active = false
    private let palette: [Color] = [
        Color(red: 0.95, green: 0.28, blue: 0.56), Color(red: 1, green: 0.69, blue: 0.54), Color(red: 0.62, green: 0.50, blue: 1),
        Color(red: 1, green: 0.85, blue: 0.35), Color(red: 0.35, green: 0.85, blue: 0.9), .white]

    var body: some View {
        ZStack {
            if active {
                TimelineView(.animation) { ctx in
                    Canvas { gc, size in
                        let t = ctx.date.timeIntervalSince(start)
                        for p in parts {
                            let lt = t - p.delay
                            if lt < 0 || lt > p.life { continue }
                            let x = p.ox * size.width + p.vx * lt
                            let y = p.oy * size.height + p.vy * lt + 0.5 * p.g * lt * lt
                            var c = gc
                            c.opacity = max(0, 1 - lt / p.life)
                            if p.spark {
                                c.fill(Path(ellipseIn: CGRect(x: x - p.size / 2, y: y - p.size / 2, width: p.size, height: p.size)), with: .color(palette[p.c % palette.count]))
                            } else {
                                c.translateBy(x: x, y: y)
                                c.rotate(by: .radians(p.rot + p.rs * lt))
                                c.fill(Path(CGRect(x: -p.size / 2, y: -p.size / 4, width: p.size, height: p.size / 2)), with: .color(palette[p.c % palette.count]))
                            }
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onChangeValue(of: trigger) { _ in fire() }
    }

    private func fire() {
        guard !reduce else { return }
        var ps: [P] = []
        let bursts: [(Double, Double, Double)] = [(0.3, 0.32, 0), (0.72, 0.26, 0.3), (0.5, 0.42, 0.6)]
        for (bx, by, dl) in bursts {
            for i in 0..<34 {
                let a = Double(i) / 34 * 2 * Double.pi + Double.random(in: -0.1...0.1)
                let sp = Double.random(in: 110...250)
                ps.append(P(ox: bx, oy: by, vx: cos(a) * sp, vy: sin(a) * sp, g: 200, size: Double.random(in: 3...5.5),
                            delay: dl, life: Double.random(in: 1.1...1.7), rot: 0, rs: 0, spark: true, c: Int.random(in: 0..<6)))
            }
        }
        for _ in 0..<46 {
            ps.append(P(ox: Double.random(in: 0.02...0.98), oy: -0.03, vx: Double.random(in: -40...40), vy: Double.random(in: 60...160), g: 260,
                        size: Double.random(in: 7...12), delay: Double.random(in: 0...0.9), life: Double.random(in: 1.8...2.6),
                        rot: Double.random(in: 0...6), rs: Double.random(in: -8...8), spark: false, c: Int.random(in: 0..<6)))
        }
        parts = ps; start = Date(); active = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { active = false }
    }
}
