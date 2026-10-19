// JavaScriptCore 没有 crypto / URL 以外的浏览器对象：只补引擎用到的
// 安全要求（9.8+ 升级）：crypto.getRandomValues 必须来自原生 SecRandomCopyBytes
// 注入的 __lowexSecureRandom（见 native/Sources/Engine.swift installSecureRandom）。
// 没有可信随机源时直接抛错，绝不回退 Math.random —— 可预测的随机数会让
// 生成的 external-controller secret 可被猜到，比直接报错更危险。
if (typeof crypto === 'undefined') {
  globalThis.crypto = {
    getRandomValues: function (a) {
      if (typeof __lowexSecureRandom !== 'function') {
        throw new Error('Lowex: no trusted random source (native SecRandomCopyBytes injection missing); refusing to use Math.random');
      }
      var out = __lowexSecureRandom(a.length);
      if (!out || out.length !== a.length) {
        throw new Error('Lowex: native secure random failed');
      }
      for (var i = 0; i < a.length; i++) a[i] = out[i] & 0xff;
      return a;
    }
  };
}
if (typeof navigator === 'undefined') { globalThis.navigator = { userAgent: 'JavaScriptCore' }; }
if (typeof window === 'undefined') { globalThis.window = globalThis; }
