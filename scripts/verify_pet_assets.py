"""Reproduce palette image data from supplied originals without changing RTL/build inputs."""
from pathlib import Path
import hashlib,json,re
from PIL import Image
R=Path(__file__).resolve().parents[1];H=R/'user_source/hdl_source';sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
manifest=json.loads((R/'reports/pet_asset_manifest.json').read_text(encoding='utf-8'));sheet=Image.new('RGB',(192,72))
for k,n in enumerate(['neutral','happy','nervous','rice']):
 p=R/'assets/pets'/(n+'.png');assert sha(p)==manifest[n]['sha256'];sheet.paste(Image.open(p).convert('RGB').resize((48,72),Image.Resampling.LANCZOS),(k*48,0))
q=sheet.quantize(colors=16,method=Image.Quantize.MEDIANCUT);indices=[0]*16384
for k in range(4):indices[k*4096:k*4096+3456]=list(q.crop((k*48,0,(k+1)*48,72)).getdata())
assert indices==[int(v,16) for v in (H/'pet_pixels.hex').read_text().split()]
p=q.getpalette();pal={int(i):int(c,16) for i,c in re.findall(r"4'd(\d+):O_rgb<=24'h([0-9a-f]+)",(H/'adv_pet_rom.v').read_text())}
assert all(pal[i]==(p[3*i]<<16)|(p[3*i+1]<<8)|p[3*i+2] for i in range(16))
gold=[int(v,16) for v in (R/'validation/pet_expected.hex').read_text().split()];assert gold==[pal[v] for v in indices]
result=dict(status='passed',original_sha256=True,reproduced_sprite_indices=len(indices),palette_colours=16,golden_pixels=len(gold),scope='Exact supplied PNG -> deterministic shared palette -> ROM/golden data; no original edits')
(R/'reports/pet_asset_verification.json').write_text(json.dumps(result,indent=2));print(result)
