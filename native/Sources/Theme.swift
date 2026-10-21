import SwiftUI

enum Brand {
    static func dyn(_ light: UIColor, _ dark: UIColor) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
    static var pink: Color { Appearance.shared.accent }
    static var pinkSoft: Color { Appearance.shared.accentSoft }
    static let lilac = Color(red: 0.62, green: 0.50, blue: 1.0)
    static let peach = Color(red: 1.0, green: 0.69, blue: 0.54)
    static var ink: Color { dyn(UIColor(red: 0.18, green: 0.10, blue: 0.22, alpha: 1), UIColor(white: 0.96, alpha: 1)) }
    static var radius: CGFloat { Appearance.shared.cornerRadius }
    static var glass: Double { Appearance.shared.glassIntensity }
}

/// 8pt 网格：全 App 统一的间距
enum Space {
    static let xs: CGFloat = 4, s: CGFloat = 8, m: CGFloat = 12, l: CGFloat = 16, xl: CGFloat = 24, xxl: CGFloat = 32
    /// 最小可点区域（HIG 44pt）
    static let tap: CGFloat = 44
}

/// 背景：自定义壁纸 > 柔和流动的网格渐变（Gemini 风格；可调速，减弱动态效果时静止）。
struct PinkBackground: View {
    @Environment(\.colorScheme) private var cs
    @Environment(\.accessibilityReduceMotion) private var reduce
    @Environment(\.pageTab) private var pageTab
    @ObservedObject private var active = ActiveTab.shared
    var body: some View {
        // 只有可见的标签页才允许背景动画；性能模式下背景始终静止
        let visible = pageTab == nil || active.tab == pageTab
        let still = reduce || Appearance.shared.performanceMode || !visible
        ZStack {
            // 不透明底色（与 LaunchBackground 同色）：网格渐变的色块带透明度，没有底色时会透出下层页面
            Appearance.shared.baseColor(dark: cs == .dark)
            if let img = Appearance.shared.wallpaper {
                Color.clear.overlay { Image(uiImage: img).resizable().scaledToFill() }.clipped()
                Color.black.opacity(cs == .dark ? min(0.8, Appearance.shared.wallpaperDim * 3.75) : Appearance.shared.wallpaperDim)
            } else {
                switch Appearance.shared.bgKind {
                case .mesh: MeshBackdrop(dark: cs == .dark, speed: Appearance.shared.gradientSpeed, paused: still)
                case .linear: LinearBackdrop(dark: cs == .dark, speed: Appearance.shared.gradientSpeed, paused: still)
                case .solid: SolidBackdrop(dark: cs == .dark)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

/// 滚动状态：滚动期间暂停背景网格渐变的逐帧更新，把 GPU / 主线程让给列表。
final class ScrollActivity: ObservableObject {
    static let shared = ScrollActivity()
    @Published private(set) var active = false
    private var last: CFTimeInterval = 0
    private var timer: Timer?
    /// contentOffset 每帧都会调用：这里只记一个时间戳，不再每帧创建 / 取消定时任务。
    func ping() {
        last = CACurrentMediaTime()
        guard !active else { return }
        active = true
        let t = Timer(timeInterval: 0.1, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            if CACurrentMediaTime() - self.last > 0.25 { self.active = false; t.invalidate(); self.timer = nil }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }
}

/// 放在 ScrollView 内容背景里，找到外层 UIScrollView 并监听 contentOffset。
struct ScrollWatcher: UIViewRepresentable {
    final class Probe: UIView {
        private var obs: NSKeyValueObservation?
        override func didMoveToWindow() {
            super.didMoveToWindow()
            obs = nil
            guard window != nil else { return }
            DispatchQueue.main.async { [weak self] in
                var v: UIView? = self?.superview
                while let c = v, !(c is UIScrollView) { v = c.superview }
                guard let sv = v as? UIScrollView else { return }
                self?.obs = sv.observe(\.contentOffset, options: [.new]) { _, _ in ScrollActivity.shared.ping() }
            }
        }
    }
    func makeUIView(context: Context) -> Probe { let p = Probe(); p.isUserInteractionEnabled = false; return p }
    func updateUIView(_ uiView: Probe, context: Context) {}
}

/// 3×3 网格渐变（iOS 18+ 用 MeshGradient，GPU 渲染；更早的系统回退为漂移的径向渐变）。只有内部 5 个控制点做缓慢的李萨如漂移，约 20fps；
/// 角点固定，所以边缘不会露底。
struct MeshBackdrop: View {
    let dark: Bool; let speed: Double; let paused: Bool
    @ObservedObject private var scroll = ScrollActivity.shared
    private var colors: [Color] {
        let ap = Appearance.shared
        if ap.bgStyle != .sakura {
            let (s1, s2, s3) = ap.seeds(dark: dark)
            if dark {
                return [Appearance.mix(s1, .black, 0.72), s2.opacity(0.35), Appearance.mix(s3, .black, 0.78),
                        s1.opacity(0.38), Appearance.mix(s1, .black, 0.62), s2.opacity(0.30),
                        Appearance.mix(s2, .black, 0.70), s3.opacity(0.22), s1.opacity(0.28)]
            }
            return [Appearance.mix(s1, .white, 0.90), s2.opacity(0.42), Appearance.mix(s2, .white, 0.86),
                    s1.opacity(0.50), Appearance.mix(s1, .white, 0.78), s2.opacity(0.36),
                    s3.opacity(0.40), Appearance.mix(s3, .white, 0.88), s1.opacity(0.38)]
        }
        let a = Brand.pinkSoft, l = Brand.lilac, p = Brand.peach
        if dark {
            return [Color(red: 0.10, green: 0.05, blue: 0.15), l.opacity(0.35), Color(red: 0.08, green: 0.07, blue: 0.19),
                    a.opacity(0.38), Color(red: 0.16, green: 0.07, blue: 0.17), l.opacity(0.30),
                    Color(red: 0.12, green: 0.06, blue: 0.13), p.opacity(0.22), a.opacity(0.28)]
        }
        return [Color(red: 1.0, green: 0.93, blue: 0.97), l.opacity(0.42), Color(red: 0.95, green: 0.93, blue: 1.0),
                a.opacity(0.50), Color(red: 1.0, green: 0.88, blue: 0.94), l.opacity(0.36),
                p.opacity(0.40), Color(red: 1.0, green: 0.93, blue: 0.95), a.opacity(0.38)]
    }
    private func points(_ t: Float) -> [SIMD2<Float>] {
        let amp = Float(0.25 + 1.5 * Appearance.shared.bgDrift)
        let k: Float = 0.11 * amp
        return [
            SIMD2<Float>(0, 0), SIMD2<Float>(0.5 + k * sin(t), 0), SIMD2<Float>(1, 0),
            SIMD2<Float>(0, 0.5 + k * cos(t * 0.8)), SIMD2<Float>(0.5 + 0.2 * amp * sin(t * 0.6 + 1), 0.5 + 0.2 * amp * cos(t * 0.5)), SIMD2<Float>(1, 0.5 + k * sin(t * 0.7 + 2)),
            SIMD2<Float>(0, 1), SIMD2<Float>(0.5 + k * cos(t * 0.9 + 0.5), 1), SIMD2<Float>(1, 1)]
    }
    var body: some View {
        let base = Appearance.shared.baseColor(dark: dark)
        // 空闲时 10fps 足够（原来 15fps）；滚动中本来就暂停；性能模式下背景直接静止
        TimelineView(.animation(minimumInterval: 1.0 / 10.0, paused: paused || scroll.active || speed <= 0.01 || Appearance.shared.performanceMode)) { ctx in
            let t = Float(ctx.date.timeIntervalSinceReferenceDate * speed * 0.22)
            if #available(iOS 18.0, *) {
                MeshGradient(width: 3, height: 3, points: points(t), colors: colors, background: base, smoothsColors: true)
            } else {
                legacy(Double(t), base)
            }
        }
    }

    /// iOS 18 之前没有 MeshGradient：用四团缓慢漂移的径向渐变叠出相近的效果。
    private func legacy(_ t: Double, _ base: Color) -> some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height, m = max(w, h)
            ZStack {
                base
                blob(colors[1], r: m * 0.75).position(x: w * (0.85 + 0.06 * sin(t)), y: h * (0.10 + 0.05 * cos(t * 0.8)))
                blob(colors[3], r: m * 0.80).position(x: w * (0.10 + 0.06 * cos(t * 0.7)), y: h * (0.45 + 0.06 * sin(t * 0.6 + 1)))
                blob(colors[6], r: m * 0.80).position(x: w * (0.15 + 0.05 * sin(t * 0.9)), y: h * 0.98)
                blob(colors[8], r: m * 0.70).position(x: w * (0.90 + 0.05 * cos(t * 0.5)), y: h * (0.85 + 0.04 * sin(t)))
            }
        }
    }
    private func blob(_ c: Color, r: CGFloat) -> some View {
        RadialGradient(colors: [c, c.opacity(0)], center: .center, startRadius: 0, endRadius: r / 2)
            .frame(width: r, height: r)
    }
}

/// 线性渐变背景：角度可调；速度 > 0 时角度缓慢呼吸漂移。暂停逻辑与网格一致（滚动 / 性能模式 / 不可见页签）。
struct LinearBackdrop: View {
    let dark: Bool; let speed: Double; let paused: Bool
    @ObservedObject private var scroll = ScrollActivity.shared
    var body: some View {
        let ap = Appearance.shared
        let (s1, s2, s3) = ap.seeds(dark: dark)
        let cols: [Color] = [Appearance.mix(s1, .white, dark ? 0.10 : 0.82), s1.opacity(dark ? 0.50 : 0.55),
                             s2.opacity(dark ? 0.42 : 0.50), Appearance.mix(s3, .white, dark ? 0.05 : 0.85)]
        TimelineView(.animation(minimumInterval: 1.0 / 10.0, paused: paused || scroll.active || speed <= 0.01 || Appearance.shared.performanceMode)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate * speed * 0.05
            let ang = (ap.bgAngle + (speed > 0.01 ? sin(t) * 14 : 0)) * Double.pi / 180
            let sx = 0.5 - 0.5 * cos(ang), sy = 0.5 - 0.5 * sin(ang)
            LinearGradient(colors: cols, startPoint: UnitPoint(x: sx, y: sy), endPoint: UnitPoint(x: 1 - sx, y: 1 - sy))
        }
    }
}

/// 柔光纯色背景：底色 + 一团静态柔光，最省电。
struct SolidBackdrop: View {
    let dark: Bool
    var body: some View {
        let ap = Appearance.shared
        let s2 = ap.seeds(dark: dark).1
        ZStack {
            ap.baseColor(dark: dark)
            RadialGradient(colors: [s2.opacity(dark ? 0.30 : 0.40), s2.opacity(0)], center: .topTrailing, startRadius: 0, endRadius: 420)
        }
    }
}

/// Glass only for a few hero cards — not every list row (keeps XS smooth).
struct GlassCard: ViewModifier {
    var radius: CGFloat? = nil
    var heavy: Bool = false
    private var r: CGFloat { radius ?? (Brand.radius + 4) }
    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *), heavy, !Appearance.shared.performanceMode {
            content.glassEffect(.regular, in: .rect(cornerRadius: r))
        } else {
            fallback(content)
        }
        #else
        fallback(content)
        #endif
    }
    private func fallback(_ content: Content) -> some View {
        content
            .background { GlassSurface(r: r) }
    }
}

/// 玻璃底层：渐变高光 + 斜向描边，纯半透明叠层（不做实时模糊），所以可以给每一行 / 每张卡片用，滚动时只是合成，不重算。
struct GlassFill: View {
    let r: CGFloat
    var tint: Color? = nil
    var boost: Double = 1
    @Environment(\.colorScheme) private var cs
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: r, style: .continuous)
        let k = 0.65 + 0.7 * Brand.glass
        let dark = cs == .dark
        shape
            .fill(LinearGradient(colors: dark ? [Color.white.opacity(0.17 * k * boost), Color.white.opacity(0.05 * k * boost)]
                                              : [Color.white.opacity(0.62 * k * boost), Color.white.opacity(0.24 * k * boost)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay { if let tint { shape.fill(tint.opacity(dark ? 0.20 : 0.14)) } }
            .overlay(shape.strokeBorder(
                tint != nil ? AnyShapeStyle(tint!.opacity(0.6))
                            : AnyShapeStyle(LinearGradient(colors: [Color.white.opacity(dark ? 0.38 : 0.95), Color.white.opacity(0.08), Color.white.opacity(dark ? 0.14 : 0.45)],
                                                           startPoint: .topLeading, endPoint: .bottomTrailing)),
                lineWidth: tint != nil ? 1.2 : 0.8))
    }
}

/// 大卡片（首页 / 各页头部卡片，每页一两张）：一层真实材质模糊 + 玻璃叠层；性能模式下去掉实时模糊，改用更厚的叠层，外观接近。
private struct GlassSurface: View {
    let r: CGFloat
    var body: some View {
        ZStack {
            if !Appearance.shared.performanceMode {
                RoundedRectangle(cornerRadius: r, style: .continuous).fill(.ultraThinMaterial)
            }
            GlassFill(r: r, boost: Appearance.shared.performanceMode ? 1.15 : 0.8)
        }
    }
}

extension View {
    func glassCard(radius: CGFloat? = nil, heavy: Bool = false) -> some View {
        modifier(GlassCard(radius: radius, heavy: heavy))
    }
}

/// 弹窗专用玻璃：对齐图一系统菜单质感——通透、水润、磨砂。
/// iOS 26 用真实 liquid glass + 顶部高光 + 镜面亮边；低版本用 regularMaterial 强模糊 + 高光叠层，保证背景不穿帮。
/// 注意：弹窗背后的遮罩必须淡（各弹窗用 0.12），遮罩太黑会把玻璃折射的背景压灰，玻璃再亮也水润不起来。
struct PopupGlass: ViewModifier {
    var radius: CGFloat = 20
    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *), !Appearance.shared.performanceMode {
            content
                // clear 是最透明的一档：本身不带灰白底色，后面的颜色能透进来，不再发灰
                .glassEffect(.clear, in: .rect(cornerRadius: radius))
                // 水润高光：只压顶部一段，亮而不糊字
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(LinearGradient(colors: [.white.opacity(0.45), .white.opacity(0.12), .clear],
                                               startPoint: .top, endPoint: .bottom))
                        .frame(height: 100)
                }
                // 镜面亮边：上亮下暗
                .overlay {
                    RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.3), .white.opacity(0.08), .white.opacity(0.4)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.0
                    )
                }
                .shadow(color: .black.opacity(0.16), radius: 26, y: 10)
        } else {
            fallback(content)
        }
        #else
        fallback(content)
        #endif
    }
    /// iOS 26 文件夹式水润玻璃：透一点的强模糊（背景色彩进来）+ 顶部高光 + 镜面亮边
    private func fallback(_ content: Content) -> some View {
        content.background {
            ZStack {
                RoundedRectangle(cornerRadius: radius, style: .continuous).fill(.ultraThinMaterial)
                // 顶部高光：水润感
                RoundedRectangle(cornerRadius: radius, style: .continuous).fill(
                    LinearGradient(colors: [.white.opacity(0.34), .white.opacity(0.07), .clear],
                                   startPoint: .top, endPoint: .bottom)
                )
                // 镜面描边：上亮下暗，文件夹式亮边
                RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.28), .white.opacity(0.08), .white.opacity(0.38)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1.2
                )
            }
            .shadow(color: .black.opacity(0.16), radius: 26, y: 10)
        }
    }
}
extension View {
    func popupGlass(radius: CGFloat = 20) -> some View { modifier(PopupGlass(radius: radius)) }
}

