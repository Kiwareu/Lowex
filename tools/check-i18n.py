#!/usr/bin/env python3
"""检查本地化表：python3 tools/check-i18n.py [Lang 目录或解包后的 .app 目录]
1) 三份表 key 集合一致、占位符个数一致；
2) 源码里所有 L("…") 的中文 key 都在每份表里（缺 key = 该语言界面会回落成简体）；
3) 译文里不能残留中文（English 表）；繁体表不能残留明显的简体字。
"""
import sys, re, json, glob, os
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
target = sys.argv[1] if len(sys.argv) > 1 else os.path.join(root, 'native/Resources/Lang')
if os.path.isdir(os.path.join(target, 'Lang')): target = os.path.join(target, 'Lang')
HAN = re.compile(r'[\u4e00-\u9fff]')
tables = {n: json.load(open(os.path.join(target, n + '.json'), encoding='utf8')) for n in ('en', 'zh-Hant-TW', 'zh-Hant-HK')}
bad = 0
base = set(tables['en'])
for n, t in tables.items():
    if set(t) != base: print(f'[{n}] key 集合与 en 不一致', len(set(t) ^ base)); bad += 1
    for k, v in t.items():
        if k.count('{}') != v.count('{}'): print(f'[{n}] 占位符不一致: {k[:30]}'); bad += 1
# 源码 L("…") 提取（简化：只处理不含插值的字面量；插值 \(x) 记为 {}）
src = ''
for f in glob.glob(os.path.join(root, 'native/Sources/*.swift')):
    if f.endswith(('IconCache.swift', 'Lang.swift')): continue
    src += open(f, encoding='utf8').read() + '\n'
keys = set()
for m in re.finditer(r'(?<![A-Za-z0-9_])L\(\s*"((?:[^"\\]|\\.)*)"', src):
    k = re.sub(r'\\\([^)]*\)', '{}', m.group(1)).replace('\\"', '"').replace('\\n', '\n')
    if HAN.search(k): keys.add(k)
miss = {n: [k for k in keys if k not in t] for n, t in tables.items()}
for n, m in miss.items():
    for k in m[:20]: print(f'[{n}] 缺 key:', k)
    bad += len(m)
print('Swift L() keys:', len(keys), '| 表条目:', {n: len(t) for n, t in tables.items()})
# English 译文不应含汉字（允许少量固定词：节点名关键词 / 地区示例）
allow = re.compile(r'回国|中国|上海|北京|一键代理|大陆')
for k, v in tables['en'].items():
    if HAN.search(re.sub(allow, '', v)): print('[en] 译文含汉字:', k[:30], '->', v[:50]); bad += 1
simp = re.compile('[们这么个为时来过对说还进动实现关开经应发见长问间机当没无头边让给让点话书车东门马鸟鱼龙网络软设订阅码户啓]')
for n in ('zh-Hant-TW', 'zh-Hant-HK'):
    for k, v in tables[n].items():
        if simp.search(v): print(f'[{n}] 疑似残留简体:', v[:40]); bad += 1
print('OK' if bad == 0 else f'问题数: {bad}')
sys.exit(1 if bad else 0)
