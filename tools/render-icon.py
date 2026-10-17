#!/usr/bin/env python3
"""从 docs/brand/lowex-icon.svg 渲染 App 图标与应用内字标：需要 cairosvg、Pillow。"""
import io, os, cairosvg
from PIL import Image, ImageDraw
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
svg = open(os.path.join(root, 'docs/brand/lowex-icon.svg'), 'rb').read()
big = Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg, output_width=2048, output_height=2048))).convert('RGBA')
A = os.path.join(root, 'native/Resources/Assets.xcassets')
big.resize((1024, 1024), Image.LANCZOS).convert('RGB').save(os.path.join(A, 'AppIcon.appiconset/icon-1024.png'))
m = Image.new('L', (2048, 2048), 0); ImageDraw.Draw(m).rounded_rectangle([0, 0, 2047, 2047], radius=int(2048 * 0.2237), fill=255)
br = big.copy(); br.putalpha(m)
for n in (120, 180, 512): br.resize((n, n), Image.LANCZOS).save(os.path.join(A, f'BrandMark.imageset/brand-{n}.png'))
