"""Create a fresh ASCII-path TD GUI project after full RTL regression."""
from pathlib import Path
import argparse,hashlib,json,re,shutil
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--destination',type=Path,default=Path('D:/FPGA_HX1P35A/anlu_pet_v4_gui'))
args=parser.parse_args();gui=args.destination.resolve()
assert str(gui).isascii(),'TD IP tools require an ASCII path'
assert not gui.exists(),'Refusing to overwrite an existing GUI project'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
sim=json.loads((ROOT/'reports/simulation_results.json').read_text())
assert {k for k in sim if k.startswith('tb_')}=={p.stem for p in (ROOT/'sim').glob('tb_*.sv')}
for n,v in sim['rtl_sha256'].items():assert sha(ROOT/'user_source/hdl_source'/n)==v,n
for n,v in sim['test_sha256'].items():assert sha(ROOT/'sim'/n)==v,n
for n,v in sim['asset_sha256'].items():assert sha(ROOT/n)==v,n
for n,v in sim['reference_sha256'].items():assert sha(ROOT/'scripts'/n)==v,n
for n,v in sim['simulation_model_sha256'].items():assert sha(ROOT/'sim'/n)==v,n
shutil.copytree(ROOT/'user_source',gui/'user_source');(gui/'td_project').mkdir()
for n in ['basic_sc520.al','basic_sc520.sdc']:shutil.copy2(ROOT/'td_project'/n,gui/'td_project'/n)
for p in (ROOT/'td_project').iterdir():
    if p.is_file() and p.suffix in ['.hex','.dath']:shutil.copy2(p,gui/'td_project'/p.name)
project=gui/'td_project/basic_sc520.al';s=project.read_text(encoding='utf-8')
s=re.sub(r'(<Project[^>]*\bPath=")[^"]*',lambda m:m[1]+(gui/'td_project').as_posix(),s)
project.write_text(s,encoding='utf-8')
entries=re.findall(r'<File Path="([^"]+)"',s)
for n in entries:
    p=(project.parent/n).resolve();assert p.is_relative_to(gui) and p.is_file(),n
assert any(n.endswith('ext_cartoon_rgb96.v') for n in entries)
inputs={p.relative_to(ROOT).as_posix():sha(p) for p in (ROOT/'user_source').rglob('*') if p.is_file()}
for n,v in inputs.items():assert sha(gui/n)==v,n
(ROOT/'reports/gui_build_inputs.json').write_text(json.dumps({'gui_project':str(project),'source_sha256':inputs,'project_entries':len(entries)},indent=2),encoding='utf-8')
print('Manual TD project:',project)
print('Run fresh synthesis / PHY / bitgen. Routed SWNS/HWNS >= 0, STNS/HTNS = 0 required.')
