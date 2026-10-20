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

// —— Web 对象补齐（URL / URLSearchParams / atob / btoa / TextEncoder / TextDecoder）——
// 引擎的节点链接解析（nodes.ts：new URL / URLSearchParams / atob）与 sing-box
// DNS 生成（singbox.ts 的 dohServer：new URL）依赖这些对象。浏览器都有；裸
// JavaScriptCore 不保证提供，缺失时引擎的 try/catch 会静默降级——节点链接解
// 析不出、DoH 服务器写成 type:udp + 完整网址（过不了官方 sing-box check）。
// 这里与 crypto 同模式：只在缺失时补齐，语义对齐 WHATWG 常用子集，保证引擎
// 在任何运行时生成逐字节一致的结果；宿主已有原生实现时不覆盖。
if (typeof atob === 'undefined' || typeof btoa === 'undefined') {
  var __b64c = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  var __b64r = {}; for (var __bi = 0; __bi < 64; __bi++) __b64r[__b64c[__bi]] = __bi;
  if (typeof atob === 'undefined') {
    globalThis.atob = function (s) {
      s = String(s).replace(/[\t\n\f\r ]/g, '');
      if (s.length % 4 === 1) throw new Error('atob: invalid length');
      while (s.length % 4) s += '=';
      var out = '';
      for (var i = 0; i < s.length; i += 4) {
        var c0 = s[i], c1 = s[i + 1], c2 = s[i + 2], c3 = s[i + 3];
        if (!(c0 in __b64r) || !(c1 in __b64r) || (c2 !== '=' && !(c2 in __b64r)) || (c3 !== '=' && !(c3 in __b64r))) throw new Error('atob: invalid character');
        var n = (__b64r[c0] << 18) | (__b64r[c1] << 12) | ((c2 === '=' ? 0 : __b64r[c2]) << 6) | (c3 === '=' ? 0 : __b64r[c3]);
        out += String.fromCharCode((n >> 16) & 0xff);
        if (c2 !== '=') out += String.fromCharCode((n >> 8) & 0xff);
        if (c3 !== '=') out += String.fromCharCode(n & 0xff);
      }
      return out;
    };
  }
  if (typeof btoa === 'undefined') {
    globalThis.btoa = function (s) {
      s = String(s); var out = '';
      for (var i = 0; i < s.length; i += 3) {
        var a = s.charCodeAt(i), hb = i + 1 < s.length, hc = i + 2 < s.length;
        var b = hb ? s.charCodeAt(i + 1) : 0, c = hc ? s.charCodeAt(i + 2) : 0;
        if (a > 0xff || b > 0xff || c > 0xff) throw new Error('btoa: character out of range');
        var n = (a << 16) | (b << 8) | c;
        out += __b64c[(n >> 18) & 63] + __b64c[(n >> 12) & 63] + (hb ? __b64c[(n >> 6) & 63] : '=') + (hc ? __b64c[n & 63] : '=');
      }
      return out;
    };
  }
}
if (typeof TextEncoder === 'undefined') {
  globalThis.TextEncoder = function () {};
  globalThis.TextEncoder.prototype.encode = function (s) {
    s = String(s == null ? '' : s); var out = [];
    for (var i = 0; i < s.length; i++) {
      var cp = s.codePointAt(i); if (cp > 0xffff) i++;
      if (cp >= 0xd800 && cp <= 0xdfff) cp = 0xfffd;
      if (cp < 0x80) out.push(cp);
      else if (cp < 0x800) out.push(0xc0 | (cp >> 6), 0x80 | (cp & 0x3f));
      else if (cp < 0x10000) out.push(0xe0 | (cp >> 12), 0x80 | ((cp >> 6) & 0x3f), 0x80 | (cp & 0x3f));
      else out.push(0xf0 | (cp >> 18), 0x80 | ((cp >> 12) & 0x3f), 0x80 | ((cp >> 6) & 0x3f), 0x80 | (cp & 0x3f));
    }
    return new Uint8Array(out);
  };
}
if (typeof TextDecoder === 'undefined') {
  globalThis.TextDecoder = function () {};
  globalThis.TextDecoder.prototype.decode = function (buf) {
    if (buf == null) return '';
    var b = buf instanceof Uint8Array ? buf : new Uint8Array(buf);
    var out = '', i = 0;
    while (i < b.length) {
      var c = b[i], cp, extra = 0;
      if (c < 0x80) cp = c;
      else if ((c & 0xe0) === 0xc0) { cp = c & 0x1f; extra = 1; }
      else if ((c & 0xf0) === 0xe0) { cp = c & 0x0f; extra = 2; }
      else if ((c & 0xf8) === 0xf0) { cp = c & 0x07; extra = 3; }
      else cp = 0xfffd;
      if (extra) {
        var ok = true;
        for (var j = 1; j <= extra; j++) {
          if (i + j >= b.length || (b[i + j] & 0xc0) !== 0x80) { ok = false; break; }
          cp = (cp << 6) | (b[i + j] & 0x3f);
        }
        if (!ok) cp = 0xfffd; else i += extra;
      }
      out += String.fromCodePoint(cp); i++;
    }
    return out;
  };
}
if (typeof URLSearchParams === 'undefined') {
  var __uspDec = function (s) { try { return decodeURIComponent(s.replace(/\+/g, ' ')); } catch (e) { return s; } };
  var __uspEnc = function (s) { return encodeURIComponent(s).replace(/%20/g, '+'); };
  globalThis.URLSearchParams = function (init) {
    this.__pairs = [];
    if (init == null) return;
    var str = String(init);
    if (str.charAt(0) === '?') str = str.slice(1);
    if (!str) return;
    var parts = str.split('&');
    for (var i = 0; i < parts.length; i++) {
      if (!parts[i]) continue;
      var eq = parts[i].indexOf('=');
      if (eq < 0) this.__pairs.push([__uspDec(parts[i]), '']);
      else this.__pairs.push([__uspDec(parts[i].slice(0, eq)), __uspDec(parts[i].slice(eq + 1))]);
    }
  };
  globalThis.URLSearchParams.prototype.get = function (name) {
    for (var i = 0; i < this.__pairs.length; i++) if (this.__pairs[i][0] === name) return this.__pairs[i][1];
    return null;
  };
  globalThis.URLSearchParams.prototype.getAll = function (name) {
    var r = []; for (var i = 0; i < this.__pairs.length; i++) if (this.__pairs[i][0] === name) r.push(this.__pairs[i][1]); return r;
  };
  globalThis.URLSearchParams.prototype.has = function (name) { return this.get(name) !== null; };
  globalThis.URLSearchParams.prototype.toString = function () {
    return this.__pairs.map(function (p) { return __uspEnc(p[0]) + '=' + __uspEnc(p[1]); }).join('&');
  };
}
if (typeof URL === 'undefined') {
  globalThis.URL = function (url) {
    var s = String(url);
    var m = /^([A-Za-z][A-Za-z0-9+.-]*):/.exec(s);
    if (!m) throw new TypeError('URL: invalid URL: ' + s);
    this.protocol = m[1].toLowerCase() + ':';
    var rest = s.slice(m[0].length);
    this.username = ''; this.password = ''; this.hostname = ''; this.port = '';
    this.pathname = ''; this.search = ''; this.hash = '';
    var hi = rest.indexOf('#'); if (hi >= 0) { this.hash = rest.slice(hi); rest = rest.slice(0, hi); }
    var qi = rest.indexOf('?'); if (qi >= 0) { this.search = rest.slice(qi); rest = rest.slice(0, qi); }
    if (rest.slice(0, 2) === '//') {
      var body = rest.slice(2);
      var si = body.indexOf('/');
      var authority = si >= 0 ? body.slice(0, si) : body;
      this.pathname = si >= 0 ? body.slice(si) : '/';
      var at = authority.lastIndexOf('@');
      var hostport = authority;
      if (at >= 0) {
        var ui = authority.slice(0, at); hostport = authority.slice(at + 1);
        var ci = ui.indexOf(':');
        if (ci >= 0) { this.username = ui.slice(0, ci); this.password = ui.slice(ci + 1); } else this.username = ui;
      }
      if (hostport.charAt(0) === '[') {
        var cb = hostport.indexOf(']');
        this.hostname = hostport.slice(0, cb + 1).toLowerCase();
        if (hostport.charAt(cb + 1) === ':') this.port = hostport.slice(cb + 2);
      } else {
        var cp2 = hostport.lastIndexOf(':');
        if (cp2 >= 0 && /^\d*$/.test(hostport.slice(cp2 + 1))) { this.hostname = hostport.slice(0, cp2).toLowerCase(); this.port = hostport.slice(cp2 + 1); }
        else this.hostname = hostport.toLowerCase();
      }
      var defPort = { 'http:': '80', 'https:': '443', 'ws:': '80', 'wss:': '443', 'ftp:': '21' };
      if (defPort[this.protocol] === this.port) this.port = '';
      if (/^0+\d/.test(this.port)) this.port = String(parseInt(this.port, 10));
    } else {
      this.pathname = rest;
    }
    this.searchParams = new globalThis.URLSearchParams(this.search);
    this.href = s;
    this.host = this.hostname + (this.port ? ':' + this.port : '');
    this.origin = 'null';
  };
  globalThis.URL.prototype.toString = function () { return this.href; };
}
