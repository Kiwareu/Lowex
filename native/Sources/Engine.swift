import Foundation
import JavaScriptCore
import Security

/// 生成引擎 = 网页版同一份 TypeScript 引擎（engine.js），在 JavaScriptCore 运行。界面原生，规则逻辑不重写。
final class Engine {
    static let shared = Engine()
    private let ctx = JSContext()!
    private var api: JSValue

    private init() {
        ctx.exceptionHandler = { _, e in NSLog("Lowex JS error: %@", e?.toString() ?? "?") }
        Self.installSecureRandom(into: ctx)
        let url = Bundle.main.url(forResource: "engine", withExtension: "js")!
        let src = try! String(contentsOf: url, encoding: .utf8)
        ctx.evaluateScript(src)
        api = ctx.objectForKeyedSubscript("Lowex")
    }

    /// 真随机：把 SecRandomCopyBytes 注入 JSC，供 prelude.js 的 crypto.getRandomValues 使用。
    /// 注入失败时 prelude 会直接抛错（绝不回退 Math.random），App 会在启动时失败而不是静默生成可预测的密钥。
    private static func installSecureRandom(into ctx: JSContext) {
        let secureRandom: @convention(block) (Int) -> [NSNumber]? = { count in
            guard count > 0, count <= 4096 else { return nil }
            var bytes = [UInt8](repeating: 0, count: count)
            let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
            guard status == errSecSuccess else { return nil }
            return bytes.map { NSNumber(value: $0) }
        }
        ctx.setObject(secureRandom as AnyObject, forKeyedSubscript: "__lowexSecureRandom" as NSString)
    }

    /// Lowex-Icons 仓库里已上传的组 id 列表（JSON 数组字符串）；引擎据此改用仓库图标
    func setIconsReady(_ ids: [String]) {
        guard let d = try? JSONSerialization.data(withJSONObject: ids), let s = String(data: d, encoding: .utf8) else { return }
        _ = call("setIconsReady", [s])
    }
    var version: String { api.objectForKeyedSubscript("version").toString() }

    private func call(_ name: String, _ args: [Any]) -> String {
        let raw = api.objectForKeyedSubscript(name).call(withArguments: args)?.toString() ?? "{}"
        // 这些返回的是状态 / 数据，不是显示文案：不翻译
        if ["initial", "applyPreset", "version"].contains(name) { return raw }
        var skip: Set<String> = []
        if name == "generate" { skip = ["text", "name", "ext", "mime"] }
        if name == "catalog" { skip = ["apps", "icon", "ext", "id", "family", "platforms"] }
        return Lang.shared.translateJSON(raw, skip: skip)
    }

