"""Reproducible lossless storage for the frozen signed6 main expression model."""
from pathlib import Path
import argparse,heapq,hashlib,json,math
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
FROZEN_MODEL_SHA='9ba73873ddccc247702a592fb9254c8dc76db05f11c9a54b569a1bbb07afa493'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def describe(manifest,meta):
    manifest.update(weights='W1 unchanged signed6 values, lossless neuron-major Huffman stream; W2 signed8 and signed32 accumulators unchanged',weight_storage='lossless_huffman_stream',packed_words=meta['storage_words'],payload_words=meta['payload_words'],weight_layout_file='expression_main_weight_layout.json')
    return manifest

def emit(root=None,write=False):
    root=Path(root) if root else ROOT
    model=root/'models/expression_mlp.npz';assert sha(model)==FROZEN_MODEL_SHA,'Frozen main model changed; model constants and audit must be revised together'
    core=(root/'user_source/hdl_source/ext_expression_core.v').read_text();assert 'main_weight_start' in core and 'main_weight_valid' in core,'Stream core interface required'
    x=np.load(model)['w1'].T.copy();assert x.shape==(32,2016) and x.min()>=-32 and x.max()<=31
    values,counts=np.unique(x,return_counts=True)
    heap=[(int(c),i,('leaf',int(v))) for i,(v,c) in enumerate(zip(values,counts))];heapq.heapify(heap);serial=len(heap)
    while len(heap)>1:
        a=heapq.heappop(heap);b=heapq.heappop(heap);heapq.heappush(heap,(a[0]+b[0],serial,('node',a[2],b[2])));serial+=1
    codes={}
    def visit(node,code):
        if node[0]=='leaf':codes[node[1]]=code;return
        visit(node[1],code+'0');visit(node[2],code+'1')
    visit(heap[0][2],'')
    assert min(map(len,codes.values()))>=1 and max(map(len,codes.values()))<=16
    assert sum(1<<(16-len(v)) for v in codes.values())==65536
    chunks=[''.join(codes[int(v)] for v in row) for row in x];offset=np.cumsum([0]+[len(v) for v in chunks]).tolist();bits=''.join(chunks)
    trie={}
    for v,code in codes.items():
        n=trie
        for b in code:
            assert 'value' not in n;n=n.setdefault(b,{})
        assert not n;n['value']=v
    # Independent prefix walking verifies every original coefficient and every seek.
    for r in range(32):
        n=trie;decoded=[]
        for b in bits[offset[r]:offset[r+1]]:
            n=n[b]
            if 'value' in n:decoded.append(n['value']);n=trie
        assert n is trie and np.array_equal(decoded,x[r]),r
    payload=np.packbits(np.frombuffer(bits.encode('ascii'),dtype=np.uint8)-48).tobytes()
    words=[int(bits[i:i+18].ljust(18,'0'),2) for i in range(0,len(bits),18)];payload_words=len(words);blocks=math.ceil(len(words)/1024);assert blocks<=14
    words+=[0]*(blocks*1024-len(words));nl=chr(10)
    data=nl.join("memory[%d]=18'h%05x;"%(i,v) for i,v in enumerate(words))
    seeks=nl.join("5'd%d: seek=19'h%05x;"%(i,((b//18)<<5)|(b%18)) for i,b in enumerate(offset[:-1]))
    cases=nl.join("16'b%s: begin value_dec=6'h%02x; length_dec=5'd%d; end"%(c+'?'*(16-len(c)),v&63,len(c)) for v,c in sorted(codes.items(),key=lambda a:(len(a[1]),a[0])))
    template_path=root/'models/main_weight_stream_template.v.in';template=template_path.read_text();assert 'reg [15:0] look_reg;' in template and 'casez(look_reg)' in template
    text=template.replace('@LAST_WORD@',str(len(words)-1)).replace('@DATA@',data).replace('@SEEK@',seeks).replace('@CODES@',cases)
    assert '@DATA@' not in text and '@CODES@' not in text
    meta=dict(format='lossless_signed6_huffman_neuron_stream_v1',model_sha256=FROZEN_MODEL_SHA,features=2016,hidden=32,coefficient_count=64512,weight_value_bits=6,quantization_changed=False,payload_bits=len(bits),payload_words=payload_words,storage_words=len(words),eram_blocks=blocks,baseline_fixed6_eram=21,max_code_bits=max(map(len,codes.values())),neuron_bit_offsets=offset,payload_sha256=hashlib.sha256(payload).hexdigest(),generator_sha256=sha(Path(__file__)),template_sha256=sha(template_path),generated_rtl_sha256=hashlib.sha256(text.encode('ascii')).hexdigest(),registered_look=True,protocol='start per neuron; valid/ready coefficient transfer; core waits without camera backpressure',limits='Storage only; numeric model and score policy frozen. Full-board routed timing/resources and hardware camera accuracy require separate verification.')
    rtl=root/'user_source/hdl_source/ext_expression_weights.v';layout=root/'models/expression_main_weight_layout.json';manifest_path=root/'models/expression_model.json';manifest=json.loads(manifest_path.read_text());assert manifest['model_sha256']==FROZEN_MODEL_SHA
    expected_manifest=describe(dict(manifest),meta)
    if write:
        rtl.write_text(text,encoding='ascii');layout.write_text(json.dumps(meta,indent=2),encoding='ascii');manifest_path.write_text(json.dumps(expected_manifest,indent=2),encoding='utf-8')
    else:
        assert rtl.read_text()==text,'Generated weight stream differs from frozen model/template'
        assert json.loads(layout.read_text())==meta,'Weight layout manifest differs'
        assert manifest==expected_manifest,'Main model storage description differs'
    return meta

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--write',action='store_true');a=p.parse_args();m=emit(write=a.write)
    print(json.dumps({k:v for k,v in m.items() if k!='neuron_bit_offsets'},indent=2))
