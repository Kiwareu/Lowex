import Foundation
import JavaScriptCore

/// 生成引擎 = 网页版同一份 TypeScript 引擎（engine.js），在 JavaScriptCore 运行。界面原生，规则逻辑不重写。
final class Engine {
    static let shared = Engine()
    private let ctx = JSContext()!
    private var api: JSValue

    private init() {
        ctx.exceptionHandler = { _, e in NSLog("Lowex JS error: %@", e?.toString() ?? "?") }
        let url = Bundle.main.url(forResource: "engine", withExtension: "js")!
        let src = try! String(contentsOf: url, encoding: .utf8)
        ctx.evaluateScript(src)
        api = ctx.objectForKeyedSubscript("Lowex")
    }

    var version: String { api.objectForKeyedSubscript("version").toString() }

    private func call(_ name: String, _ args: [Any]) -> String {
        api.objectForKeyedSubscript(name).call(withArguments: args)?.toString() ?? "{}"
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
            return GenResult(error: "方案无法序列化")
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
    func presets() -> [[String: Any]] {
        (try? JSONSerialization.jsonObject(with: Data(call("presets", []).utf8))) as? [[String: Any]] ?? []
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
