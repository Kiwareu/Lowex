import SwiftUI
import UIKit
import Security

// MARK: - 触感反馈（统一入口，受设置开关控制）
enum Haptics {
    static var enabled: Bool { Appearance.shared.haptics }
    static func light() { guard enabled else { return }; UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7) }
    static func selection() { guard enabled else { return }; UISelectionFeedbackGenerator().selectionChanged() }
    static func success() { guard enabled else { return }; UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { guard enabled else { return }; UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}

// MARK: - 键盘：工具栏「完成」+ 点空白处收起（不影响按钮 / 输入框）
final class KeyboardHelper: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardHelper()
    private var installed = false
    private lazy var bar: UIToolbar = {
        let tb = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        tb.sizeToFit()
        let done = UIBarButtonItem(title: L("完成"), style: .done, target: self, action: #selector(dismissKeyboard))
        tb.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), done]
        return tb
    }()

    func install() {
        guard !installed else { return }
        installed = true
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(began(_:)), name: UITextField.textDidBeginEditingNotification, object: nil)
        nc.addObserver(self, selector: #selector(began(_:)), name: UITextView.textDidBeginEditingNotification, object: nil)
        DispatchQueue.main.async { self.attachTap() }
    }
    @objc private func began(_ n: Notification) {
        if let f = n.object as? UITextField, f.inputAccessoryView == nil { f.inputAccessoryView = bar; f.reloadInputViews() }
        if let v = n.object as? UITextView, v.inputAccessoryView == nil { v.inputAccessoryView = bar; v.reloadInputViews() }
    }
    @objc func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    private func attachTap() {
        guard let w = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.windows.first(where: \.isKeyWindow) }).first else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.attachTap() }; return
        }
        let g = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        g.cancelsTouchesInView = false
        g.delegate = self
        w.addGestureRecognizer(g)
    }
    func gestureRecognizer(_ g: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var v: UIView? = touch.view
        while let x = v {
            if x is UITextField || x is UITextView || x is UIControl || x is UIToolbar { return false }
            v = x.superview
        }
        return true
    }
    func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
}

// MARK: - 手动节点密码：优先钥匙串；当前签名不允许时回退到沙盒私有文件（不上传）
enum SecretStore {
    private static let service = "com.lowex.manualnode"
    private static var fileURL: URL {
        let d = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d.appendingPathComponent("manual-secrets.json")
    }
    private static func loadFile() -> [String: String] {
        guard let d = try? Data(contentsOf: fileURL), let j = try? JSONDecoder().decode([String: String].self, from: d) else { return [:] }
        return j
    }
    private static func saveFile(_ m: [String: String]) {
        guard let d = try? JSONEncoder().encode(m) else { return }
        try? d.write(to: fileURL, options: [.atomic, .completeFileProtection])
        var u = fileURL; var rv = URLResourceValues(); rv.isExcludedFromBackup = true; try? u.setResourceValues(rv)
    }
    private static func base(_ id: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: id]
    }
    static func set(_ value: String, id: String) {
        SecItemDelete(base(id) as CFDictionary)
        var f = loadFile()
        if value.isEmpty { f[id] = nil; saveFile(f); return }
        var q = base(id)
        q[kSecValueData as String] = Data(value.utf8)
        q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        if SecItemAdd(q as CFDictionary, nil) == errSecSuccess { f[id] = nil } else { f[id] = value }
        saveFile(f)
    }
    static func get(_ id: String) -> String {
        var q = base(id)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: CFTypeRef?
        if SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let d = out as? Data, let s = String(data: d, encoding: .utf8) { return s }
        return loadFile()[id] ?? ""
    }
    static func remove(_ id: String) { set("", id: id) }
}
