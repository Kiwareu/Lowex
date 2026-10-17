import numpy as np, math
from PIL import Image,ImageDraw,ImageFilter,ImageFont
S=2;N=1024*S
def tx(p): return ((512+0.86*(p[0]-512))*S,(540+0.86*(p[1]-440))*S)
def tail(f):
    A=(800+40*f,262-45*f);T=(A[0]+70+10*f,A[1]+95+25*f)
    return [(766,330-45*f),(A[0]-45,A[1]),A,(A[0]+60,A[1]),(T[0]+15,T[1]-70),T]
def chain(fl,fr):
    R=tail(fr);L=[(1024-x,y) for x,y in tail(fl)]
    segs=[]
    segs.append([L[5],L[4],L[3],L[2]]);segs.append([L[2],L[1],L[0],(262,350)])
    segs.append([(262,350),(275,500),(315,712),(385,708)])
    segs.append([(385,708),(450,704),(500,500),(555,370)])
    segs.append([(555,370),(605,270),(575,215),(515,218)])   # ends at loop top
    segs.append([(515,218),(455,222),(420,330),(475,405)])
    segs.append([(475,405),(505,480),(560,700),(640,708)])
    segs.append([(640,708),(710,712),(750,500),(762,350)])
    segs.append([(762,350),R[0],R[1],R[2]]);segs.append([R[2],R[3],R[4],R[5]])
    return segs
def sample(segs,n=160):
    pts=[];split=None
    for i,sg in enumerate(segs):
        for k in range(n):
            t=k/n;a,b,c,d=[np.array(tx(p)) for p in sg]
            pts.append((1-t)**3*a+3*(1-t)**2*t*b+3*(1-t)*t*t*c+t**3*d)
        if i==4: split=len(pts)
    pts.append(np.array(tx(segs[-1][3])));return np.array(pts),split
def stamp(pts,widths,sl=None):
    m=Image.new('L',(N,N),0);d=ImageDraw.Draw(m)
    idx=range(len(pts)) if sl is None else range(*sl)
    for i in idx:
        r=widths[i]/2*S;x,y=pts[i];d.ellipse([x-r,y-r,x+r,y+r],fill=255)
    return m
def shift(im,dx,dy): return im.transform((N,N),Image.AFFINE,(1,0,-dx,0,1,-dy))
def smooth(t): return t*t*(3-2*t)
def widths(n,W0):
    s=np.linspace(0,1,n);w=W0*(1+0.055*np.sin(2*np.pi*3.3*s+1.0)+0.03*np.sin(2*np.pi*7*s))
    e=np.minimum(s,1-s)/0.07;w*=0.86+0.14*np.clip(smooth(np.clip(e,0,1)),0,1);return w
def blobs(base,bl):
    yy,xx=np.mgrid[0:N,0:N];xx=xx/N;yy=yy/N;out=np.zeros((N,N,3))+np.array(base,float)
    for cx,cy,r,col,al in bl:
        d=np.sqrt((xx-cx)**2+(yy-cy)**2)/r;a=(np.clip(1-d,0,1)**1.2*al)[...,None];out=out*(1-a)+np.array(col)*a
    return Image.fromarray(out.astype('uint8')).convert('RGBA')
BGS={
 'A':((255,128,185),[(0.05,0.98,0.8,(154,107,255),1),(1,1,0.75,(255,176,138),1),(0.35,0.5,0.6,(255,105,173),1),(0.95,0.12,0.7,(183,156,255),1),(0.1,0.08,0.75,(255,201,224),1),(0.8,0.5,0.5,(120,170,255),.7)]),
 'warm':((255,150,140),[(0.05,0.05,0.8,(255,205,215),1),(0.95,0.95,0.8,(255,150,80),1),(0.9,0.1,0.7,(255,120,190),.9),(0.1,0.95,0.7,(200,120,255),.8)]),
 'cream':((255,244,248),[(0.05,0.05,0.8,(255,214,230),1),(0.95,0.1,0.7,(224,208,255),1),(0.95,0.95,0.7,(255,214,190),1)]),
 'night':((40,22,84),[(0.1,0.9,0.8,(130,60,200),1),(0.9,0.1,0.8,(70,90,220),.9),(0.5,0.5,0.6,(200,70,160),.55),(0.95,0.95,0.6,(255,120,110),.6)]),
}
def globe(img):
    o=Image.new('RGBA',(N,N),0);d=ImageDraw.Draw(o);c=(512*S,540*S);R=372*S
    d.ellipse([c[0]-R,c[1]-R,c[0]+R,c[1]+R],fill=(255,255,255,24))
    for rx in (130,260):
        r=rx*S;d.ellipse([c[0]-r,c[1]-R,c[0]+r,c[1]+R],outline=(255,255,255,40),width=7*S)
    for dy in (-190,0,190): d.line([c[0]-R,c[1]+dy*S,c[0]+R,c[1]+dy*S],fill=(255,255,255,40),width=7*S)
    clip=Image.new('L',(N,N),0);ImageDraw.Draw(clip).ellipse([c[0]-R,c[1]-R,c[0]+R,c[1]+R],fill=255)
    o2=Image.new('RGBA',(N,N),0);o2.paste(o,(0,0),clip)
    d2=ImageDraw.Draw(o2);d2.ellipse([c[0]-R,c[1]-R,c[0]+R,c[1]+R],outline=(255,255,255,80),width=10*S)
    return Image.alpha_composite(img,o2)
