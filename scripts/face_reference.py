"""Independent XML/NumPy LBP cascade reference. No RTL imports.
OpenCV model uses 24x24 block-LBP, categorical membership selects left leaf.
Scaled rectangular features are an FPGA approximation, not OpenCV's image pyramid.
"""
from pathlib import Path
import xml.etree.ElementTree as ET
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
SCALES=(4,5,6,7,8,10,12,14)
WINDOWS=tuple(24*s//4 for s in SCALES)
ORDER=(0,1,2,5,8,7,6,3)

def load_model(profile=False):
    x=ET.parse(ROOT/('models/lbpcascade_profileface.xml' if profile else 'models/lbpcascade_frontalface.xml')).getroot().find('cascade')
    features=[tuple(map(int,f.findtext('rect').split())) for f in x.find('features')]
    stages=[];nodes=[]
    for s in x.find('stages'):
        for w in s.find('weakClassifiers'):
            ns=list(map(int,w.findtext('internalNodes').split()))
            assert ns[:2]==[0,-1] and len(ns)==11
            leaves=tuple(map(float,w.findtext('leafValues').split()))
            nodes.append((features[ns[2]],tuple(v&0xffffffff for v in ns[3:]),leaves))
        stages.append((len(nodes),float(s.findtext('stageThreshold'))-1e-5))
    assert (len(nodes),len(stages))==((130,16) if profile else (139,20))
    return stages,nodes

def integral(a):return np.pad(np.asarray(a,dtype=np.int64).cumsum(0).cumsum(1),((1,0),(1,0)))

def detect(a, fixed=True, stride=2, trace=False, profile=False, mirror=False, mirror_y=False, phase=(0,0)):
    a=np.asarray(a,dtype=np.uint8);h,w=a.shape;ii=integral(a)
    stages,nodes=load_model(profile);hits=[];traces=[];evals=0
    for si,scale in enumerate(SCALES):
        win=(34 if profile else 24)*scale//4;nominal_width=(20 if profile else 24)*scale//4
        extent=max(((fx*scale+2)//4)+3*((fw*scale+2)//4) for (fx,fy,fw,fh),_,_ in nodes)
        ey=max(((fy*scale+2)//4)+3*((fh*scale+2)//4) for (fx,fy,fw,fh),_,_ in nodes)
        # Hardware reserves a conservative 3-pixel halo for fractional scaling.
        xpad=(win-nominal_width)//2 if profile else 0
        limit_x=max(win,xpad+extent);limit_y=max(win,ey)
        if limit_y>h or limit_x>w:continue
        yy,xx=np.mgrid[phase[1]:h-limit_y+1:stride,phase[0]:w-limit_x+1:stride]
        xs=xx.ravel();ys=yy.ravel();active=np.arange(len(xs));start=0
        for st,(end,threshold) in enumerate(stages):
            if not len(active):break
            scores=np.zeros(len(active),dtype=np.int64 if fixed else np.float64)
            for ni in range(start,end):
                rect,subsets,leaves=nodes[ni];fx,fy,fw,fh=((v*scale+2)//4 for v in rect)
                gx=xs[active]+xpad+(extent-fx-3*fw if mirror else fx);gy=ys[active]+(ey-fy-3*fh if mirror_y else fy)
                cells=[]
                for cy in range(3):
                    for cx in range(3):
                        x0=gx+(2-cx if mirror else cx)*fw;y0=gy+(2-cy if mirror_y else cy)*fh;x1=x0+fw;y1=y0+fh
                        cells.append(ii[y1,x1]+ii[y0,x0]-ii[y0,x1]-ii[y1,x0])
                code=np.zeros(len(active),np.uint8)
                for bit,j in enumerate(ORDER):code|=(cells[j]>=cells[4]).astype(np.uint8)<<(7-bit)
                subset=np.asarray(subsets,dtype=np.uint32)[code>>5]
                member=((subset>>(code&31))&1).astype(bool)
                if fixed:values=np.where(member,round(leaves[0]*4096),round(leaves[1]*4096))
                else:values=np.where(member,leaves[0],leaves[1])
                scores+=values;evals+=len(active)
                if trace:
                    traces.append((si,st,ni,active.copy(),code.copy(),scores.copy()))
            active=active[scores >= (round(threshold*4096) if fixed else threshold)]
            start=end
        hits.extend((int(xs[i]),int(ys[i]),win,si) for i in active)
    return hits,evals,traces

def group(hits):
    # Same scan order, but independently implemented bounded nearest clustering.
    groups=[]
    for x,y,w,si in hits:
        cx=x+w//2;cy=y+w//2
        match=next((g for g in groups if abs(cx-g[0])<=((w+g[2])>>3)+2 and abs(cy-g[1])<=((w+g[2])>>3)+2 and abs(w-g[2])<=(g[2]>>1)),None)
        if match is None:
            if len(groups)<8:groups.append([cx,cy,w,1])
            else:
                j=min(range(8),key=lambda j:groups[j][3])
                if groups[j][3]<=1:groups[j]=[cx,cy,w,1]
        elif match[3]<255:
            match[:3]=[(3*match[j]+v+2)//4 for j,v in enumerate((cx,cy,w))]
            match[3]+=1
    if not groups:return (False,0,0,0,0)
    best=max(groups,key=lambda g:g[3]);cx,cy,w,count=best
    return (count>=3,cx-w//2,cy-w//2,w,count)


def detect_multi(a,fixed=True):
    all_hits=[];evaluations=0;best=(False,0,0,0,0)
    for kind in range(5):
        hits,ev,_=detect(a,fixed,profile=kind!=0,mirror=kind in (2,4),mirror_y=kind in (3,4));evaluations+=ev
        all_hits.extend((kind,*h) for h in hits)
        best=group(hits)
        if best[4]>=5 or kind==4:
            found,x,y,w,v=best
            return all_hits,(found,x,y,w,(min(v,127)|(128 if kind else 0))),evaluations
    raise AssertionError()
