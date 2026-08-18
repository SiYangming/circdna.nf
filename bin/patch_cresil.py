#!/usr/bin/env python
"""Apply a single string replacement to a CRESIL module source file.

The cresil 1.2.1 container ships inconsistent column names across subcommands
(e.g. identify writes `consensus_status` while annotate reads
`eccdna_status`). site-packages is read-only in the container, so modules
copy the package into a writable dir and call this helper to patch it in
place before shadowing via PYTHONPATH.

Usage: patch_cresil.py <file.py> '<old>' '<new>'
"""
import pathlib
import sys


def main() -> None:
    if len(sys.argv) != 4:
        sys.exit("usage: patch_cresil.py <file.py> '<old>' '<new>'")
    target = pathlib.Path(sys.argv[1])
    old, new = sys.argv[2], sys.argv[3]
    src = target.read_text()
    if old not in src:
        sys.exit(f"error: pattern not found in {target}: {old!r}")
    target.write_text(src.replace(old, new))
    print(f"patched {target}: {old!r} -> {new!r}")


if __name__ == "__main__":
    main()
