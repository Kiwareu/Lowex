import SwiftUI
import UIKit

@main
struct LowexApp: App {
    init() {
        UIScrollView.appearance().bounces = false
        // 默认滚动视图会把触摸延迟约 150ms 才交给按钮，快速点按 chevron 时像「没反应」
        UIScrollView.appearance().delaysContentTouches = false
        UITableView.appearance().bounces = false
        UITextView.appearance().backgroundColor = .clear   // iOS 15：TextEditor 背景透明
        let tb = UITabBarAppearance(); tb.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tb
        UITabBar.appearance().scrollEdgeAppearance = tb
        IconCache.warm()
    }
    @StateObject private var boot = Boot()
    @StateObject private var appearance = Appearance.shared
    @StateObject private var lang = Lang.shared
    var body: some Scene {
        WindowGroup {
            RootGate(boot: boot)
                .environmentObject(appearance)
                .environmentObject(lang)
                .environment(\.locale, lang.resolved.locale)
        }
    }
}

/// 启动编排：先显示启动动画；引擎（JavaScriptCore）在后台线程加载，加载完再在主线程建 Store。
/// 动画与引擎加载互不阻塞；动画走完且 Store 就绪后淡出进首页。
final class Boot: ObservableObject {
    @Published var store: Store?
    @Published var showSplash = true
    init() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            _ = Engine.shared   // 解析 engine.js（最耗时的一步）放在后台
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { self?.store = Store() }
        }
    }
    func finish(duration: Double) {
        withAnimation(.easeOut(duration: duration)) { showSplash = false }
        store?.finishSplash()
    }
}

struct RootGate: View {
    @ObservedObject var boot: Boot
    @EnvironmentObject var appearance: Appearance
    var body: some View {
        ZStack {
            if let store = boot.store {
                // 首页在启动动画下面先布局好（不可见、不可点），动画结束后一起淡入 + 轻微放大
                RootContainer()
                    .environmentObject(store)
                    .opacity(boot.showSplash ? 0 : 1)
                    .scaleEffect(boot.showSplash ? 0.97 : 1)
                    .allowsHitTesting(!boot.showSplash)
                    .accessibilityHidden(boot.showSplash)
            }
            if boot.showSplash {
                SplashView(boot: boot)
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
                    .zIndex(5)
            }
        }
        .preferredColorScheme(appearance.scheme)
        .fontDesignCompat(appearance.fontStyle.design)
    }
}

struct RootContainer: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var appearance: Appearance
    @EnvironmentObject var lang: Lang
    var body: some View {
        ZStack {
            RootView().id("\(appearance.revision)-\(lang.revision)")
            ConfettiView(trigger: store.celebrate)
        }
        .preferredColorScheme(appearance.scheme)
        .fontDesignCompat(appearance.fontStyle.design)
        .onChangeValue(of: lang.revision) { _ in store.reloadLanguage() }
        .onChangeValue(of: store.celebrate) { _ in Haptics.success() }
        .submitLabel(.done)
        .onSubmit { KeyboardHelper.shared.dismissKeyboard() }
        .onAppear { KeyboardHelper.shared.install() }
        .sheet(isPresented: $store.showDisclaimer) {
            NavStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(L("免责声明")).font(.title2.weight(.bold))
                        Text(DisclaimerText.body).font(.footnote)
                        Button { store.acceptDisclaimer() } label: {
                            Text(L("我已阅读并知悉上述内容")).frame(maxWidth: .infinity).padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent).tint(Brand.pink)
                    }
                    .padding(20)
                }
                .background(PinkBackground())
            }
            .interactiveDismissDisabled(true)
            .preferredColorScheme(appearance.scheme)
        }
        .sheet(isPresented: $store.showAppearance) {
            AppearanceView().id(appearance.revision)
                .preferredColorScheme(appearance.scheme)
                .fontDesignCompat(appearance.fontStyle.design)
                .tint(appearance.accent)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: Store
    var body: some View {
        TabView(selection: $store.tab) {
            HomeView().environment(\.pageTab, .home).tag(AppTab.home)
                .tabItem { Label(L("首页"), systemImage: "house.fill") }
            NodesView().environment(\.pageTab, .nodes).tag(AppTab.nodes)
                .tabItem { Label(L("节点"), systemImage: "server.rack") }
            RulesView().environment(\.pageTab, .rules).tag(AppTab.rules)
                .tabItem { Label(L("规则"), systemImage: "list.bullet.rectangle") }
            GenerateView().environment(\.pageTab, .generate).tag(AppTab.generate)
                .tabItem { Label(L("生成"), systemImage: "sparkles") }
            MoreView().environment(\.pageTab, .more).tag(AppTab.more)
                .tabItem { Label(L("更多"), systemImage: "ellipsis.circle") }
        }
        .tint(Brand.pink)
        .onChangeValue(of: store.tab) { ActiveTab.shared.tab = $0 }
        .overlay(FPSOverlay())
    }
}

enum AppTab: Hashable { case home, nodes, rules, generate, more }
