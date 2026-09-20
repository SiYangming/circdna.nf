#!/usr/bin/env python
"""Annotate eccDNA candidate BED rows with a te_overlap column (repeat annotation).

§4.6: repeats are ANNOTATED, never hard-deleted (no bedtools intersect -v on repeats).

Counts how many repeat intervals (from --repeats BED) overlap each candidate.
Appends a trailing column `te_overlap`. Candidate header lines (e.g. the unified
BED header `chr\tstart\tend\tname\tscore\tstrand\tread_count`) are preserved and
gain a te_overlap header cell.
"""
import argparse
import bisect
import sys


def parse_args():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--candidates", required=True)
    p.add_argument("--repeats", required=True)
    p.add_argument("--out", required=True)
    return p.parse_args()


def load_repeats(path):
    by_chr = {}
    with open(path) as fh:
        for line in fh:
            if not line.strip() or line.startswith("#"):
                continue
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 3:
                continue
            try:
                s, e = int(parts[1]), int(parts[2])
            except ValueError:
                continue
            by_chr.setdefault(parts[0], []).append((s, e))
    for chrom in by_chr:
        by_chr[chrom].sort()
    return by_chr


def overlap_count(by_chr, chrom, start, end):
    ivs = by_chr.get(chrom, [])
    if not ivs:
        return 0
    starts = [s for s, _ in ivs]
    i = bisect.bisect_right(starts, start) - 1
    count = 0
    while i < len(ivs) and ivs[i][0] < end:
        s, e = ivs[i]
        if e > start:
            count += 1
        i += 1
    return count


def main():
    args = parse_args()
    repeats = load_repeats(args.repeats)
    with open(args.candidates) as fin, open(args.out, "w") as fout:
        for line in fin:
            if not line.strip():
                continue
            if line.startswith("#"):
                fout.write(line.rstrip("\n") + "\tte_overlap\n")
                continue
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 3:
                fout.write(line)
                continue
            # header-like first row (unified BED header without '#')
            if parts[0] == "chr" and parts[1] == "start" and parts[2] == "end":
                fout.write(line.rstrip("\n") + "\tte_overlap\n")
                continue
            try:
                start, end = int(parts[1]), int(parts[2])
            except ValueError:
                fout.write(line)
                continue
            count = overlap_count(repeats, parts[0], start, end)
            fout.write(line.rstrip("\n") + "\t{}\n".format(count))


if __name__ == "__main__":
    sys.exit(main())
