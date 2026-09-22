#!/usr/bin/env python
"""Convert an ecc_finder ONT map CSV into the unified eccDNA BED contract.

`ont_merge.py` (ecc_finder_slim) writes a header-less table of

    refID  rstart  rend  read_count

i.e. only **4** columns (see /opt/ecc_finder_slim/bin/ont_merge.py:
"Output: {prefix}.csv (refID,rstart,rend,read_count)").  Older/black-box
ecc_finder variants emitted 6 columns (`chr start end num_s num_d len`).

This script accepts both layouts and always emits the unified
BED6+read_count contract (header line included):

    chr  start  end  name  score  strand  read_count

read_count = max(num_s, num_d) for the 6-column layout, or the 4th column
for the 4-column layout.
"""
import argparse
import sys


BED_HEADER = ["chr", "start", "end", "name", "score", "strand", "read_count"]


def parse_args():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("csv", help="ecc_finder ONT map CSV (ont_merge output)")
    p.add_argument("output", help="Output BED6+read_count file")
    return p.parse_args()


def split_fields(line):
    parts = line.rstrip("\n").split("\t")
    if len(parts) < 4:
        parts = line.rstrip("\n").split(",")
    return parts


def convert(csv_path, output_path):
    written = 0
    skipped = 0
    with open(csv_path) as fin, open(output_path, "w") as fout:
        fout.write("\t".join(BED_HEADER) + "\n")
        for line in fin:
            if not line.strip() or line.startswith("#"):
                continue
            parts = split_fields(line)
            if len(parts) < 4:
                skipped += 1
                continue
            try:
                chrom = parts[0]
                start = int(parts[1])
                end = int(parts[2])
                if len(parts) >= 6:
                    # chr start end num_s num_d len
                    num_s = int(parts[3])
                    num_d = int(parts[4])
                    read_count = max(num_s, num_d)
                    score = num_s
                else:
                    # refID rstart rend read_count
                    read_count = int(parts[3])
                    score = read_count
            except ValueError:
                skipped += 1
                continue
            name = "eccDNA_{}_{}_{}".format(chrom, start, end)
            fout.write("{}\t{}\t{}\t{}\t{}\t.\t{}\n".format(
                chrom, start, end, name, score, read_count))
            written += 1
    sys.stderr.write(
        "eccfinder_ont_to_bed: wrote {} candidate(s), skipped {} row(s) -> {}\n".format(
            written, skipped, output_path))


if __name__ == "__main__":
    args = parse_args()
    convert(args.csv, args.output)