def sparkle(img,cx,cy,R,col=(255,255,255,240)):
    o=Image.new('RGBA',(N,N),0);d=ImageDraw.Draw(o);pts=[]
    for k in range(8):
        a=math.pi/4*k-math.pi/2;rad=R if k%2==0 else R*0.25;pts.append((cx*S+rad*S*math.cos(a),cy*S+rad*S*math.sin(a)))
    d.polygon(pts,fill=col);return Image.alpha_composite(img,o)
def lerp(a,b,t): return tuple(a[i]*(1-t)+b[i]*t for i in range(3))
def gradimg(stops,mode):
    yy,xx=np.mgrid[0:N,0:N];t=((xx+yy)/(2*N)) if mode=='diag' else yy/N
    t=np.clip((t-0.18)/0.64,0,1)[...,None];out=np.zeros((N,N,3))
    k=len(stops)-1;pos=t*k
    for i in range(k):
        m=((pos>=i)&(pos<=i+1))
        tt=np.clip(pos-i,0,1);seg=np.array(stops[i])*(1-tt)+np.array(stops[i+1])*tt;out=np.where(m,seg,out)
    return Image.fromarray(out.astype('uint8')).convert('RGBA')
def render(name,bg,fill,fl,fr,glob=True,spark=True,W0=76,alpha=.9,shadow=(90,26,110),spark_pos=(885,125),dark=False):
    img=blobs(*BGS[bg])
    if glob: img=globe(img)
    segs=chain(fl,fr);pts,split=sample(segs);w=widths(len(pts),W0)
    M=stamp(pts,w)
    U=stamp(pts,w,(0,split));D=stamp(pts,w,(split,len(pts)))
    ov=np.minimum(np.array(U),np.array(D)).astype(float)/255
    jx,jy=pts[split];yy,xx=np.mgrid[0:N,0:N];far=(np.sqrt((xx-jx)**2+(yy-jy)**2)>120*S)
    ov=ov*far
    # also exclude start/other joints: only loop crossing region (y of crossing)
    ov=Image.fromarray((ov*255).astype('uint8')).filter(ImageFilter.GaussianBlur(2*S))
    # shadow
    sh=shift(M.filter(ImageFilter.GaussianBlur(14*S)),0,22*S)
    shl=Image.new('RGBA',(N,N),shadow+(0,));shl.putalpha(sh.point(lambda v:int(v*(0.38 if not dark else 0.5))))
    img=Image.alpha_composite(img,shl)
    # glow
    gl=M.filter(ImageFilter.GaussianBlur(26*S));glc=Image.new('RGBA',(N,N),(255,255,255,0));glc.putalpha(gl.point(lambda v:int(v*0.30)))
    if not dark: img=Image.alpha_composite(img,glc)
    # ink body
    body=fill.copy();body.putalpha(M.point(lambda v:int(v*alpha)))
    # overlap darkening: second layer of ink only where overlapped (multiply feel)
    arr=np.array(body).astype(float);o=np.array(ov).astype(float)/255
    arr[...,:3]=arr[...,:3]*(1-0.20*o[...,None])+np.array((235,95,165))*0.20*o[...,None]*0.5
    arr[...,3]=np.clip(arr[...,3]+ (255-arr[...,3])*0.6*o,0,255)
    body=Image.fromarray(arr.astype('uint8'))
    img=Image.alpha_composite(img,body)
    # soft glossy rim (no center line): top-left inner edge
    # highlight = M minus M shifted down-right, blurred => lit upper-left edge
    sft=shift(M,14*S,18*S)
    hl=np.clip(np.array(M).astype(float)-np.array(sft).astype(float),0,255)
    hl=Image.fromarray(hl.astype('uint8')).filter(ImageFilter.GaussianBlur(7*S))
    hlc=Image.new('RGBA',(N,N),(255,255,255,0));hlc.putalpha(Image.fromarray((np.array(hl).astype(float)*0.55*(np.array(M)>0)).astype('uint8')) if not dark else hl.point(lambda v:int(v*0.25)))
    img=Image.alpha_composite(img,hlc)
    # lower soft inner shade (pooled ink) on bottom edge
    sft2=shift(M,-12*S,-18*S)
    ed=np.clip(np.array(M).astype(float)-np.array(sft2).astype(float),0,255)
    ed=Image.fromarray(ed.astype('uint8')).filter(ImageFilter.GaussianBlur(8*S))
    edc=Image.new('RGBA',(N,N),(150,60,140,0));edc.putalpha(ed.point(lambda v:int(v*0.16)))
    img=Image.alpha_composite(img,edc)
    if spark: img=sparkle(img,*spark_pos,60,(255,255,255,240) if not dark else (190,90,170,230))
    out=img.convert('RGB').resize((1024,1024),Image.LANCZOS);out.save(f'{name}-1024.png');return out
