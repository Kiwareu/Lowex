# Lowex

**語言 / Language：** [簡體中文](README.md) · 繁體中文 · [English](README.en.md)



> **賬號改名說明**：作者的 GitHub 賬號已由 `wenxu184` 改名為 **Kiwareu**，倉庫現在位於 https://github.com/Kiwareu/Lowex 。舊連結會被 GitHub 自動重定向，但本專案內的所有地址已更新為新名。

> 本機生成的代理配置工具 · iOS 原生 SwiftUI · 支援 Windows / iOS / Android 三個目標平臺
>
> A fully on-device proxy-config generator for Windows / iOS / Android clients, built with SwiftUI.

**⚠️ 使用前請閱讀 [DISCLAIMER.md](DISCLAIMER.md)。** Lowex 不提供任何節點或訂閱，也不鼓勵任何違反當地法律的行為。

## 功能 / Features
- **三平臺**：先選 Windows / iOS / Android，再選客戶端；輸出只含該平臺有效的規則（Windows 僅 `.exe` 程序名，Android 僅包名，iOS 無程序 / 包名）。
- **14 個客戶端**：Clash Verge Rev、FlClash、Clash Mi、Clash Meta for Android、Mihomo Party、Mihomo 核心、sing-box、Karing、Surge、Quantumult X、Shadowrocket、Loon、Stash、Egern。詳見 [docs/CLIENTS.md](docs/CLIENTS.md)。
- **75 個服務分組**：AI、流媒體、社交、開發、銀行（滙豐、香港虛擬銀行、新加坡銀行）、跨境賬戶、遠端工作、券商、數字遊民工具、加密貨幣等；預設可選關閉。
- **故障轉移**：每個地區「手動 / 自動測速 / 故轉」。
- **防洩漏**：fake-ip DNS、嗅探、QUIC / STUN 攔截、廣告 / 追蹤 / 遙測攔截（可選）。
- **手動節點**：SOCKS5 / HTTP / HTTPS（住宅 / 家寬代理），密碼存鑰匙串，按客戶端語法輸出，詳見 [docs/MANUAL-NODES.md](docs/MANUAL-NODES.md)。
- **輸入體驗**：節點頁訂閱 URL、節點連結 / Base64、手動節點三塊分開；鍵盤「完成」按鈕、點空白收起、滾動收起；全域性觸感反饋（可在外觀裡關閉）。
- **一鍵預設**：數字遊民、加密貨幣、通用防洩漏等。
- **匯出**：複製、系統分享、儲存到「檔案」、二維碼；多數客戶端支援 URL scheme 匯入（見 [docs/IMPORT-SCHEMES.md](docs/IMPORT-SCHEMES.md)）。
- **外觀**：淺色 / 深色 / 跟隨系統、強調色、圓角、玻璃強度、漸變速度、字型、自定義桌布；啟動動畫和生成成功煙花（遵守「減弱動態效果」）。
- **多語言（v1.6.0）**：介面支援 簡體中文 / 繁體中文（臺灣）/ 繁體中文（香港）/ English；預設跟隨系統語言，也可在「更多 → 語言」裡切換，立即生效。詳見 [docs/LOCALIZATION.md](docs/LOCALIZATION.md)。生成的配置正文與策略組名稱保持中文，不隨介面語言變化。
- **隱私**：全部在本機執行，無伺服器、無統計。

## 截圖 / Screenshots
| 首頁 Home | 規則 Rules |
|---|---|
| <img src="docs/screenshots/home.png" width="260"> | <img src="docs/screenshots/rules.png" width="260"> |

> 截圖來自早期構建；當時配置名稱未跟隨客戶端自動變化，v1.0.0 已修復。

## 安裝 / Install
從 [Releases](../../releases) 下載最新版 `Lowex-native.ipa`；安裝後請核對首頁頂部小字的版本與 build 是否與 Release 一致（**未簽名**）。
- **TrollStore**：用 TrollStore 開啟 / 分享 IPA 安裝（需要受支援的 iOS 版本）。
- **自行簽名**：用你自己的證書 / 側載工具（AltStore、Sideloadly 等）簽名後安裝。
- 系統要求：iOS 18+。作者在 iPhone XS（iOS 18.3.1 + TrollStore）上測試。

## 使用 / Usage
1. **首頁**：選系統與客戶端，選網路環境，按需套用預設。
2. **節點**：貼上你自己的節點 / 訂閱（Shadowrocket 的節點在 App 內新增，配置裡不含節點）。
3. **規則**：開關服務分組，設定出口，可按 App / 域名 / Wi-Fi 通話分流。
4. **生成**：生成並匯出；若有自己的 https 託管地址，可使用一鍵匯入。

## 從原始碼構建 / Build
```
cd engine && npm install && npm run build      # 生成 native/Resources/engine.js
cd ../native && brew install xcodegen && xcodegen generate
xcodebuild -project LowexNative.xcodeproj -scheme LowexNative -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO
```
或直接執行 GitHub Actions 的 *Build Lowex IPA*（macOS runner，輸出未簽名 IPA）。

## 版本 / Versioning
版本號與 GitHub tag 一致：當前 **v1.6.0**（App 首頁顯示 `v1.6 (build 17)`）。舊的內部 3.6 版本線記為 v1.0.x，見 [CHANGELOG.md](CHANGELOG.md)。

## FAQ
- **為什麼沒有節點 / 訂閱？** 本工具不提供任何節點，只整理你自己的。
- **一鍵匯入為什麼要填連結？** URL scheme 無法攜帶本地整份檔案，需要一個 https 直鏈；否則請用分享或「儲存到檔案」。
- **Shadowrocket 的訂閱為什麼不在配置裡？** 它的節點與訂閱儲存在 App 首頁，配置檔案只含規則與策略組。
- **Quantumult X 能一鍵匯入嗎？** 官方 scheme 僅支援資源片段，請複製 / 分享後手動匯入。
- **iOS 能按 App 分流嗎？** 不能（沒有程序 / 包名規則），Lowex 會改用服務組或域名。

## 致謝與資料來源 / Credits
Lowex 只在生成的配置裡**引用**以下公開資源的 URL，不在本倉庫內分發其內容；請遵循各自的許可：
- [MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat)（GPL-3.0）
- [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script)（GPL-2.0）
- [SagerNet/sing-geosite / sing-geoip](https://github.com/SagerNet)
- [ACL4SSR/ACL4SSR](https://github.com/ACL4SSR/ACL4SSR)（CC BY-SA 4.0）
- 圖示：Koolson/Qure、lige47/QuanX-icon-rule、luestr/IconResource、Semporia/Hand-Painted-icon、Orz-3/mini（這些倉庫未宣告明確許可證，僅在執行時按 URL 下載，圖示版權歸原作者）
- 各客戶端與服務的名稱、商標歸其所有者。

## 許可 / License
[MIT](LICENSE)（僅適用於本倉庫自有程式碼；第三方資源見上）。聯絡：wenx@xewol.com


## 圖示

全部服務組 / 地區 / 特殊組圖示（共 97 張）都已重繪並內建進 App（v1.5.1），同時放在（見 [Lowex-Icons](https://github.com/Kiwareu/Lowex-Icons) 的 contact-sheet.png）。核對結果見 [docs/ICONS-TODO.md](docs/ICONS-TODO.md)；補充圖示放在 [Lowex-Icons](https://github.com/Kiwareu/Lowex-Icons)，上傳後 App 啟動時自動採用。