/// 普通卡片 / 行：纯叠层玻璃（GlassFill），没有实时模糊。
struct SoftCard: ViewModifier {
    var radius: CGFloat? = nil
    func body(content: Content) -> some View {
        content.background(GlassFill(r: radius ?? max(8, Brand.radius * 0.8)))
    }
}
extension View {
    func softCard(radius: CGFloat? = nil) -> some View { modifier(SoftCard(radius: radius)) }
}

/// 全局液态玻璃确认弹窗：替代 confirmationDialog。每个 action 一行大按钮；destructive 显示红色。
struct GlassConfirmAction: Identifiable {
    let id = UUID()
    let title: String
    let destructive: Bool
    let action: () -> Void
}

struct GlassConfirm: View {
    let title: String
    let message: String
    let actions: [GlassConfirmAction]
    var dismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.12).ignoresSafeArea()
                .onTapGesture { dismiss() }
            VStack(spacing: 0) {
                Text(title).font(.headline).foregroundStyle(Brand.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18).padding(.top, 16)
                if !message.isEmpty {
                    Text(message).font(.footnote).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 18).padding(.top, 6)
                }
                VStack(spacing: 6) {
                    ForEach(actions) { a in
                        Button { Haptics.light(); a.action(); dismiss() } label: {
                            Text(a.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(a.destructive ? Color.red : Brand.pink)
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(a.destructive ? Color.red.opacity(0.10) : Color.secondary.opacity(0.10)))
                        }
                        .buttonStyle(.plain)
                    }
                    Button { dismiss() } label: {
                        Text(L("取消"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Brand.ink)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.secondary.opacity(0.14)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .frame(maxWidth: 300)
            .popupGlass()
            .padding(.horizontal, 24)
        }
    }
}

