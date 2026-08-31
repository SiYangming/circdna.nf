#!/usr/bin/env python
"""Patch CRESIL identify_wgls strand comparison bug.

CRESIL identify_wgls compares trim_sup['strand'] to '+'/'-' but CRESIL
trim writes numeric -1/1 (mappy convention), so both splits are empty and
the downstream genomecov table is empty (KeyError: 'name').

The module file in site-packages is read-only inside the container, so we
copy it next to the module and shadow it via PYTHONPATH. This script
performs the in-place replacement on the copy.
"""
import pathlib
import sys

target = pathlib.Path(sys.argv[1])
src = target.read_text()
src = src.replace("trim_sup['strand'] == '+'", "trim_sup['strand'] == 1")
src = src.replace("trim_sup['strand'] == '-'", "trim_sup['strand'] == -1")
target.write_text(src)
print(f"patched {target}")
