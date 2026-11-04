"""Fresh TD implementation; promote a bitstream only after routed timing passes."""
from pathlib import Path
import argparse,hashlib,json,os,re,shutil,subprocess,tempfile,time
ROOT=Path(__file__).resolve().parents[1]
ASCII_ROOT=Path(os.environ.get('FPGA_STAGE_ROOT','D:/FPGA_HX1P35A/_work'))
parser=argparse.ArgumentParser()
parser.add_argument('--fresh',action='store_true',help='Ignore a valid exact-source cache')
parser.add_argument('--td',default=os.environ.get('TD_EXE',r'D:\Anlogic\TD_6.2.1_Engineer_6.2.168.116\bin\td_commands_prompt.exe'))
parser.add_argument('--stage-root',type=Path,default=ASCII_ROOT)
args=parser.parse_args();sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
sim=json.loads((ROOT/'reports/simulation_results.json').read_text())
assert {k for k in sim if k.startswith('tb_')}=={p.stem for p in (ROOT/'sim').glob('tb_*.sv')},'Run full regression first'
for n,v in sim['rtl_sha256'].items():assert sha(ROOT/'user_source/hdl_source'/n)==v,n
for n,v in sim['test_sha256'].items():assert sha(ROOT/'sim'/n)==v,n
for n,v in sim['asset_sha256'].items():assert sha(ROOT/n)==v,n
for n,v in sim['reference_sha256'].items():assert sha(ROOT/'scripts'/n)==v,n
for n,v in sim['simulation_model_sha256'].items():assert sha(ROOT/'sim'/n)==v,n
assert str(args.stage_root.resolve()).isascii(),'Build stage path must be ASCII'
inputs={p.relative_to(ROOT).as_posix():sha(p) for p in (ROOT/'user_source').rglob('*') if p.is_file()}
for n in ['td_project/basic_sc520.al','td_project/basic_sc520.sdc','td_project/logo_low4.dath','td_project/pet_pixels.hex','td_project/logo_compact.hex','scripts/implement.tcl','scripts/cached_build.py','scripts/build.py','scripts/build_extension.py']:inputs[n]=sha(ROOT/n)
reports=ROOT/'reports';target=ROOT/'release/pet_advanced_v4.bit'
assert sha(ROOT/'td_project/logo_low4.dath')==sha(ROOT/'user_source/hdl_source/logo_low4.dath')
for n in ['pet_pixels.hex','logo_compact.hex']:assert sha(ROOT/'td_project'/n)==sha(ROOT/'user_source/hdl_source'/n),n
from cached_build import reusable
if not args.fresh and (reports/'build_status.json').is_file() and (reports/'build_inputs.json').is_file():
 old=json.loads((reports/'build_status.json').read_text());previous=json.loads((reports/'build_inputs.json').read_text())
 if reusable(old,previous,inputs,target):
  old['cache_hit']=True;old['cache_verification']='exact input hashes, positive setup/hold, zero TNS, exact target path and bit SHA256'
  (reports/'build_status.json').write_text(json.dumps(old,indent=2));print('EXACT_BUILD_CACHE_HIT: no synthesis/place/route executed');raise SystemExit(0)
previous_target_sha=sha(target) if target.is_file() else None

args.stage_root.mkdir(parents=True,exist_ok=True)
stage=Path(tempfile.mkdtemp(prefix='anlu_ext_build_',dir=args.stage_root))
for name in ['user_source','td_project']:
    shutil.copytree(ROOT/name,stage/name,ignore=shutil.ignore_patterns('*_Runs','implementation','*.log','*.logw','*.dmp'))
for p in (ROOT/'user_source/hdl_source').glob('*.hex'):shutil.copy2(p,stage/'td_project'/p.name)
project=stage/'td_project/basic_sc520.al';s=project.read_text(encoding='utf-8')
s=re.sub(r'(<Project[^>]*\bPath=")[^"]*',lambda m:m[1]+(stage/'td_project').as_posix(),s)
project.write_text(s,encoding='utf-8')
shutil.copy2(ROOT/'scripts/implement.tcl',stage/'td_project/build.tcl')
reports=ROOT/'reports';destination=ROOT/'td_project/implementation';destination.mkdir(exist_ok=True)
(reports/'build_inputs.json').write_text(json.dumps(inputs,indent=2),encoding='utf-8')
state={'path':str(stage),'status':'running','sram_download':'not performed','flash_programming':'not performed'}
def save():
    (reports/'build_status.json').write_text(json.dumps(state,indent=2),encoding='utf-8')
save();print('TD build stage:',stage,flush=True);start=time.time()
try:
    with (reports/'build_console.log').open('wb') as log:
        result=subprocess.run([args.td,'build.tcl'],cwd=stage/'td_project',stdout=log,stderr=subprocess.STDOUT,
                              creationflags=subprocess.CREATE_NO_WINDOW)
    state['exit_code']=result.returncode
    for p in (stage/'td_project').iterdir():
        if p.is_file() and p.suffix in {'.area','.ts','.timing','.txt','.log','.logw','.bit','.bin'}:
            shutil.copy2(p,destination/p.name)
    console=(reports/'build_console.log').read_text(encoding='utf-8',errors='replace')
    assert result.returncode==0 and 'BASIC_BUILD_FINISHED' in console,'TD did not complete; see build_console.log'
    timing=(destination/'basic_sc520_pr.timing').read_text(encoding='utf-8',errors='replace')
    values={n:float(re.search(r'\b'+n+r':\s*(-?[\d.]+)ns',timing)[1]) for n in ['SWNS','STNS','HWNS','HTNS']}
    state['timing_ns']=values
    state['placed_preflight']=re.search(r'V23_PREFLIGHT slice=(\d+) eram=(\d+)',console).groups()
    m=re.search(r'V23_ROUTE_MS (\d+)',console);state['route_seconds']=int(m[1])/1000 if m else None
    state['sta_coverage']=re.search(r'STA coverage\s*:\s*([^\n]+)',timing)[1].strip()
    assert re.search(r'Confidence\s*:\s*Routed',timing),'Final routed report required'
    assert values['SWNS']>=0 and values['HWNS']>=0 and values['STNS']==0 and values['HTNS']==0,'Timing failed: no release'
    assert all(sha(ROOT/n)==v for n,v in inputs.items()),'Build inputs changed'
    bit=stage/'td_project/basic_sc520.bit';assert bit.is_file(),'No bitstream'
    target=ROOT/'release/pet_advanced_v4.bit'
    assert (sha(target) if target.is_file() else None)==previous_target_sha,'Existing release changed during build'
    if previous_target_sha is not None:
        backup=ASCII_ROOT/('pet_v4_release_backup_'+time.strftime('%Y%m%d_%H%M%S')+'_'+previous_target_sha[:8])
        backup.mkdir(parents=True,exist_ok=False);shutil.copy2(target,backup/target.name)
        assert sha(backup/target.name)==previous_target_sha
        state['previous_release_backup']=str(backup)
    shutil.copy2(bit,target.with_suffix('.bit.pending'));target.with_suffix('.bit.pending').replace(target)
    state.update(status='routed_timing_passed',bitstream=str(target),bitstream_sha256=sha(target))
except Exception as exc:
    state.update(status='failed',reason=str(exc));raise
finally:
    state['elapsed_seconds']=round(time.time()-start,1);save();print(json.dumps(state,indent=2),flush=True)
