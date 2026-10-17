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
        haptics = true; mode = .system; accentIndex = 0; cornerRadius = 20; glassIntensity = 0.6; gradientSpeed = 0.6; fontStyle = .rounded
        clearWallpaper()
    }
}

// MARK: - 设置页
struct AppearanceView: View {
    @ObservedObject private var ap = Appearance.shared
    @Environment(\.dismiss) private var dismiss
    @State private var pick: PhotosPickerItem?
    @State private var radius = Double(Appearance.shared.cornerRadius)
    @State private var glass = Appearance.shared.glassIntensity
    @State private var speed = Appearance.shared.gradientSpeed

    var body: some View {
        NavigationStack {
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
                            Toggle(L("触感反馈"), isOn: Binding(get: { ap.haptics }, set: { ap.haptics = $0; if $0 { Haptics.light() } })).tint(Brand.pink)
                            Text(L("按钮、开关、选择与生成成功时的轻微震动。")).font(.caption2).foregroundStyle(.secondary)
                        }
                        PlainCard {
                            Text(L("字体")).font(.headline)
                            Picker(L("字体"), selection: Binding(get: { ap.fontStyle }, set: { ap.fontStyle = $0 })) {
                                ForEach(Appearance.FontStyle.allCases) { Text($0.label).tag($0) }
                            }.pickerStyle(.segmented)
                        }
                        PlainCard {
                            slider(L("圆角"), value: $radius, range: 8...32, text: "\(Int(radius))") { ap.cornerRadius = CGFloat(radius) }
                            slider(L("玻璃 / 模糊强度"), value: $glass, range: 0...1, text: "\(Int(glass * 100))%") { ap.glassIntensity = glass }
                            slider(L("背景渐变速度（0 = 静止）"), value: $speed, range: 0...1.5, text: String(format: "%.1f×", speed)) { ap.gradientSpeed = speed }
                            Text(L("松手后生效。开启系统「减弱动态效果」时背景自动静止。")).font(.caption2).foregroundStyle(.secondary)
                        }
                        PlainCard {
                            Text(L("自定义壁纸")).font(.headline)
                            HStack {
                                PhotosPicker(selection: $pick, matching: .images) {
                                    Label(L("从相册选择"), systemImage: "photo.on.rectangle").frame(maxWidth: .infinity)
                                }.buttonStyle(.borderedProminent).tint(Brand.pink)
                                if ap.wallpaper != nil {
                                    Button(role: .destructive) { ap.clearWallpaper() } label: { Text(L("移除")) }.buttonStyle(.bordered)
                                }
                            }
                            Text(L("图片只保存在本机（已压缩到长边 1600px），不上传。")).font(.caption2).foregroundStyle(.secondary)
                        }
                        Button(role: .destructive) {
                            ap.resetAll()
                            radius = 20; glass = 0.6; speed = 0.6
                        } label: { Label(L("恢复默认外观"), systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity) }
                            .buttonStyle(.bordered)
                    }
                    .padding(16)
                }
            }
            .navigationTitle(L("外观与主题"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L("完成")) { dismiss() } } }
            .onChange(of: pick) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        await MainActor.run { ap.setWallpaper(data: data) }
                    }
                }
            }
        }
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, text: String, commit: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack { Text(title).font(.subheadline); Spacer(); Text(text).font(.caption).foregroundStyle(.secondary) }
            Slider(value: value, in: range) { editing in if !editing { commit() } }.tint(Brand.pink)
        }
    }
}

// MARK: - 启动动画
struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduce
    @State private var appear = false
    @State private var sweep = false
    var body: some View {
        ZStack {
            PinkBackground()
            VStack(spacing: 14) {
                ZStack {
                    Text("Lowex")
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [Brand.pink, Brand.lilac], startPoint: .leading, endPoint: .trailing))
                        .padding(.horizontal, 34).padding(.vertical, 20)
                        .glassCard(radius: 44, heavy: true)
                        .overlay {
                            if !reduce {
                                LinearGradient(colors: [.clear, .white.opacity(0.55), .clear], startPoint: .leading, endPoint: .trailing)
                                    .frame(width: 70).offset(x: sweep ? 170 : -170)
                                    .blendMode(.overlay)
                                    .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
                                    .allowsHitTesting(false)
                            }
                        }
                }
                .scaleEffect(appear ? 1 : 0.55)
                .opacity(appear ? 1 : 0)
                Text(L("本机生成 · 不上传"))
                    .font(.footnote).foregroundStyle(.secondary)
                    .opacity(appear ? 1 : 0).offset(y: appear ? 0 : 12)
            }
        }
        .onAppear {
            if reduce { withAnimation(.easeIn(duration: 0.3)) { appear = true } }
            else {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.58)) { appear = true }
                withAnimation(.easeInOut(duration: 1.0).delay(0.35)) { sweep = true }
            }
        }
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
        .onChange(of: trigger) { _, _ in fire() }
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