    func initialState(client: String, platform: String) -> [String: Any] {
        json(call("initial", [client, platform]))
    }
    func catalog() -> Catalog {
        let s = call("catalog", [])
        return (try? JSONDecoder().decode(Catalog.self, from: Data(s.utf8))) ?? Catalog.empty
    }
    func recommend(network: String, location: String, platform: String) -> [String: Any] {
        json(call("recommend", [network, location, platform]))
    }
    func supports(client: String, feature: String) -> Bool {
        api.objectForKeyedSubscript("supports").call(withArguments: [client, feature])?.toBool() ?? false
    }
    func generate(state: [String: Any]) -> GenResult {
        guard let d = try? JSONSerialization.data(withJSONObject: state), let s = String(data: d, encoding: .utf8) else {
            return GenResult(error: L("方案无法序列化"))
        }
        let r = json(call("generate", [s]))
        if let e = r["error"] as? String { return GenResult(error: e) }
        return GenResult(text: r["text"] as? String ?? "", name: r["name"] as? String ?? "lowex.conf",
                         warnings: r["warnings"] as? [String] ?? [])
    }
    func leak(state: [String: Any]) -> [LeakItem] {
        guard let d = try? JSONSerialization.data(withJSONObject: state), let s = String(data: d, encoding: .utf8) else { return [] }
        let r = json(call("leak", [s]))
        let st = r["status"] as? [String: String] ?? [:]
        return (r["items"] as? [[String: Any]] ?? []).map {
            LeakItem(id: $0["id"] as? String ?? UUID().uuidString, group: $0["group"] as? String ?? "", title: $0["title"] as? String ?? "",
                     status: st[$0["status"] as? String ?? ""] ?? ($0["status"] as? String ?? ""), why: $0["why"] as? String ?? "", how: $0["how"] as? String)
        }
    }
    /// 防泄漏综合分（由引擎按生成出的配置文本取证后计算）
    func leakScore(state: [String: Any]) -> (Int, String)? {
        guard let d = try? JSONSerialization.data(withJSONObject: state), let s = String(data: d, encoding: .utf8) else { return nil }
        let r = json(call("leak", [s]))
        guard let sc = r["score"] as? [String: Any], let v = sc["score"] as? Int else { return nil }
        return (v, sc["note"] as? String ?? "")
    }
    func carriers() -> [Carrier] {
        (try? JSONDecoder().decode([Carrier].self, from: Data(call("carriers", []).utf8))) ?? []
    }
    func shared() -> [[String: Any]] {
        (try? JSONSerialization.jsonObject(with: Data(call("sharedList", []).utf8))) as? [[String: Any]] ?? []
    }
    func modInfo(name: String, url: String, content: String) -> [String: Any] { json(call("modInfo", [name, url, content])) }
    func supportsModules(client: String) -> Bool {
        api.objectForKeyedSubscript("supportsModules").call(withArguments: [client])?.toBool() ?? false
    }
    struct ManualCap: Decodable { let id: String; let socks5: Bool; let socks5tls: Bool; let http: Bool; let https: Bool }
    func manualMatrix() -> [ManualCap] {
        (try? JSONDecoder().decode([ManualCap].self, from: Data(call("manualMatrix", []).utf8))) ?? []
    }
    func manualIssue(client: String, node: [String: Any]) -> String? {
        guard let d = try? JSONSerialization.data(withJSONObject: node), let s = String(data: d, encoding: .utf8) else { return L("无法序列化") }
        return json(call("manualIssue", [client, s]))["issue"] as? String
    }
    func presets() -> [[String: Any]] {
        (try? JSONSerialization.jsonObject(with: Data(call("presets", []).utf8))) as? [[String: Any]] ?? []
    }

    // MARK: 9.8+ 接线（直通引擎 API，不经翻译，避免校验文案 / 脚本模板被改写）
    struct ValidationIssue: Identifiable {
        let id = UUID(); let level: String; let msg: String
        var isError: Bool { level == "error" }
    }
    func validateConfig(family: String, text: String) -> [ValidationIssue] {
        let s = api.objectForKeyedSubscript("validateConfig")?.call(withArguments: [family, text])?.toString() ?? "[]"
        guard let d = s.data(using: .utf8), let arr = try? JSONSerialization.jsonObject(with: d) as? [[String: Any]] else { return [] }
        return arr.compactMap { item in
            guard let msg = item["msg"] as? String else { return nil }
            return ValidationIssue(level: item["level"] as? String ?? "warn", msg: msg)
        }
    }
    struct Tiers { let quic: String; let stun: String }
    func tiers(client: String) -> Tiers {
        let r = json(api.objectForKeyedSubscript("tiers")?.call(withArguments: [client])?.toString() ?? "{}")
        return Tiers(quic: r["quic"] as? String ?? "unknown", stun: r["stun"] as? String ?? "unknown")
    }
    /// 分层预设 A/B：由 opts.failover 决定（true = A，false = B）
    func presetMode(state: [String: Any]) -> String {
        guard let d = try? JSONSerialization.data(withJSONObject: state), let s = String(data: d, encoding: .utf8) else { return "A" }
        let r = json(api.objectForKeyedSubscript("presetMode")?.call(withArguments: [s])?.toString() ?? "{}")
        return r["mode"] as? String ?? "A"
    }
    struct RemoteJsKindInfo { let kind: String; let supported: Bool; let note: String; let supporters: [String] }
    struct RemoteJsSupport { let kinds: [RemoteJsKindInfo]; let anySupported: Bool }
    func remoteJsSupport(client: String) -> RemoteJsSupport {
        let r = json(api.objectForKeyedSubscript("remoteJsSupport")?.call(withArguments: [client])?.toString() ?? "{}")
        let kinds = (r["kinds"] as? [[String: Any]] ?? []).map { d in
            RemoteJsKindInfo(kind: d["kind"] as? String ?? "", supported: d["supported"] as? Bool ?? false,
                             note: d["note"] as? String ?? "", supporters: d["supporters"] as? [String] ?? [])
        }
        return RemoteJsSupport(kinds: kinds, anySupported: r["anySupported"] as? Bool ?? false)
    }
    struct RemoteJsCheck { let blocked: [String]; let warns: [String] }
    func remoteJsValidate(kind: String, url: String, sha256: String, name: String, mitmHosts: [String], confirmSensitive: Bool) -> RemoteJsCheck {
        let input: [String: Any] = ["kind": kind, "url": url, "sha256": sha256, "name": name, "mitmHosts": mitmHosts, "confirmSensitive": confirmSensitive]
        guard let d = try? JSONSerialization.data(withJSONObject: input), let s = String(data: d, encoding: .utf8) else {
            return RemoteJsCheck(blocked: ["无法序列化"], warns: [])
        }
        let r = json(api.objectForKeyedSubscript("remoteJsValidate")?.call(withArguments: [s])?.toString() ?? "{}")
        return RemoteJsCheck(blocked: r["blocked"] as? [String] ?? [], warns: r["warns"] as? [String] ?? [])
    }
    func remoteJsTemplate(kind: String) -> String {
        let r = json(api.objectForKeyedSubscript("remoteJsTemplate")?.call(withArguments: [kind])?.toString() ?? "{}")
        return r["text"] as? String ?? ""
    }
    func remoteJsLibrary(client: String) -> [[String: Any]] {
        let s = api.objectForKeyedSubscript("remoteJsLibrary")?.call(withArguments: [client])?.toString() ?? "[]"
        return (try? JSONSerialization.jsonObject(with: Data(s.utf8))) as? [[String: Any]] ?? []
    }
    func remoteJsLibraryAttribution(id: String) -> [String: String] {
        let r = json(api.objectForKeyedSubscript("remoteJsLibraryAttribution")?.call(withArguments: [id])?.toString() ?? "{}")
        return ["url": r["url"] as? String ?? "", "text": r["text"] as? String ?? ""]
    }
    func applyPreset(id: String, state: [String: Any]) -> [String: Any]? {
        guard let d = try? JSONSerialization.data(withJSONObject: state), let s = String(data: d, encoding: .utf8) else { return nil }
        let r = json(call("applyPreset", [id, s]))
        if r["error"] != nil { return nil }
        return r
    }
    private func json(_ s: String) -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: Data(s.utf8))) as? [String: Any] ?? [:]
    }
}

