# 贡献指南 / Contributing

欢迎 PR 与 Issue。

## 结构
- `native/` — SwiftUI 应用（iOS 18+），XcodeGen（`project.yml`）。
- `engine/` — TypeScript 生成引擎，打包为 `native/Resources/engine.js` 并在 JavaScriptCore 中运行。
- `docs/` — 客户端矩阵、导入 scheme 说明。

## 修改规则 / 分组
分组在 `engine/src/data/groups-extra.ts`（`G(id,name,category,default,defaultOn,risk,notes,domains)`），图标在 `engine/src/data/icons.ts`（键 `g:<id>`）。新增域名请先确认官网域名归属，不要提交来源不明的域名。

## 构建引擎
```
cd engine && npm install && npm run build   # 输出 native/Resources/engine.js
```
## 构建 IPA
在 GitHub Actions 运行 *Build Lowex IPA*，或在 macOS：`cd native && xcodegen generate && xcodebuild ...`（见 workflow）。

## 约定
- 不得提交任何真实订阅链接、节点、密码、令牌；不得提交个人参考配置。
- 平台隔离是硬性要求：改动后确认 iOS 输出不含 PROCESS-NAME / 包名，Android 不含 `.exe`，Windows 不含包名。
- 提交信息用英文或中文均可；请使用 GitHub noreply 邮箱。