/// 按下回弹（spring）
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.62), value: configuration.isPressed)
            .onChangeValue(of: configuration.isPressed) { p in if p { Haptics.light() } }
    }
}

/// 展开 / 收起箭头：圆底 + 品牌色，比单独的灰色 chevron 更容易看见
struct ChevronBadge: View {
    let open: Bool
    var body: some View {
        Image(systemName: "chevron.down")
            .font(.footnote.weight(.bold))
            .foregroundStyle(Brand.pink)
            .rotationEffect(.degrees(open ? 180 : 0))
            .frame(width: 32, height: 32)
            .background(Brand.pink.opacity(0.14), in: Circle())
    }
}

/// 整行可点的展开头：≥44pt 高、整行 contentShape、spring + 触感。所有「展开 / 收起」统一用它。
struct ExpandHeader<Label: View>: View {
    @Binding var open: Bool
    @ViewBuilder var label: Label
    var body: some View {
        Button {
            Haptics.light()
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) { open.toggle() }
        } label: {
            HStack(spacing: Space.m) {
                label
                Spacer(minLength: Space.s)
                ChevronBadge(open: open)
            }
            .frame(maxWidth: .infinity, minHeight: Space.tap, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(open ? "expanded" : "collapsed")
    }
}

/// 图标按钮：最小 44×44 的点击区域
struct IconTapStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: Space.tap, minHeight: Space.tap)
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// 统一的分区标题：标题 + 可选说明
struct SectionHeader: View {
    let title: String; var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(title).font(.headline).foregroundStyle(Brand.ink)
            if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
        }
    }
}

