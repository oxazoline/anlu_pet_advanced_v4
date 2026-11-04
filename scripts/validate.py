"""Run the supplied RTL tests with checksum-verified fixed simulation vectors."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import argparse
import hashlib
import json
import os
import queue
import re
import shutil
import subprocess
import tempfile
import threading
import time

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ['adv_pet_rom.v', 'adv_pet_overlay.v', 'adv_logo_compact.v', 'adv_motion_hold.v', 'adv_auto_exposure.v', 'adv_ref_track.v', 'adv_font_rom.v', 'adv_base_osd.v', 'adv_hand_weights.v', 'adv_ref_rows.v', 'adv_axis_select.v', 'adv_stable_track.v', 'adv_target_hold.v', 'adv_vision.v', 'adv_frame_latency.v', 'adv_overlay.v', 'lane_lvds_10_1.v', 'ext_expression_preview.v', 'ext_expression_weights.v', 'ext_expression_motion.v', 'ext_face_visual_hold.v', 'ext_expression_au_weights.v', 'ext_expression_cue_weights.v', 'ext_expression_cbrow_weights.v', 'ext_expression_core.v', 'ext_expression_capture.v', 'awb.v', 'ext_face_detector.v', 'ext_face_lbp.v', 'ext_face_integral_ram.v', 'ext_face_track.v', 'ext_face_status_cdc.v', 'ext_face_feature_rom.v', 'ext_face_subset_rom.v', 'ext_face_stage_rom.v', 'ext_chroma_scale.v', 'ext_line_ram_rgb96.v', 'anlogic_logo_rom_sync.v', 'isp/demosaic_4x_2_0/zhenghe.v', 'ext_cartoon_rgb96.v', 'basic_status_cdc.v', 'isp/isp_top.v', 'design_top_wrapper.v', 'basic_color_restore.v', 'basic_saturation_keys.v', 'basic_detail_sharpen.v', 'basic_tone_map.v', 'basic_vertical_denoise.v', 'basic_spatial_denoise.v', 'basic_gray_rgb96.v', 'basic_rgb_packer.v', 'basic_osd.v', 'basic_display_startup.v', 'anlogic_logo_rom.v', 'osd_char_lib.v', 'hdmi_mixer.v', 'video_out.v', 'video_in.v', 'basic_fault_counter.v', 'uiisp_beta/ae_set.v', 'uics520_cfg/SC520GainTbl.v', 'uics520_cfg/uics520regAE.v', 'uics520_cfg/uicfgcs520.v', 'uics520_cfg/uics520reg.v', 'uics520_cfg/uics520reg_720p60.v', 'uics520_cfg/uics520reg_full_2560x1920_30.v', 'uics500_cfg/uii2c.v']
SIM_MODELS = ['vendor_eram_sp_model.sv', 'hdmi_oddr_model.sv', 'legacy_lane_lvds.v', 'v21_expression_core_gold.v', 'v21_expression_capture_gold.v', 'v22_expression_core_gold.v', 'v24_expression_core_gold.v', 'v25_expression_core_gold.v']

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    parser = argparse.ArgumentParser(description='RTL regression with supplied fixed vectors')
    parser.add_argument('--stage-root', type=Path, default=Path(os.environ.get('FPGA_STAGE_ROOT', 'D:/FPGA_HX1P35A/_work')))
    parser.add_argument('--modelsim', default=os.environ.get('MODELSIM_BIN', 'D:/modelsim/win32'))
    parser.add_argument('--jobs', type=int, default=4)
    parser.add_argument('--only', nargs='*', help='Test top names for a selected run')
    parser.add_argument('--prepare-only', action='store_true')
    args = parser.parse_args()
    if args.jobs < 1:
        parser.error('--jobs must be positive')
    if not str(args.stage_root.resolve()).isascii():
        parser.error('The simulation stage path must contain ASCII characters only')
    tool = Path(args.modelsim)
    for name in ['vlib.exe', 'vlog.exe', 'vsim.exe']:
        if not (tool/name).is_file():
            parser.error('Missing ModelSim executable: ' + str(tool/name))

    reports = ROOT/'reports'
    reports.mkdir(exist_ok=True)
    args.stage_root.mkdir(parents=True, exist_ok=True)
    stage = Path(tempfile.mkdtemp(prefix='pet_v4_sim_', dir=args.stage_root))
    hdl = ROOT/'user_source/hdl_source'
    vectors = ROOT/'validation'
    fixtures = json.loads((vectors/'fixtures_sha256.json').read_text(encoding='utf-8'))
    for name, digest in fixtures.items():
        source = vectors/name
        assert source.parent == vectors and sha(source) == digest, ('Simulation vector mismatch', name)
        shutil.copy2(source, stage/name)
    for name in SOURCES:
        destination = stage/name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(hdl/name, destination)
    shutil.copy2(hdl/'vtc/uivtc.v', stage/'uivtc.v')
    tests = sorted(p.name for p in (ROOT/'sim').glob('tb_*.sv'))
    for name in tests + SIM_MODELS:
        shutil.copy2(ROOT/'sim'/name, stage/name)
    selected = {Path(n).stem for n in args.only} if args.only else {Path(n).stem for n in tests}
    assert selected <= {Path(n).stem for n in tests}, 'Unknown test name'

    snapshot = {
        'rtl_sha256': {n: sha(hdl/n) for n in SOURCES},
        'test_sha256': {n: sha(ROOT/'sim'/n) for n in tests},
        'simulation_model_sha256': {n: sha(ROOT/'sim'/n) for n in SIM_MODELS},
        'reference_sha256': {p.name: sha(p) for p in (ROOT/'scripts').glob('*.py')},
        'asset_sha256': {p.relative_to(ROOT).as_posix(): sha(p) for folder in ['models', 'assets', 'validation'] for p in (ROOT/folder).rglob('*') if p.is_file()},
        'fixture_sha256': fixtures,
    }
    for n in ['user_source/hdl_source/logo_low4.dath', 'td_project/logo_low4.dath', 'user_source/hdl_source/pet_pixels.hex', 'user_source/hdl_source/logo_compact.hex']:
        snapshot['asset_sha256'][n] = sha(ROOT/n)

    def run(command, cwd, log_name):
        result = subprocess.run(command, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                timeout=600, creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
        text = result.stdout.decode('utf-8', errors='replace')
        (reports/log_name).write_text(text, encoding='utf-8')
        if result.returncode:
            raise RuntimeError(log_name + '\n' + text[-5000:])
        return text

    print('Compiling', len(tests), 'RTL tests; simulation stage:', stage, flush=True)
    run([str(tool/'vlib.exe'), 'work'], stage, 'sim_library.log')
    run([str(tool/'vlog.exe'), '-sv', '-work', 'work', *SOURCES, 'uivtc.v', *SIM_MODELS, *tests], stage, 'sim_compile.log')
    if args.prepare_only:
        prepared = dict(snapshot, stage=str(stage), tests=tests)
        (reports/'fixture_prepare.json').write_text(json.dumps(prepared, indent=2), encoding='utf-8')
        print('ALL_FIXTURES_AND_RTL_PREPARED', stage, flush=True)
        return

    pending = queue.Queue()
    for name in sorted(selected):
        pending.put(name)
    lock = threading.Lock()
    stop = threading.Event()
    results = {}
    start = time.monotonic()
    directories = []
    for i in range(min(args.jobs, len(selected))):
        directory = stage/f'worker{i}'
        directory.mkdir()
        shutil.copytree(stage/'work', directory/'work')
        for name in fixtures:
            try:
                os.link(stage/name, directory/name)
            except OSError:
                shutil.copy2(stage/name, directory/name)
        directories.append(directory)

    def worker(directory):
        while not stop.is_set():
            try:
                top = pending.get_nowait()
            except queue.Empty:
                return
            try:
                text = run([str(tool/'vsim.exe'), '-c', '-onfinish', 'stop', 'work.'+top, '-do',
                            'onerror {quit -code 1}; onbreak {quit -code 1}; run -all; quit -code 0'], directory, top+'.log')
                assert re.search(r'\bPASS(?::|\s)', text) and '** Fatal:' not in text and '** Error:' not in text, top+' failed'
                with lock:
                    results[top] = [line.strip() for line in text.splitlines() if re.search(r'\bPASS(?::|\s)', line)]
                    print(f'PASS {len(results)}/{len(selected)} {top}', flush=True)
            except BaseException:
                stop.set()
                raise

    with ThreadPoolExecutor(max_workers=len(directories)) as executor:
        for result in executor.map(worker, directories):
            pass
    assert set(results) == selected
    for field, directory in [('rtl_sha256', hdl), ('test_sha256', ROOT/'sim'), ('simulation_model_sha256', ROOT/'sim'), ('reference_sha256', ROOT/'scripts')]:
        for name, digest in snapshot[field].items():
            assert sha(directory/name) == digest, ('Input changed during simulation', name)
    for name, digest in snapshot['asset_sha256'].items():
        assert sha(ROOT/name) == digest, ('Asset changed during simulation', name)
    record = dict(sorted(results.items()))
    record.update(snapshot)
    record['parallel_execution'] = {'jobs': len(directories), 'private_work_libraries': True,
                                    'all_tests_rerun': not bool(args.only), 'fixed_vectors_checksum_verified': True,
                                    'elapsed_seconds': round(time.monotonic()-start, 1)}
    filename = 'simulation_results_selected.json' if args.only else 'simulation_results.json'
    (reports/filename).write_text(json.dumps(record, indent=2), encoding='utf-8')
    print('ALL RTL REGRESSIONS PASSED', len(results), flush=True)

if __name__ == '__main__':
    main()
