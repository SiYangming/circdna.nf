#!/usr/bin/env python
"""Convert a CircleSeeker eccDNA_summary.csv into a BED6+read_count table.

CircleSeeker (v1.1.x) writes a per-sample summary CSV
(``<prefix>_eccDNA_summary.csv``) with one eccDNA per row and direct
``chr / start / end / strand`` columns:

    eccDNA_id,type,state,chr,start,end,strand,length,location,...
    UeccDNA0001,Uecc,Confirmed,chr1,600,1100,+,500,...

This script converts it into a BED6+ table
(chr, start, end, name, score, strand, read_count) so the standard
LONG_READ_FILTERING machinery (``filter_by_read_support.py`` etc.) can be
reused downstream. Coordinates are converted from 1-based inclusive
(CircleSeeker) to 0-based half-open (BED).

The header line deliberately does NOT start with ``#`` so that
``filter_by_read_support.py`` auto-detects the ``read_count`` support column.
"""
import argparse
import csv
import re
import sys

BED_HEADER = ["chr", "start", "end", "name", "score", "strand", "read_count"]

# Fallback parser for a ``chr:start-end`` style region (used when the
# chr/start/end columns are absent, e.g. from the legacy merged_output.csv).
REGION_RE = re.compile(r"^(?P<chr>[^:]+):(?P<start>\d+)[-:](?P<end>\d+)$")

# Candidate names for the read-support column (case-insensitive)
SUPPORT_COL_CANDIDATES = ("read_count", "reads_count", "reads", "hit_count", "count")


def parse_region(region):
    """Return (chrom, start0, end0) for the first coordinate of a region string."""
    first = re.split(r"[;,]\s*", region.strip())[0]
    m = REGION_RE.match(first)
    if not m:
        return None
    start = int(m.group("start")) - 1  # 1-based inclusive -> 0-based half-open
    end = int(m.group("end"))
    return m.group("chr"), start, end


def convert(csv_path, bed_path):
    written = 0
    with open(csv_path, newline="") as fin, open(bed_path, "w") as fout:
        reader = csv.DictReader(fin)
        fout.write("\t".join(BED_HEADER) + "\n")
        if not reader.fieldnames:
            return written

        support_col = None
        for cand in SUPPORT_COL_CANDIDATES:
            if cand in reader.fieldnames:
                support_col = cand
                break

        for row in reader:
            # Prefer dedicated chr/start/end columns (v1.1.x summary CSV)
            chrom = (row.get("chr") or row.get("chrom") or "").strip()
            start_raw = (row.get("start") or "").strip()
            end_raw = (row.get("end") or "").strip()
            if chrom and start_raw and end_raw:
                try:
                    chrom, start, end = chrom, int(start_raw) - 1, int(end_raw)
                except (TypeError, ValueError):
                    parsed = None
                else:
                    parsed = (chrom, start, end)
            else:
                # Fallback: parse the first region from a Regions/location field
                region = row.get("Regions") or row.get("regions") or row.get("location") or ""
                parsed = parse_region(region) if region else None
            if not parsed:
                continue

            chrom, start, end = parsed
            name = row.get("eccDNA_id") or row.get("eccdna_id") or "eccDNA"
            strand = (row.get("Strand") or row.get("strand") or "+").strip()
            if strand not in ("+", "-"):
                strand = "+"
            try:
                support = int(row.get(support_col, 0)) if support_col else 0
            except (TypeError, ValueError):
                support = 0
            fout.write(f"{chrom}\t{start}\t{end}\t{name}\t0\t{strand}\t{support}\n")
            written += 1
    return written


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv_input", help="CircleSeeker <prefix>_eccDNA_summary.csv (or merged CSV)")
    parser.add_argument("bed_output", help="Output BED6+read_count file")
    args = parser.parse_args()

    written = convert(args.csv_input, args.bed_output)
    sys.stderr.write(f"circleseeker_to_bed: wrote {written} eccDNA interval(s) to {args.bed_output}\n")


if __name__ == "__main__":
    main()
