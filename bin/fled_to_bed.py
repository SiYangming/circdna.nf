#!/usr/bin/env python
"""Convert a FLED junctions file into the unified eccDNA BED contract.

FLED writes per-sample junction files (.DiGraph.OnesegJunction.out and
.DiGraph.MulsegFullJunction.out) whose rows start with:

    chrom  start  end  [count ...]

This script emits BED6+read_count:

    chr  start  end  name  score  strand  read_count

with a header line (read_count auto-detectable by filter_by_read_support.py).
"""
import argparse
import sys


def parse_args():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("junctions", help="FLED junctions file (tab-delimited)")
    p.add_argument("output", help="Output BED6+read_count file")
    return p.parse_args()


BED_HEADER = ["chr", "start", "end", "name", "score", "strand", "read_count"]


def convert(junctions_path, output_path):
    written = 0
    with open(junctions_path) as fin, open(output_path, "w") as fout:
        fout.write("\t".join(BED_HEADER) + "\n")
        for line in fin:
            if not line.strip() or line.startswith("#"):
                continue
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 3:
                continue
            try:
                chrom, start, end = parts[0], int(parts[1]), int(parts[2])
            except ValueError:
                continue
            name = "eccDNA_{}_{}_{}".format(chrom, start, end)
            count = 1
            if len(parts) >= 4:
                try:
                    count = int(parts[3])
                except ValueError:
                    count = 1
            fout.write("{}\t{}\t{}\t{}\t0\t.\t{}\n".format(chrom, start, end, name, count))
            written += 1
    sys.stderr.write("fled_to_bed: wrote {} junction(s) to {}\n".format(written, output_path))


if __name__ == "__main__":
    args = parse_args()
    convert(args.junctions, args.output)
