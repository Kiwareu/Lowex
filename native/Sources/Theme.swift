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

/// 背景：自定义壁纸 > 渐变（可调速、减弱动态时静止）。动画限 15fps，iPhone XS 友好。
struct PinkBackground: View {
    @Environment(\.colorScheme) private var cs
    @Environment(\.accessibilityReduceMotion) private var reduce
    var body: some View {
        ZStack {
            if let img = Appearance.shared.wallpaper {
                Color.clear.overlay { Image(uiImage: img).resizable().scaledToFill() }.clipped()
                Color.black.opacity(cs == .dark ? 0.45 : 0.12)
            } else {
                LinearGradient(
                    colors: cs == .dark
                        ? [Color(red: 0.10, green: 0.05, blue: 0.14), Color(red: 0.08, green: 0.06, blue: 0.17), Color(red: 0.12, green: 0.06, blue: 0.12)]
                        : [Color(red: 1, green: 0.94, blue: 0.97), Color(red: 0.97, green: 0.92, blue: 1.0), Color(red: 1, green: 0.95, blue: 0.93)],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                blobs
            }
        }
        .ignoresSafeArea()
    }
    @ViewBuilder private var blobs: some View {
        let speed = Appearance.shared.gradientSpeed
        let k = cs == .dark ? 0.55 : 1.0
        TimelineView(.animation(minimumInterval: 1.0 / 15.0, paused: reduce || speed <= 0.01)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate * speed * 0.35
            ZStack {
                RadialGradient(colors: [Brand.pinkSoft.opacity(0.42 * k), .clear],
                               center: UnitPoint(x: 0.2 + 0.18 * sin(t), y: 0.12 + 0.10 * cos(t * 0.8)), startRadius: 8, endRadius: 380)
                RadialGradient(colors: [Brand.lilac.opacity(0.34 * k), .clear],
                               center: UnitPoint(x: 0.85 + 0.12 * cos(t * 0.7), y: 0.85 + 0.10 * sin(t)), startRadius: 8, endRadius: 420)
                RadialGradient(colors: [Brand.peach.opacity(0.22 * k), .clear],
                               center: UnitPoint(x: 0.7 + 0.2 * sin(t * 0.9 + 1), y: 0.25 + 0.12 * cos(t * 0.6)), startRadius: 4, endRadius: 260)
            }
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
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.62), value: configuration.isPressed)
    }
}

struct BrandHeader: View {
    var subtitle: String? = nil
    var body: some View {
        HStack(spacing: 12) {
            Image("BrandMark")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Brand.pink.opacity(0.35), radius: 8, y: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Lowex")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [Brand.pink, Brand.lilac],
                                       startPoint: .leading, endPoint: .trailing))
                Text(subtitle ?? "本机生成 · 不上传")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 8)
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
                LazyVStack(alignment: .leading, spacing: 12) {
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
        VStack(alignment: .leading, spacing: 8) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
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