/// 手写签名风格字标：直接用矢量素材 WordmarkScript（Great Vibes 的 "Lowex" 轮廓，SIL OFL 1.1，生成脚本见 tools/brand/make_wordmark.py）。
/// 不依赖运行时字体注册，也不会被「字体风格」之类的全局设置改成无衬线。
struct WordmarkShape: View {
    static let aspect: CGFloat = 2.008
    var body: some View {
        Image("WordmarkScript")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(Self.aspect, contentMode: .fit)
    }
}
struct ScriptWordmark: View {
    var body: some View {
        LinearGradient(colors: [Brand.pink, Brand.lilac, Color(red: 1.0, green: 0.52, blue: 0.46)], startPoint: .leading, endPoint: .trailing)
            .mask(WordmarkShape())
            .aspectRatio(WordmarkShape.aspect, contentMode: .fit)
            .shadow(color: Brand.pink.opacity(0.22), radius: 8, y: 3)
            .accessibilityElement()
            .accessibilityLabel("Lowex")
    }
}

struct BrandHeader: View {
    private static let logoSize: CGFloat = 50

    var body: some View {
        // 字标区宽度 = 屏幕宽 - 两侧页边距 - Logo；高度由矢量宽高比决定（上限 128），尽量铺满
        // 标语「本机生成 · 不上传」不放这里（字标下显得挤），改到关于页与首页底部脚注。
        let availW = max(min(UIScreen.main.bounds.width, 560) - Space.l * 2 - Self.logoSize - Space.s, 120)
        let h = min(availW / WordmarkShape.aspect, 128)
        HStack(alignment: .center, spacing: Space.s) {
            Image("BrandMark")
                .resizable().scaledToFit()
                .frame(width: Self.logoSize, height: Self.logoSize)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .shadow(color: Brand.pink.opacity(0.35), radius: 7, y: 3)
            ScriptWordmark()
                .frame(width: availW, height: h, alignment: .trailing)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
        .padding(.bottom, 4)
    }
}

/// Page chrome without large navigation titles (avoids top blank gap + awkward centered title).
struct PageChrome<Content: View>: View {
    var title: String? = nil
    var showBrand: Bool = false
    @ViewBuilder var content: Content
    var body: some View {
        ZStack(alignment: .top) {
            PinkBackground()
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 10) {
                    if showBrand {
                        BrandHeader()
                    } else if let title {
                        Text(title)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Brand.ink)
                            .padding(.top, 6)
                    }
                    content
                }
                .padding(.horizontal, Space.l)
                .padding(.bottom, Space.xl)
                .background(ScrollWatcher())
            }
            .scrollTailCompat()
            BottomFade()
        }
        .hideNavBar()
    }
}

