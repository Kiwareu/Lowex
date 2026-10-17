import SwiftUI
import PhotosUI

// 兼容层：Lowex 的最低系统是 iOS 15。较新的 SwiftUI API 在这里集中做可用性判断，
// 旧系统上自动回退到等价或相近的实现（外观略有差异，功能不缺）。

/// iOS 16+ 用 NavigationStack，iOS 15 用单列 NavigationView。
struct NavStack<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }.navigationViewStyle(.stack)
        }
    }
}

extension View {
    /// 隐藏系统导航栏。
    @ViewBuilder func hideNavBar() -> some View {
        if #available(iOS 16.0, *) { self.toolbar(.hidden, for: .navigationBar) }
        else { self.navigationBarHidden(true) }
    }
    /// 底部留白（给悬浮标签栏让位）+ 内容不足一屏时不回弹（iOS 17+）。
    @ViewBuilder func scrollTailCompat() -> some View {
        if #available(iOS 17.0, *) {
            self.scrollBounceBehavior(.basedOnSize).contentMargins(.bottom, 56, for: .scrollContent)
        } else {
            self.safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: 56) }
        }
    }
    /// 文本编辑器 / 列表背景透明（iOS 16+；iOS 15 靠全局 appearance 清掉背景）。
    @ViewBuilder func hideScrollBG() -> some View {
        if #available(iOS 16.0, *) { self.scrollContentBackground(.hidden) } else { self }
    }
    /// 拖动列表时收起键盘（iOS 16+）。
    @ViewBuilder func dismissKeyboardOnScroll() -> some View {
        if #available(iOS 16.0, *) { self.scrollDismissesKeyboard(.interactively) } else { self }
    }
    /// 半高弹窗（iOS 16+，旧系统为全高弹窗）。
    @ViewBuilder func detentsCompat() -> some View {
        if #available(iOS 16.0, *) { self.presentationDetents([.medium, .large]) } else { self }
    }
    /// 全局字体风格（iOS 16.1+，旧系统保持系统默认字体）。
    @ViewBuilder func fontDesignCompat(_ d: Font.Design) -> some View {
        if #available(iOS 16.1, *) { self.fontDesign(d) } else { self }
    }
    /// onChange 的单参数形式：iOS 15 起可用（iOS 17 起仅提示弃用，行为一致）。
    func onChangeValue<V: Equatable>(of value: V, _ action: @escaping (V) -> Void) -> some View {
        self.onChange(of: value, perform: action)
    }
}

/// 相册选图（PHPicker，iOS 14+），代替 iOS 16 才有的 PhotosPicker。
struct ImagePicker: UIViewControllerRepresentable {
    var onPick: (Data) -> Void
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var cfg = PHPickerConfiguration(photoLibrary: .shared())
        cfg.filter = .images; cfg.selectionLimit = 1
        let vc = PHPickerViewController(configuration: cfg)
        vc.delegate = context.coordinator
        return vc
    }
    func updateUIViewController(_ vc: PHPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: (Data) -> Void
        init(onPick: @escaping (Data) -> Void) { self.onPick = onPick }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let p = results.first?.itemProvider, p.canLoadObject(ofClass: UIImage.self) else { return }
            p.loadObject(ofClass: UIImage.self) { obj, _ in
                guard let img = obj as? UIImage, let data = img.jpegData(compressionQuality: 0.95) else { return }
                DispatchQueue.main.async { self.onPick(data) }
            }
        }
    }
}
