"""Reuse only an exact-input, passed-timing, byte-verified local release."""
from pathlib import Path
import hashlib
def reusable(state,previous,inputs,bit):
 try:
  t=state["timing_ns"];bit=Path(bit)
  return (state["status"]=="routed_timing_passed" and previous==inputs
   and t["SWNS"]>=0 and t["HWNS"]>=0 and t["STNS"]==t["HTNS"]==0
   and Path(state["bitstream"]).resolve()==bit.resolve() and bit.is_file()
   and hashlib.sha256(bit.read_bytes()).hexdigest()==state["bitstream_sha256"])
 except (KeyError,TypeError,OSError,ValueError):return False