struct HeroCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .glassCard(heavy: true)
    }
}

struct PlainCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 6) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Space.m)
            .softCard()
    }
}

struct StepBadge: View {
    let n: Int; let label: String; var done: Bool = false; var active: Bool = false
    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle().fill(done ? Brand.pink : (active ? Brand.pink.opacity(0.2) : Color.primary.opacity(0.08)))
                    .frame(width: 22, height: 22)
                if done {
                    Image(systemName: "checkmark").font(.caption2.weight(.bold)).foregroundStyle(.white)
                } else {
                    Text("\(n)").font(.caption2.weight(.bold))
                        .foregroundStyle(active ? Brand.pink : .secondary)
                }
            }
            Text(label).font(.caption.weight(active ? .semibold : .regular))
                .foregroundStyle(active || done ? Brand.ink : .secondary)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
    }
}

/// 标签栏上方的渐隐衬底：纯渐变（不再用实时模糊材质——整条 110pt 的模糊在每一帧滚动里都要重算）。
struct BottomFade: View {
    @Environment(\.colorScheme) private var cs
    var body: some View {
        if Appearance.shared.wallpaper == nil {
            let base = cs == .dark ? Color(red: 0.082, green: 0.051, blue: 0.129) : Color(red: 1, green: 0.949, blue: 0.969)
            LinearGradient(colors: [base.opacity(0), base.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                .frame(height: 80)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
        }
    }
}

/// 多行自适应的单选按钮组：代替 segmented Picker，标签再长也会换行显示完整，大字号 / 小屏不会出现省略号。
struct ChoiceTabs<T: Hashable>: View {
    let options: [(T, String)]
    @Binding var selection: T
    @Namespace private var pillNS
    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, o in
                let on = o.0 == selection
                Button {
                    if !on {
                        Haptics.selection()
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) { selection = o.0 }
                    }
                } label: {
                    Text(o.1)
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, 9).padding(.horizontal, 6)
                        .foregroundStyle(on ? Brand.ink : Brand.ink.opacity(0.72))
                        .background {
                            if on {
                                // 滑动的液态玻璃白条：随选择在选项之间滑过去
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.white)
                                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(LinearGradient(colors: [.white.opacity(0.85), .white.opacity(0.35)], startPoint: .top, endPoint: .bottom)))
                                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(LinearGradient(colors: [.white.opacity(0.95), .black.opacity(0.06)], startPoint: .top, endPoint: .bottom), lineWidth: 0.8))
                                    .shadow(color: .black.opacity(0.15), radius: 4, y: 1.5)
                                    .matchedGeometryEffect(id: "choicePill", in: pillNS)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.secondary.opacity(0.14)))
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// 两列网格：所有格子等宽等高；数量为奇数时最后一格占满整行，不留空洞。
struct PairGrid<T: Identifiable, Cell: View>: View {
    let items: [T]; var spacing: CGFloat = 8; let height: CGFloat
    @ViewBuilder var cell: (T) -> Cell
    var body: some View {
        VStack(spacing: spacing) {
            ForEach(Array(stride(from: 0, to: items.count, by: 2)), id: \.self) { i in
                HStack(spacing: spacing) {
                    cell(items[i]).frame(maxWidth: .infinity).frame(height: height)
                    if i + 1 < items.count { cell(items[i + 1]).frame(maxWidth: .infinity).frame(height: height) }
                }
            }
        }
    }
}

