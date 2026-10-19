<p align="center">
  <img src="docs/brand/lowex-icon-rounded-1024.png" width="128" alt="Lowex">
</p>

<h1 align="center">Lowex</h1>

<p align="center">
  On-device proxy &amp; routing config generator for iPhone and iPad · SwiftUI + TypeScript · nothing is uploaded
</p>

<p align="center">
  <a href="https://github.com/Kiwareu/Lowex/releases/latest"><img alt="release" src="https://img.shields.io/github/v/release/Kiwareu/Lowex"></a>
  <img alt="platform" src="https://img.shields.io/badge/iOS-15%2B-pink">
  <a href="LICENSE"><img alt="license" src="https://img.shields.io/github/license/Kiwareu/Lowex"></a>
</p>

<p align="center">
  <a href="README.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a> · <b>English</b>
</p>

> **Please read [DISCLAIMER.md](DISCLAIMER.md) first.** Lowex provides no nodes, subscriptions or network access, and does not encourage anything that violates local law.

## About

Lowex runs on iPhone / iPad. Pick a target client and options, paste *your own* nodes or subscription, and export a config file (rules, policy groups, DNS, leak protection) that fits that client. Everything is generated on the device — there is no server, and nodes or subscriptions are never uploaded.

## Features

- **14 clients**: Clash Verge Rev, FlClash, Clash Mi, Clash Meta for Android, Mihomo Party, Mihomo core, sing-box, Karing, Surge, Quantumult X, Shadowrocket, Loon, Stash, Egern.
- **Per-platform output**: choose Windows / iOS / Android first, then the client; the output only contains rules valid on that platform (Windows: `.exe` process names only, Android: package names only, iOS: neither).
- **75 service groups**: AI, streaming, social, dev, banks and brokers, cross-border accounts, remote work, digital-nomad tools, crypto and more — toggle each and pick its exit.
- **Failover**: per region, choose manual / auto speed-test / failover; only the group types each client really supports are generated.
- **Leak protection**: fake-ip DNS, sniffing, QUIC / STUN blocking, optional ad / tracker / telemetry blocking.
- **Network environment**: evidence-based DNS / DoH, bootstrap DNS, IPv6, MTU and QUIC recommendations by carrier, network type and location (see [docs/NETWORK-ENV.md](docs/NETWORK-ENV.md)).
- **Manual nodes**: SOCKS5 / HTTP / HTTPS (residential proxies); passwords stay in the system Keychain; output follows each client's syntax (see [docs/MANUAL-NODES.md](docs/MANUAL-NODES.md)).
- **Presets, backup & restore**: digital-nomad, crypto and general leak-protection presets; settings export to JSON and restore.
- **Export**: copy, system share sheet, save to Files, QR code; most clients support URL-scheme import (see [docs/IMPORT-SCHEMES.md](docs/IMPORT-SCHEMES.md)).
- **UI**: script-style wordmark, light / dark, accent colour, corner radius, glass strength, gradient speed, fonts, custom wallpaper, haptics, list density on the Rules page (single / two columns / compact); honours Reduce Motion.
- **Languages**: Simplified Chinese, Traditional Chinese (Taiwan, Hong Kong) and English; follows the system language and can be switched in the app (see [docs/LOCALIZATION.md](docs/LOCALIZATION.md)).

## Screenshots

| Home | Rules |
|---|---|
| <img src="docs/screenshots/home.png" width="260"> | <img src="docs/screenshots/rules.png" width="260"> |

> Screenshots show v1.3; v1.4 adds list density on the Rules page, so details may differ.

## Supported clients

| Client | Platforms | Export | Nodes / subscriptions |
|---|---|---|---|
| Clash Verge Rev / Mihomo Party | Windows · macOS · Linux | `.yaml` | in config, or added in the app |
| FlClash | Windows · macOS · Linux · Android | `.yaml` | in config, or added in the app |
| Clash Mi | iOS · Android · Windows · macOS | `.yaml` | in config, or added in the app |
| Clash Meta for Android | Android | `.yaml` | in config, or added in the app |
| Mihomo core | Linux · Windows · macOS · Android | `.yaml` | in config |
| sing-box | Windows · macOS · Linux · Android · iOS | `.json` | in config |
| Karing | iOS · Android · Windows · macOS | `.json` | in config |
| Surge | iOS · macOS | `.conf` | in config |
| Quantumult X | iOS | `.conf` | in config, or added in the app |
| Shadowrocket | iOS · macOS | `.conf` | in config, or added in the app |
| Loon | iOS | `.conf` | in config |
| Stash | iOS · macOS | `.yaml` | in config |
| Egern | iOS · macOS | `.yaml` | in config |

