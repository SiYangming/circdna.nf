#!/usr/bin/env python
"""Convert an ecc_finder ONT map CSV into the unified eccDNA BED contract.

ont_merge.py emits header-less 6-column rows:

    chr  start  end  num_s  num_d  len

num_s / num_d are split/discordant read support counts. We emit
BED6+read_count where read_count = max(num_s, num_d) and score = num_s.
"""
import argparse
import sys


def parse_args():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("csv", help="ecc_finder ONT map CSV")
    p.add_argument("output", help="Output BED6+read_count file")
    return p.parse_args()


BED_HEADER = ["chr", "start", "end", "name", "score", "strand", "read_count"]


def convert(csv_path, output_path):
    written = 0
    with open(csv_path) as fin, open(output_path, "w") as fout:
        fout.write("\t".join(BED_HEADER) + "\n")
        for line in fin:
            if not line.strip() or line.startswith("#"):
                continue
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 6:
                # tolerate ',' separators as well
                parts = line.rstrip("\n").split(",")
            if len(parts) < 6:
                continue
            try:
                chrom, start, end = parts[0], int(parts[1]), int(parts[2])
                num_s = int(parts[3])
                num_d = int(parts[4])
            except ValueError:
                continue
            read_count = max(num_s, num_d)
            name = "eccDNA_{}_{}_{}".format(chrom, start, end)
            fout.write("{}\t{}\t{}\t{}\t{}\t.\t{}\n".format(chrom, start, end, name, num_s, read_count))
            written += 1
    sys.stderr.write("eccfinder_ont_to_bed: wrote {} candidate(s) to {}\n".format(written, output_path))


if __name__ == "__main__":
    args = parse_args()
    convert(args.csv, args.output)
