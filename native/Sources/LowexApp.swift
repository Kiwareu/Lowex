import SwiftUI
import UIKit

@main
struct LowexApp: App {
    init() {
        UIScrollView.appearance().bounces = false
        UITableView.appearance().bounces = false
        let tb = UITabBarAppearance(); tb.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tb
        UITabBar.appearance().scrollEdgeAppearance = tb
    }
    @StateObject private var store = Store()
    @StateObject private var appearance = Appearance.shared
    @StateObject private var lang = Lang.shared
    var body: some Scene {
        WindowGroup {
            RootContainer()
                .environmentObject(store)
                .environmentObject(appearance)
                .environmentObject(lang)
                .environment(\.locale, lang.resolved.locale)
        }
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
            if store.showSplash {
                SplashView().allowsHitTesting(false).transition(.opacity).zIndex(5)
            }
        }
        .preferredColorScheme(appearance.scheme)
        .fontDesign(appearance.fontStyle.design)
        .onChange(of: lang.revision) { _, _ in store.reloadLanguage() }
        .onChange(of: store.celebrate) { _, _ in Haptics.success() }
        .submitLabel(.done)
        .onSubmit { KeyboardHelper.shared.dismissKeyboard() }
        .onAppear { KeyboardHelper.shared.install() }
        .task {
            try? await Task.sleep(nanoseconds: 1_700_000_000)
            store.finishSplash()
        }
        .sheet(isPresented: $store.showDisclaimer) {
            NavigationStack {
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
                .fontDesign(appearance.fontStyle.design)
                .tint(appearance.accent)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: Store
    var body: some View {
        TabView(selection: $store.tab) {
            HomeView().tag(AppTab.home)
                .tabItem { Label(L("首页"), systemImage: "house.fill") }
            NodesView().tag(AppTab.nodes)
                .tabItem { Label(L("节点"), systemImage: "server.rack") }
            RulesView().tag(AppTab.rules)
                .tabItem { Label(L("规则"), systemImage: "list.bullet.rectangle") }
            GenerateView().tag(AppTab.generate)
                .tabItem { Label(L("生成"), systemImage: "sparkles") }
            MoreView().tag(AppTab.more)
                .tabItem { Label(L("更多"), systemImage: "ellipsis.circle") }
        }
        .tint(Brand.pink)
    }
}

enum AppTab: Hashable { case home, nodes, rules, generate, more }
