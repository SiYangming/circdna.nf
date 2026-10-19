#!/usr/bin/env python
"""Apply a string replacement to a CRESIL module source file.

The cresil 1.2.1 container ships inconsistent column names across subcommands
(e.g. identify writes `consensus_status` while annotate reads
`eccdna_status`). site-packages is read-only in the container, so modules
copy the package into a writable dir and call this helper to patch it in
place before shadowing via PYTHONPATH.

By default the old string is matched as a substring. Pass `--line` to
match whole lines (leading indentation included), which is useful when the
same substring appears at multiple indentation levels but only one of them
should change.

Usage: patch_cresil.py [--line] <file.py> '<old>' '<new>'
"""
import pathlib
import sys


def main() -> None:
    args = sys.argv[1:]
    line_mode = False
    if args and args[0] == "--line":
        line_mode = True
        args = args[1:]
    if len(args) != 3:
        sys.exit("usage: patch_cresil.py [--line] <file.py> '<old>' '<new>'")
    target = pathlib.Path(args[0])
    old, new = args[1], args[2]
    src = target.read_text()

    if line_mode:
        lines = src.split("\n")
        if old not in lines:
            sys.exit(f"error: line not found in {target}: {old!r}")
        src = "\n".join(new if line == old else line for line in lines)
    else:
        if old not in src:
            sys.exit(f"error: pattern not found in {target}: {old!r}")
        src = src.replace(old, new)

    target.write_text(src)
    print(f"patched {target}: {old!r} -> {new!r}")


if __name__ == "__main__":
    main()
