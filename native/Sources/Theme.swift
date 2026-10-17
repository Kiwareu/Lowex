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
    var body: some View {
        ZStack {
            // 不透明底色（与 LaunchBackground 同色）：网格渐变的色块带透明度，没有底色时会透出下层页面
            (cs == .dark ? Color(red: 0.082, green: 0.051, blue: 0.129) : Color(red: 1, green: 0.949, blue: 0.969))
            if let img = Appearance.shared.wallpaper {
                Color.clear.overlay { Image(uiImage: img).resizable().scaledToFill() }.clipped()
                Color.black.opacity(cs == .dark ? 0.45 : 0.12)
            } else {
                MeshBackdrop(dark: cs == .dark, speed: Appearance.shared.gradientSpeed, paused: reduce)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

/// 3×3 网格渐变（iOS 18+ 用 MeshGradient，GPU 渲染；更早的系统回退为漂移的径向渐变）。只有内部 5 个控制点做缓慢的李萨如漂移，约 20fps；
/// 角点固定，所以边缘不会露底。
struct MeshBackdrop: View {
    let dark: Bool; let speed: Double; let paused: Bool
    private var colors: [Color] {
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
        let k: Float = 0.11
        return [
            SIMD2<Float>(0, 0), SIMD2<Float>(0.5 + k * sin(t), 0), SIMD2<Float>(1, 0),
            SIMD2<Float>(0, 0.5 + k * cos(t * 0.8)), SIMD2<Float>(0.5 + 0.2 * sin(t * 0.6 + 1), 0.5 + 0.2 * cos(t * 0.5)), SIMD2<Float>(1, 0.5 + k * sin(t * 0.7 + 2)),
            SIMD2<Float>(0, 1), SIMD2<Float>(0.5 + k * cos(t * 0.9 + 0.5), 1), SIMD2<Float>(1, 1)]
    }
    var body: some View {
        let base = dark ? Color(red: 0.08, green: 0.05, blue: 0.13) : Color(red: 1, green: 0.95, blue: 0.97)
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: paused || speed <= 0.01)) { ctx in
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

/// Glass only for a few hero cards — not every list row (keeps XS smooth).
struct GlassCard: ViewModifier {
    var radius: CGFloat? = nil
    var heavy: Bool = false
    private var r: CGFloat { radius ?? (Brand.radius + 4) }
    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *), heavy {
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
            .background {
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.45 + 0.55 * Brand.glass))
            }
            .overlay {
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.08)],
                                       startPoint: .top, endPoint: .bottom),
                        lineWidth: 0.8)
            }
            .shadow(color: .black.opacity(heavy ? 0.10 : 0.05), radius: heavy ? 12 : 6, y: heavy ? 5 : 2)
    }
}

extension View {
    func glassCard(radius: CGFloat? = nil, heavy: Bool = false) -> some View {
        modifier(GlassCard(radius: radius, heavy: heavy))
    }
}

/// Soft row surface — cheaper than material blur on every cell.
struct SoftCard: ViewModifier {
    var radius: CGFloat? = nil
    @Environment(\.colorScheme) private var cs
    func body(content: Content) -> some View {
        let r = radius ?? max(8, Brand.radius * 0.8)
        let k = Brand.glass
        content
            .background {
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .fill(cs == .dark ? Color.white.opacity(0.05 + 0.10 * k) : Color.white.opacity(0.30 + 0.40 * k))
            }
            .overlay {
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .strokeBorder(Color.white.opacity(cs == .dark ? 0.10 : 0.45), lineWidth: 0.6)
            }
    }
}
extension View {
    func softCard(radius: CGFloat? = nil) -> some View { modifier(SoftCard(radius: radius)) }
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
    var subtitle: String? = nil
    private static let logoSize: CGFloat = 50

    var body: some View {
        // 字标区宽度 = 屏幕宽 - 两侧页边距 - Logo；高度由矢量宽高比决定（上限 128），尽量铺满
        let availW = max(min(UIScreen.main.bounds.width, 560) - Space.l * 2 - Self.logoSize - Space.s, 120)
        let h = min(availW / WordmarkShape.aspect, 128)
        VStack(alignment: .trailing, spacing: 0) {
            HStack(alignment: .center, spacing: Space.s) {
                Image("BrandMark")
                    .resizable().scaledToFit()
                    .frame(width: Self.logoSize, height: Self.logoSize)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .shadow(color: Brand.pink.opacity(0.35), radius: 7, y: 3)
                ScriptWordmark()
                    .frame(width: availW, height: h, alignment: .trailing)
            }
            // 副标题靠右、紧贴字标下沿；"L" 的尾巴在左侧，不会与它重叠
            Text(subtitle ?? L("本机生成 · 不上传"))
                .font(.caption2).foregroundStyle(.secondary)
                .lineLimit(1).minimumScaleFactor(0.8)
                .padding(.top, -2)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
        .padding(.bottom, 2)
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
                LazyVStack(alignment: .leading, spacing: Space.m) {
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
        VStack(alignment: .leading, spacing: 10) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .glassCard(heavy: true)
    }
}

struct PlainCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Space.l)
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
        }
    }
}

/// 标签栏上方的渐隐衬底：内容滚到底栏下时不再「糊」在文字上（单层静态材质，XS 友好）
struct BottomFade: View {
    var body: some View {
        Rectangle()
            .fill(.regularMaterial)
            .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black.opacity(0.85), location: 0.55), .init(color: .black, location: 1)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(height: 110)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
    }
}

/// 多行自适应的单选按钮组：代替 segmented Picker，标签再长也会换行显示完整，大字号 / 小屏不会出现省略号。
struct ChoiceTabs<T: Hashable>: View {
    let options: [(T, String)]
    @Binding var selection: T
    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, o in
                let on = o.0 == selection
                Button {
                    if !on { Haptics.selection(); selection = o.0 }
                } label: {
                    Text(o.1)
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, 9).padding(.horizontal, 6)
                        .foregroundStyle(on ? Color.white : Brand.ink)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(on ? AnyShapeStyle(LinearGradient(colors: [Brand.pink, Brand.lilac], startPoint: .topLeading, endPoint: .bottomTrailing))
                                     : AnyShapeStyle(Color.secondary.opacity(0.14))))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
