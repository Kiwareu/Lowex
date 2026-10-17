import SwiftUI
import Foundation

/// 界面语言：跟随系统 / 简体中文 / 繁體中文（台灣）/ 繁體中文（香港）/ English。
/// 源码里的中文原文就是翻译表的 key（简体中文即原文）；翻译表在 Resources/Lang/*.json（key → 译文，`{}` / `{1}` 是占位符）。
enum AppLang: String, CaseIterable, Identifiable {
    case system, zhHans, zhHantTW, zhHantHK, en
    var id: String { rawValue }
    /// 选项名固定用各语言自己的写法，方便在任何语言下找到
    var label: String {
        switch self {
        case .system: return "跟随系统 · System"
        case .zhHans: return "简体中文"
        case .zhHantTW: return "繁體中文（台灣）"
        case .zhHantHK: return "繁體中文（香港）"
        case .en: return "English"
        }
    }
    var table: String? {
        switch self {
        case .zhHantTW: return "zh-Hant-TW"
        case .zhHantHK: return "zh-Hant-HK"
        case .en: return "en"
        default: return nil
        }
    }
    var locale: Locale {
        switch self {
        case .zhHantTW: return Locale(identifier: "zh-Hant-TW")
        case .zhHantHK: return Locale(identifier: "zh-Hant-HK")
        case .en: return Locale(identifier: "en")
        default: return Locale(identifier: "zh-Hans")
        }
    }
}

final class Lang: ObservableObject {
    static let shared = Lang()
    private let key = "lowex.lang.choice.v1"
    @Published var revision = 0
    var choice: AppLang { didSet { UserDefaults.standard.set(choice.rawValue, forKey: key); reload() } }
    private(set) var resolved: AppLang = .zhHans
    private var dict: [String: String] = [:]
    private var patterns: [(NSRegularExpression, String)] = []

    private init() {
        choice = AppLang(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? .system
        reload(bump: false)
    }

    /// 跟随系统时按系统首选语言挑：简体 → 简体；港澳 → 香港繁體；其他繁體 → 台灣繁體；其余 → English
    static func systemChoice() -> AppLang {
        for l in Locale.preferredLanguages {
            let s = l.lowercased()
            if s.hasPrefix("zh") {
                if s.contains("hant") || s.contains("-tw") || s.contains("-hk") || s.contains("-mo") {
                    return (s.contains("-hk") || s.contains("-mo")) ? .zhHantHK : .zhHantTW
                }
                return .zhHans
            }
            if s.hasPrefix("en") { return .en }
        }
        return .en
    }

    func reload(bump: Bool = true) {
        resolved = choice == .system ? Lang.systemChoice() : choice
        dict = [:]; patterns = []
        if let t = resolved.table,
           let data = try? Data(contentsOf: Bundle.main.bundleURL.appendingPathComponent("Lang/\(t).json")),
           let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: String] {
            dict = obj
            for (k, v) in obj where k.contains("{}") {
                let esc = NSRegularExpression.escapedPattern(for: k).replacingOccurrences(of: "\\{\\}", with: "(.+?)")
                if let re = try? NSRegularExpression(pattern: "^" + esc + "$", options: [.dotMatchesLineSeparators]) {
                    patterns.append((re, v))
                }
            }
            patterns.sort { $0.1.count > $1.1.count }
        }
        if bump { DispatchQueue.main.async { self.revision += 1 } }
    }

    private static func fill(_ t: String, _ args: [String]) -> String {
        if args.isEmpty { return t }
        var out = ""; var i = 0; var seq = 0
        let chars = Array(t)
        while i < chars.count {
            if chars[i] == "{" {
                if i + 1 < chars.count, chars[i + 1] == "}" {
                    if seq < args.count { out += args[seq] }; seq += 1; i += 2; continue
                }
                var j = i + 1; var num = ""
                while j < chars.count, chars[j].isNumber { num.append(chars[j]); j += 1 }
                if j < chars.count, chars[j] == "}", let n = Int(num), n >= 1, n <= args.count { out += args[n - 1]; i = j + 1; continue }
            }
            out.append(chars[i]); i += 1
        }
        return out
    }

    /// 原文（简体中文）→ 当前语言；精确匹配 → 「【配置取证】」复合句 → 带占位符的模式；都没有就原样返回。
    func tr(_ s: String) -> String {
        if resolved == .zhHans || s.isEmpty { return s }
        if let v = dict[s] { return v }
        let pre = "【配置取证】"
        if s.hasPrefix(pre) {
            let body = String(s.dropFirst(pre.count))
            let head = tr("【配置取证】")
            if let r = body.range(of: "。 ") {
                let ev = String(body[..<r.lowerBound]); let why = String(body[r.upperBound...])
                return head + tr(ev) + tr("。") + " " + tr(why)
            }
            return head + tr(body)
        }
        // 「正文 + 空格开头的补充句」拼接：在 "。 / ） " 之后的空格处拆成两段分别翻
        let chars = Array(s)
        if chars.count > 2 {
            for i in 1..<chars.count where chars[i] == " " && "。）)；".contains(chars[i - 1]) {
                let a = String(chars[..<i]); let b = String(chars[i...])
                if let x = dict[a], let y = dict[b] { return x + y }
            }
        }
        for (re, v) in patterns {
            let ns = s as NSString
            if let m = re.firstMatch(in: s, range: NSRange(location: 0, length: ns.length)) {
                var args: [String] = []
                for g in 1..<m.numberOfRanges { args.append(tr(ns.substring(with: m.range(at: g)))) }
                return Lang.fill(v, args)
            }
        }
        return s
    }

    func translated(_ key: String, _ args: [Any]) -> String {
        let base = resolved == .zhHans ? key : (dict[key] ?? key)
        return Lang.fill(base, args.map { "\($0)" })
    }

    /// 引擎返回的 JSON：把里面的中文显示串翻成当前语言（skip 里的字段不动，例如生成出的配置正文）
    func translateJSON(_ raw: String, skip: Set<String> = []) -> String {
        if resolved == .zhHans { return raw }
        guard let obj = try? JSONSerialization.jsonObject(with: Data(raw.utf8), options: [.fragmentsAllowed]) else { return raw }
        func walk(_ v: Any, _ k: String?) -> Any {
            if let k, skip.contains(k) { return v }
            if let s = v as? String { return tr(s) }
            if let a = v as? [Any] { return a.map { walk($0, nil) } }
            if let d = v as? [String: Any] { return d.reduce(into: [String: Any]()) { $0[$1.key] = walk($1.value, $1.key) } }
            return v
        }
        let out = walk(obj, nil)
        guard let d = try? JSONSerialization.data(withJSONObject: out, options: [.fragmentsAllowed]), let s = String(data: d, encoding: .utf8) else { return raw }
        return s
    }
}

/// 本地化：L("中文原文") 或 L("共 {} 项", n)
func L(_ key: String, _ args: Any...) -> String { Lang.shared.translated(key, args) }
