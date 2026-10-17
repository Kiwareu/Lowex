#!/usr/bin/env python3
"""Lowex 图标生成：手绘风 W 字标（马克笔质感）+ 暖色渐变底。
用法：python3 tools/brand/make_icon.py        （需要 numpy、Pillow）
输出：AppIcon 1024（全出血 RGB）、BrandMark 120/180/512（圆角 RGBA）、docs/brand/ 下的 PNG 与矢量 SVG。
"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import marker as g2
from marker import S, N

ROOT = os.path.dirname(os.path.dirname(HERE))
# 字标中心线的关键点（草图坐标），Catmull-Rom 平滑
PTS = [(90,455),(170,375),(270,275),(350,180),(388,140),(378,215),(390,310),(420,385),(470,405),(530,385),(580,335),(618,255),(655,170),(645,120),(595,132),(548,205),(555,285),(605,330),(680,330),(760,308),(830,260),(890,195),(925,125),(925,70),(900,45),(868,52),(852,78)]
SPLIT_I = 13   # 环的顶点：从这里把笔画分成两段，用来做交叉处的叠色
K, W0 = 0.96, 74

def cr(pts, n=60):
    P = [pts[0]] + list(pts) + [pts[-1]]; out = []; split = None
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = [np.array(q, float) for q in P[i-1:i+3]]
        if i - 1 == SPLIT_I: split = len(out)
        for k in range(n):
            t = k / n
            out.append(0.5 * ((2*p1) + (-p0+p2)*t + (2*p0-5*p1+4*p2-p3)*t*t + (-p0+3*p1-3*p2+p3)*t**3))
    out.append(np.array(pts[-1], float)); return np.array(out), split

def render():
    arr, split = cr(PTS)
    g2.chain = lambda a, b: None
    g2.sample = lambda segs: (np.stack([(512 + K*(arr[:, 0]-500))*S, (548 + K*(arr[:, 1]-262))*S], 1), split)
    G = g2.gradimg([(255,255,255),(255,240,247),(255,205,230)], 'v')
    return g2.render('/tmp/lowex-icon', bg='warm', fill=G, fl=1, fr=1, glob=False, spark=True, W0=W0, alpha=.92), arr

def svg(arr):
    """矢量版：同一条中心线上盖圆（扁平白色笔画），底为同色径向渐变。"""
    w = g2.widths(len(arr), W0)
    pts = np.stack([512 + K*(arr[:, 0]-500), 548 + K*(arr[:, 1]-262)], 1)
    c = ''.join(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r/2:.1f}"/>' for (x, y), r in list(zip(pts, w))[::3])
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
<defs>
<radialGradient id="a" cx="0.05" cy="0.05" r="0.8"><stop offset="0" stop-color="#ffcdd7"/><stop offset="1" stop-color="#ffcdd7" stop-opacity="0"/></radialGradient>
<radialGradient id="b" cx="0.95" cy="0.95" r="0.8"><stop offset="0" stop-color="#ff9650"/><stop offset="1" stop-color="#ff9650" stop-opacity="0"/></radialGradient>
<radialGradient id="c" cx="0.9" cy="0.1" r="0.7"><stop offset="0" stop-color="#ff78be" stop-opacity="0.9"/><stop offset="1" stop-color="#ff78be" stop-opacity="0"/></radialGradient>
<radialGradient id="d" cx="0.1" cy="0.95" r="0.7"><stop offset="0" stop-color="#c878ff" stop-opacity="0.8"/><stop offset="1" stop-color="#c878ff" stop-opacity="0"/></radialGradient>
</defs>
<rect width="1024" height="1024" fill="#ff968c"/>
<rect width="1024" height="1024" fill="url(#a)"/><rect width="1024" height="1024" fill="url(#b)"/><rect width="1024" height="1024" fill="url(#c)"/><rect width="1024" height="1024" fill="url(#d)"/>
<g fill="#fff" fill-opacity="0.94">{c}</g>
<polygon points="885,65 900,110 945,125 900,140 885,185 870,140 825,125 870,110" fill="#fff" fill-opacity="0.94"/>
</svg>
'''

if __name__ == '__main__':
    img, arr = render()
    A = os.path.join(ROOT, 'native/Resources/Assets.xcassets'); B = os.path.join(ROOT, 'docs/brand')
    img.convert('RGB').save(os.path.join(A, 'AppIcon.appiconset/icon-1024.png')); img.convert('RGB').save(os.path.join(B, 'lowex-icon-1024.png'))
    m = Image.new('L', (4096, 4096), 0); ImageDraw.Draw(m).rounded_rectangle([0, 0, 4095, 4095], radius=int(4096*.2237), fill=255)
    big = img.convert('RGBA').resize((4096, 4096), Image.LANCZOS); big.putalpha(m)
    for n in (120, 180, 512): big.resize((n, n), Image.LANCZOS).save(os.path.join(A, f'BrandMark.imageset/brand-{n}.png'))
    big.resize((1024, 1024), Image.LANCZOS).save(os.path.join(B, 'lowex-icon-rounded-1024.png'))
    open(os.path.join(B, 'lowex-icon.svg'), 'w').write(svg(arr))
    print('ok')