Per-client research, confidence levels and primary sources: [docs/CLIENTS.md](docs/CLIENTS.md).

## Platform support

- **Device running Lowex**: iPhone / iPad on **iOS 15.0 or later** (comparable to sing-box and Karing; sources in [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md)).
- **Configs target**: clients on Windows / macOS / Linux / Android / iOS.
- The author tests on iOS 18. iOS 15–17 have been compile-verified only, not tested on devices per version — please open an issue if something breaks.

## How it works

- Everything runs locally: no server, and nodes, subscriptions or results are never uploaded. The only network requests are the optional App Store search (iTunes Search API) and rule icons (bundled, with optional extras from a public icon repo).
- The UI is written in **SwiftUI**; the generation engine is **TypeScript**, bundled as `engine.js` and run in the system's **JavaScriptCore**.
- The engine trims options to each client's capability matrix, and outputs are regression-tested with the clients' own validators (mihomo `-t`, `sing-box check`).

## Install

> Lowex is not on the App Store. It ships as an **unsigned IPA**.

1. Download the latest `Lowex-vX.Y.Z.ipa` from [Releases](https://github.com/Kiwareu/Lowex/releases) (the `.sha256` file next to it verifies integrity).
2. Install with either:
   - **TrollStore**: on supported systems (officially iOS 14.0–16.6.1, 16.7 RC and 17.0), open the IPA with TrollStore.
   - **Sign / sideload yourself**: AltStore, Sideloadly, Feather, etc., using your own Apple ID or certificate.
3. Verify: `shasum -a 256 -c Lowex-vX.Y.Z.ipa.sha256`.

## Usage

1. **Home**: pick system and client, choose the network environment, apply a preset if you like.
2. **Nodes**: paste your own nodes / subscription; for clients that allow it, choose "Write to config" or "Add in client".
3. **Rules**: toggle service groups and exits; route by app, domain or Wi-Fi Calling.
4. **Generate**: copy, share, save to Files, scan the QR code, or import with a URL scheme.

## Build from source

Requires macOS, Xcode and Node.js.

```bash
cd engine && npm install && npm run build       # writes native/Resources/engine.js
cd ../native && brew install xcodegen && xcodegen generate
xcodebuild -project LowexNative.xcodeproj -scheme LowexNative -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO
```

> The canonical Bundle ID is `com.wenx.lowex` (see `PRODUCT_BUNDLE_IDENTIFIER` in `native/project.yml`); the old `com.wenx.lowex.native` is no longer used.

Or run the *Build Lowex IPA* GitHub Action (macOS runner, unsigned IPA).

## Validation & testing

- Engine output is checked with `mihomo -t` and `sing-box check`, plus fuzzing over random option combinations (IPv6 / TUN / fake-ip / failover / ad blocking / STUN / QUIC …).
- `python3 tools/check-i18n.py` verifies the four UI language tables are complete.
- Compilation is verified by CI on a macOS runner; there are no automated UI tests.

## Contributing

Issues and PRs are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md). Never paste nodes, subscription URLs or tokens in issues.

## Security

Report vulnerabilities through GitHub's *Security → Report a vulnerability* (private advisory); see [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE) (covers this repository's own code only). The bundled Great Vibes font is under SIL OFL 1.1 ([docs/brand/OFL-GreatVibes.txt](docs/brand/OFL-GreatVibes.txt)). Third-party rule and icon sources are listed below.

## Disclaimer

Lowex is not affiliated with, authorised or endorsed by any client, service, bank or platform mentioned; all names and trademarks belong to their owners. The software is provided “as is” without warranty; the authors and contributors accept no liability for its use. It was developed and tested with AI assistance and may still contain errors — verify the generated results yourself. Comply with the laws that apply in your jurisdiction — see [DISCLAIMER.md](DISCLAIMER.md).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) and [Releases](https://github.com/Kiwareu/Lowex/releases).

## Acknowledgements & data sources

Lowex only **references** the URLs of these public resources in generated configs and does not redistribute their content; follow their licences:

- [MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat) (GPL-3.0)
- [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script) (GPL-2.0)
- [SagerNet/sing-geosite / sing-geoip](https://github.com/SagerNet)
- [ACL4SSR/ACL4SSR](https://github.com/ACL4SSR/ACL4SSR) (CC BY-SA 4.0)
- Icons were redrawn with reference to community icon sets (Koolson/Qure, lige47/QuanX-icon-rule, luestr/IconResource, Semporia/Hand-Painted-icon, Orz-3/mini); brand marks belong to their owners and are used only to identify the service. See also [Lowex-Icons](https://github.com/Kiwareu/Lowex-Icons).
- Font: [Great Vibes](https://github.com/googlefonts/great-vibes) (SIL OFL 1.1).
