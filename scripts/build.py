"""Entry point for the extension build with simulation and timing gates."""
import runpy
from pathlib import Path
runpy.run_path(str(Path(__file__).with_name("build_extension.py")),run_name="__main__")