PINK=[(255,150,200),(170,120,255),(255,140,110)]
G=gradimg([(255,255,255),(255,240,247),(255,205,230)],'v')
GRAD=gradimg(PINK,'diag')
GRAD2=gradimg([(255,95,170),(150,90,255),(255,125,95)],'diag')
DARK=gradimg([(210,60,140),(120,70,220),(230,100,90)],'diag')
specs=[
 ('opt1',dict(bg='A',fill=G,fl=.9,fr=.9,glob=True,spark=True,alpha=.92)),
 ('opt2',dict(bg='cream',fill=GRAD,fl=1.0,fr=1.0,glob=False,spark=True,alpha=.9,spark_pos=(885,125),dark=True)),
 ('opt3',dict(bg='cream',fill=DARK,fl=.8,fr=.8,glob=True,spark=False,alpha=.9,dark=True)),
 ('opt4',dict(bg='warm',fill=G,fl=1.2,fr=1.2,glob=False,spark=True,alpha=.92)),
 ('opt5',dict(bg='night',fill=GRAD2,fl=.7,fr=1.2,glob=True,spark=True,alpha=.92,dark=True,spark_pos=(885,125))),
 ('opt6',dict(bg='A',fill=G,fl=.6,fr=.6,glob=False,spark=False,alpha=.9)),
]
if __name__=='__main__':
    outs=[]
    for n,k in specs: outs.append(render(n,**k))
    lab=['1 白玻璃马克笔·经纬+星光','2 渐变马克笔·奶油底','3 深色渐变·浅底(反色)','4 白玻璃·暖橙底','5 渐变·夜紫底(左小右大)','6 白玻璃·极简']
    f=ImageFont.truetype('',22) if __import__('os').path.exists('/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc') else ImageFont.load_default()
    sheet=Image.new('RGB',(3*430+20,2*(560)+20),(246,244,250));d=ImageDraw.Draw(sheet)
    def rr(im,s):
        m=Image.new('L',(s*4,s*4),0);ImageDraw.Draw(m).rounded_rectangle([0,0,s*4-1,s*4-1],radius=int(s*4*.2237),fill=255);m=m.resize((s,s),Image.LANCZOS)
        t=im.resize((s,s),Image.LANCZOS).convert('RGBA');t.putalpha(m);return t
    for i,im in enumerate(outs):
        x=20+(i%3)*430;y=20+(i//3)*560
        t=rr(im,300);sheet.paste(t,(x,y),t);d.text((x,y+310),lab[i],font=f,fill=(60,40,80))
        xx=x
        for s in (120,60,40):
            t=rr(im,s);sheet.paste(t,(xx,y+360),t);xx+=s+20
        d.text((x,y+500),'120 / 60 / 40 pt',font=f,fill=(120,100,140))
    sheet.save('options2-sheet.png');sheet.save('sheet-view3.png')
