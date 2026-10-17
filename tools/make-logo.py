# 生成 App 图标与应用内字标：python3 tools/make-logo.py（需要 Pillow）；输出 icon-1024.png / brand-*.png
from PIL import Image, ImageDraw, ImageFilter
import math
S=4096  # supersample
def mesh(size):
    im=Image.new('RGB',(size,size),(255,150,200))
    blobs=[((0.15,0.1),(255,196,222),0.75),((0.9,0.15),(170,140,255),0.7),((0.1,0.95),(150,110,255),0.8),
           ((0.95,0.95),(255,176,140),0.7),((0.5,0.5),(255,105,170),0.7),((0.75,0.45),(120,170,255),0.45)]
    base=Image.new('RGB',(size,size),(255,128,185))
    for (cx,cy),col,r in blobs:
        m=Image.new('L',(size//8,size//8),0);d=ImageDraw.Draw(m)
        R=r*size/8/1.6
        px,py=cx*size/8,cy*size/8
        d.ellipse([px-R,py-R,px+R,py+R],fill=255)
        m=m.filter(ImageFilter.GaussianBlur(size/8*0.16)).resize((size,size),Image.BICUBIC)
        base=Image.composite(Image.new('RGB',(size,size),col),base,m.point(lambda v:int(v*0.85)))
    return base
def glyph(size,color,width,dx=0,dy=0,alpha=255):
    lay=Image.new('RGBA',(size,size),(0,0,0,0));d=ImageDraw.Draw(lay)
    s=size/1024
    # L: vertical stem with soft rounded corner into a base that sweeps up-right (like a flowing 'L' + tail)
    x0,y0=317*s+dx,252*s+dy; yb=742*s+dy; x1=645*s+dx; rad=120*s
    pts=[]
    pts.append((x0,y0)); pts.append((x0,yb-rad))
    for i in range(0,31):
        a=math.pi*(i/30)/2
        pts.append((x0+rad-rad*math.cos(a), yb-rad+rad*math.sin(a)))
    pts.append((x1,yb))
    w=width*s
    dense=[]
    for (ax,ay),(bx,by) in zip(pts,pts[1:]):
        n=max(2,int(math.hypot(bx-ax,by-ay)/(w*0.04))+1)
        for i in range(n+1): dense.append((ax+(bx-ax)*i/n,ay+(by-ay)*i/n))
    for p in dense:
        d.ellipse([p[0]-w/2,p[1]-w/2,p[0]+w/2,p[1]+w/2],fill=color+(alpha,))
    # spark (4-point star) top-right
    cx,cy=667*s+dx,330*s+dy; R=88*s; r=20*s
    star=[]
    for i in range(8):
        a=math.pi/4*i-math.pi/2; rr=R if i%2==0 else r
        star.append((cx+rr*math.cos(a),cy+rr*math.sin(a)))
    d.polygon(star,fill=color+(alpha,))
    return lay
def render(size=1024,rounded=False):
    base=mesh(size) if False else mesh(size)
    im=base.convert('RGBA')
    # soft shadow
    g=glyph(size,(120,40,120),96,0,18,110).filter(ImageFilter.GaussianBlur(size*0.018))
    im=Image.alpha_composite(im,g)
    # ghost offset stroke for depth
    im=Image.alpha_composite(im,glyph(size,(255,255,255),96,-26*size/1024,-18*size/1024,95))
    im=Image.alpha_composite(im,glyph(size,(255,255,255),96,0,0,255))
    # top highlight
    hl=Image.new('RGBA',(size,size),(255,255,255,0));hd=ImageDraw.Draw(hl)
    hd.ellipse([-size*0.2,-size*0.75,size*1.2,size*0.35],fill=(255,255,255,38))
    hl=hl.filter(ImageFilter.GaussianBlur(size*0.03))
    im=Image.alpha_composite(im,hl)
    if rounded:
        m=Image.new('L',(size,size),0);ImageDraw.Draw(m).rounded_rectangle([0,0,size-1,size-1],radius=int(size*0.2237),fill=255)
        im.putalpha(m)
    return im
big=render(2048)
icon=big.resize((1024,1024),Image.LANCZOS).convert('RGB')
icon.save('icon-1024.png')
br=render(2048,True)
for n in (120,180,512): br.resize((n,n),Image.LANCZOS).save(f'brand-{n}.png')
print('ok')