/// 可横向滚动的胶囊标签：比等宽分段更小、更圆，适合规则页分区。
struct ChipTabs<T: Hashable>: View {
    let options: [(T, String)]
    @Binding var selection: T
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(options.enumerated()), id: \.offset) { _, o in
                    let on = o.0 == selection
                    Button {
                        if !on { Haptics.selection(); selection = o.0 }
                    } label: {
                        Text(o.1)
                            .font(.caption.weight(.semibold))
                            .padding(.vertical, 6).padding(.horizontal, 11)
                            .foregroundStyle(on ? Color.white : Brand.ink)
                            .background(Capsule(style: .continuous)
                                .fill(on ? AnyShapeStyle(LinearGradient(colors: [Brand.pink, Brand.lilac], startPoint: .leading, endPoint: .trailing))
                                         : AnyShapeStyle(Color.secondary.opacity(0.14))))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            .padding(.vertical, 1)
        }
    }
}

/// 列表密度切换：规则 / 节点页顶栏右侧用。
struct DensityBar: View {
    @ObservedObject private var ap = LayoutPrefs.shared
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "rectangle.grid.1x2").font(.caption2).foregroundStyle(.secondary)
            ForEach(LayoutDensity.allCases) { d in
                let on = ap.density == d
                Button {
                    if !on { Haptics.selection(); ap.density = d }
                } label: {
                    Text(d.label)
                        .lineLimit(1).minimumScaleFactor(0.8)
                        .font(.caption2.weight(on ? .bold : .medium))
                        .padding(.vertical, 4).padding(.horizontal, 8)
                        .foregroundStyle(on ? Color.white : Brand.ink)
                        .background(Capsule().fill(on ? Brand.pink : Color.secondary.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}