struct GenResult {
    var text = ""; var name = ""; var warnings: [String] = []; var error: String? = nil
    init(error: String) { self.error = error }
    init(text: String, name: String, warnings: [String]) { self.text = text; self.name = name; self.warnings = warnings }
}

struct Catalog: Decodable {
    struct Client: Decodable, Identifiable {
        let id: String; let name: String; let family: String; let platforms: [String]
        let blurb: String?; let ext: String?
        let subInConfig: Bool?; let importHint: String?; let processRules: Bool?; let caps: [String]?
        let placement: String?; let howConfig: String?; let howApp: String?; let inApp: [String]?; let conf: String?; let verified: Bool?
        var confLabel: String { conf == "high" ? L("高") : (conf == "medium" ? L("中") : L("低")) }
        var fileExt: String { ext ?? "conf" }
        var embedsSubscription: Bool { subInConfig ?? false }
    }
    struct Platform: Decodable, Identifiable { let id: String; let name: String }
    struct Cap: Decodable, Identifiable { let id: String; let label: String }
    struct Group: Decodable, Identifiable {
        let id: String; let name: String; let cat: String; let def: String
        let defOn: Bool; let risk: String?; let notes: String?; let icon: String?
    }
    struct Region: Decodable, Identifiable { let id: String; let name: String; let icon: String? }
    struct AppEntry: Decodable, Identifiable {
        var id: String { n }; let n: String; let en: String?; let pkg: String?
        var exe: String? = nil
        let bid: String?; let dom: [String]; let g: String?
    }
    let clients: [Client]; let platforms: [Platform]; let capList: [Cap]; let groups: [Group]; let regions: [Region]
    let cats: [String: String]; let apps: [AppEntry]
    static let empty = Catalog(clients: [], platforms: [], capList: [], groups: [], regions: [], cats: [:], apps: [])
}

struct LeakItem: Identifiable {
    let id: String; let group: String; let title: String; let status: String; let why: String; let how: String?
}
struct Carrier: Decodable, Identifiable {
    var id: String { mcc + "-" + mnc }
    let c: String; let cn: String; let n: String; let mcc: String; let mnc: String
    let st: String; let ims: Bool; let extra: [String]
}
