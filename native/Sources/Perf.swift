import SwiftUI
import UIKit
import QuartzCore

/// 设备与性能模式。性能模式 = 静态背景 + 实心半透明卡片（无实时模糊 / 阴影），较旧机型（A12 及更早，如 iPhone XS）默认开启。
enum DeviceInfo {
    static let machine: String = {
        var s = utsname(); uname(&s)
        return withUnsafePointer(to: &s.machine) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) } }
    }()
    /// iPhone11,x（XS / XR）及更早，或内存小于 3.5GB
    static let isLowEnd: Bool = {
        if machine.hasPrefix("iPhone"), let n = Int(machine.dropFirst(6).prefix { $0.isNumber }), n <= 11 { return true }
        return ProcessInfo.processInfo.physicalMemory < 3_500_000_000
    }()
}

/// 当前正在显示的标签页：背景动画只在可见页面上跑，其余四页的背景保持静止。
final class ActiveTab: ObservableObject {
    static let shared = ActiveTab()
    @Published var tab: AppTab = .home
}
private struct PageTabKey: EnvironmentKey { static let defaultValue: AppTab? = nil }
extension EnvironmentValues {
    var pageTab: AppTab? { get { self[PageTabKey.self] } set { self[PageTabKey.self] = newValue } }
}

/// 轻量开关：纯形状绘制，代替每行一个 UISwitch + scaleEffect（长列表里最贵的控件之一）。
struct MiniSwitch: View {
    let on: Bool
    var action: (Bool) -> Void
    var body: some View {
        Button { action(!on) } label: {
            ZStack(alignment: on ? .trailing : .leading) {
                Capsule().fill(on ? Brand.pink : Color.secondary.opacity(0.32))
                Circle().fill(Color.white).padding(2)
            }
            .frame(width: 42, height: 25)
            .frame(width: 46, height: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(on ? "on" : "off")
    }
}

/// 隐藏的帧率浮层（More → 关于 里连点版本号 7 次开关）。CADisplayLink 统计，每秒刷新一次显示，不会引起额外重绘。
final class FPSMeter: ObservableObject {
    static let shared = FPSMeter()
    @Published private(set) var enabled = UserDefaults.standard.bool(forKey: "dbg.fps")
    @Published private(set) var text = "—"
    private var link: CADisplayLink?
    private var last: CFTimeInterval = 0, acc: CFTimeInterval = 0, frames = 0, worst: CFTimeInterval = 0
    init() { if enabled { start() } }
    func toggle() {
        enabled.toggle(); UserDefaults.standard.set(enabled, forKey: "dbg.fps")
        enabled ? start() : stop()
    }
    private func start() {
        guard link == nil else { return }
        last = 0; acc = 0; frames = 0; worst = 0
        let l = CADisplayLink(target: self, selector: #selector(tick(_:)))
        l.add(to: .main, forMode: .common); link = l
    }
    private func stop() { link?.invalidate(); link = nil }
    @objc private func tick(_ l: CADisplayLink) {
        let now = l.timestamp
        if last > 0 {
            let dt = now - last
            acc += dt; frames += 1; worst = max(worst, dt)
            if acc >= 1 {
                text = String(format: "%.0f fps · max %.0f ms", Double(frames) / acc, worst * 1000)
                acc = 0; frames = 0; worst = 0
            }
        }
        last = now
    }
}
struct FPSOverlay: View {
    @ObservedObject private var m = FPSMeter.shared
    var body: some View {
        if m.enabled {
            Text(m.text).font(.system(size: 11, weight: .semibold, design: .monospaced)).foregroundColor(.white)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.black.opacity(0.7), in: Capsule())
                .padding(.top, 4).padding(.trailing, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .allowsHitTesting(false)
        }
    }
}

/// 连点 7 次开关隐藏的帧率浮层
private struct FPSSecret: ViewModifier {
    @State private var taps = 0
    @State private var lastTap = Date.distantPast
    func body(content: Content) -> some View {
        content.contentShape(Rectangle()).onTapGesture {
            let now = Date()
            taps = now.timeIntervalSince(lastTap) > 1.5 ? 1 : taps + 1
            lastTap = now
            if taps >= 7 { taps = 0; FPSMeter.shared.toggle(); Haptics.success() }
        }
    }
}
extension View { func fpsSecret() -> some View { modifier(FPSSecret()) } }
