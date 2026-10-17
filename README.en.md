# Lowex

<img src="docs/brand/lowex-icon-rounded-1024.png" width="120" align="right">

**Language:** [简体中文](README.md) · [繁體中文](README.zh-Hant.md) · English

> A fully on-device proxy-config generator for Windows / iOS / Android clients — native SwiftUI iOS app (iOS 18+).

**⚠️ Read [DISCLAIMER.md](DISCLAIMER.md) first.** Lowex provides no nodes or subscriptions and does not encourage anything that breaks local law.

> The author's GitHub account was renamed from `wenxu184` to **Kiwareu**; the repo now lives at https://github.com/Kiwareu/Lowex. All addresses in this project use the new name.

## Features
- **Three platforms**: pick Windows / iOS / Android, then a client; output only contains rules valid for that platform.
- **14 clients**: Clash Verge Rev, FlClash, Clash Mi, Clash Meta for Android, Mihomo Party, Mihomo core, sing-box, Karing, Surge, Quantumult X, Shadowrocket, Loon, Stash, Egern — see [docs/CLIENTS.md](docs/CLIENTS.md).
- **75 service groups**: AI, streaming, social, development, banks, cross-border accounts, remote work, brokers, digital-nomad tools, crypto and more.
- **Failover** per region (manual / auto speed-test / fallback), **anti-leak** (fake-ip DNS, sniffing, QUIC / STUN blocking, optional ad / tracker blocking).
- **Manual nodes** (SOCKS5 / HTTP / HTTPS), passwords kept in the Keychain; presets; export by copy / share / Files / QR code / URL scheme.
- **Languages (v1.6.0)**: 简体中文, 繁體中文 (Taiwan), 繁體中文 (Hong Kong) and English. Follows the system language by default; switch in *More → Language*, applied immediately. See [docs/LOCALIZATION.md](docs/LOCALIZATION.md). Generated config text and policy-group names stay in Chinese regardless of UI language.
- **Network environment (v1.7.0)**: sourced recommendations by carrier / network type / location (mainland DoH, bootstrap DNS, IPv6, MTU, QUIC); sources and confidence in [docs/NETWORK-ENV.md](docs/NETWORK-ENV.md).
- **Privacy**: everything runs on-device; no servers, no analytics.

## Install
Download the latest `Lowex-native.ipa` from [Releases](../../releases) (**unsigned**), then install with TrollStore or sign it yourself (AltStore, Sideloadly…). Requires iOS 18+.

## Build
```
cd engine && npm install && npm run build      # produces native/Resources/engine.js
cd ../native && brew install xcodegen && xcodegen generate
xcodebuild -project LowexNative.xcodeproj -scheme LowexNative -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO
python3 tools/check-i18n.py                     # localization tables sanity check
```
Or run the *Build Lowex IPA* GitHub Action.

## Versioning
Current **v1.8.1** (the Home screen shows `v1.8 (build 20)`). See [CHANGELOG.md](CHANGELOG.md).

## Credits
Generated configs only *reference* public resources by URL (MetaCubeX/meta-rules-dat, blackmatrix7/ios_rule_script, SagerNet, ACL4SSR, various icon repos); follow their licenses. Client and service names and trademarks belong to their owners.
