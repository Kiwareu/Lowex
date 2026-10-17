#!/usr/bin/env python3
"""把 Great Vibes 的 "Lowex" 字形轮廓导出为矢量 PDF（App 内字标素材，模板渲染）和 SVG。
App 不再依赖运行时字体注册：首页与启动页都直接用这份矢量。字体 SIL OFL 1.1。
用法：python3 tools/brand/make_wordmark.py"""
import os, cairosvg
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.boundsPen import BoundsPen
ROOT=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
f=TTFont(os.path.join(ROOT,'native/Resources/Fonts/GreatVibes-Regular.ttf'))
gs=f.getGlyphSet(); cmap=f.getBestCmap(); hmtx=f['hmtx']
# 简单排版：逐字前进宽度（含 kern 表时叠加）
x=0; pens=[]
names=[cmap[ord(c)] for c in 'Lowex']
for n in names:
    pens.append((n,x)); x+=hmtx[n][0]
bp=BoundsPen(gs)
for n,ox in pens: gs[n].draw(TransformPen(bp,(1,0,0,1,ox,0)))
x0,y0,x1,y1=bp.bounds
w,h=x1-x0,y1-y0
sp=SVGPathPen(gs)
for n,ox in pens:
    # 翻转 y，平移到左上角
    gs[n].draw(TransformPen(sp,(1,0,0,-1,ox-x0,y1)))
d=sp.getCommands()
svg=f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w:.1f} {h:.1f}" width="{w:.1f}" height="{h:.1f}"><path d="{d}" fill="#000"/></svg>'
open(os.path.join(ROOT,'docs/brand/lowex-wordmark.svg'),'w').write(svg)
cairosvg.svg2pdf(bytestring=svg.encode(),write_to=os.path.join(ROOT,'native/Resources/Assets.xcassets/WordmarkScript.imageset/wordmark.pdf'))
print('aspect',w/h)
