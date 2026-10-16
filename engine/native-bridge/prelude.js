// JavaScriptCore 没有 crypto / URL 以外的浏览器对象：只补引擎用到的
if(typeof crypto==='undefined'){globalThis.crypto={getRandomValues:function(a){for(var i=0;i<a.length;i++)a[i]=Math.floor(Math.random()*256);return a}}}
if(typeof navigator==='undefined'){globalThis.navigator={userAgent:'JavaScriptCore'}}
if(typeof window==='undefined'){globalThis.window=globalThis}
