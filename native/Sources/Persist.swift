import Foundation
import UIKit

/// 本地私有文件：只写在 App 沙盒（Application Support/Lowex），不上传、不进 iCloud / 设备备份。
/// 用来存订阅链接 / 粘贴的节点（含密钥）与「历史记录」。
enum LocalFile {
    private static let queue = DispatchQueue(label: "lowex.localfile", qos: .utility)
    private static var dir: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Lowex", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }
    static func url(_ name: String) -> URL { dir.appendingPathComponent(name) }
    static func read(_ name: String) -> Data? { try? Data(contentsOf: url(name)) }
    /// 异步写入（串行队列，保证顺序）
    static func write(_ data: Data, _ name: String) {
        let u = url(name)
        queue.async {
            try? data.write(to: u, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            var uu = u; var rv = URLResourceValues(); rv.isExcludedFromBackup = true; try? uu.setResourceValues(rv)
        }
    }
    static func remove(_ name: String) {
        let u = url(name)
        queue.async { try? FileManager.default.removeItem(at: u) }
    }
    /// 等待此前排队的写入完成（备份 / 退出前用）
    static func flush() { queue.sync {} }
}

/// 导出 / 分享用的临时文件：文件名（含扩展名）原样保留，系统才会按 .yaml / .conf / .json 处理，而不是 .txt。
enum TempFile {
    static func safeName(_ n: String, fallback: String) -> String {
        let bad = CharacterSet(charactersIn: "/\\:*?\"<>|\n\r")
        let s = n.components(separatedBy: bad).joined(separator: "-").trimmingCharacters(in: .whitespaces)
        return s.isEmpty ? fallback : s
    }
    static func make(name: String, text: String, fallback: String = "lowex.conf") -> URL? {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("lowex-export", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(safeName(name, fallback: fallback))
        do { try Data(text.utf8).write(to: url, options: .atomic); return url } catch { return nil }
    }
}
