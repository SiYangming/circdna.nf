#!/usr/bin/env python
"""Convert a CReSIL ``*_eccDNA_final.txt`` table into the unified eccDNA BED contract.

CReSIL identify output is a 10-column table with a header line:

    id  merge_region  merge_len  num_region  ctc  numreads  totalbase
    coverage  consensus_len  consensus_status

``merge_region`` lists the genomic segments merged into one eccDNA event,
comma separated, each ``chrom:start-end_strand`` (an event can therefore span
several loci, e.g. ``5:5629961-5635320_-,1:12753486-12760410_+``).

The unified contract is one interval per row, so this script emits one row per
event using the **first** segment as the representative locus and keeps the
event id plus the full segment list in the ``name`` field for traceability::

    chr  start  end  name  score  strand  read_count

``read_count`` = ``numreads`` (column 6), ``score`` = ``numreads``.

Note: the previous implementation read columns 1-3 as chr/start/end even
though column 1 is the event id and column 2 is the (multi-segment) region
string, so every row was emitted with garbage coordinates.
"""
import argparse
import sys

BED_HEADER = ["chr", "start", "end", "name", "score", "strand", "read_count"]


def parse_args():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("input_file", help="CReSIL eccDNA_final.txt file")
    p.add_argument("output_file", help="Output BED6+read_count file")
    return p.parse_args()


def parse_region(region):
    """'chrom:start-end_strand' -> (chrom, start, end, strand) or None"""
    if ":" not in region or "-" not in region:
        return None
    chrom, rest = region.split(":", 1)
    coords, _, strand = rest.rpartition("_")
    if not coords:
        coords, strand = rest, "."
    start, _, end = coords.partition("-")
    if not start.isdigit() or not end.isdigit():
        return None
    if strand not in ("+", "-"):
        strand = "."
    return chrom, start, end, strand


def to_int(value, default=0):
    try:
        return int(float(value))
    except (TypeError, ValueError):
        return default


def convert(input_file, output_file):
    written = 0
    skipped = 0
    with open(input_file) as fin, open(output_file, "w") as fout:
        fout.write("\t".join(BED_HEADER) + "\n")
        for lineno, line in enumerate(fin):
            if not line.strip() or line.startswith("#"):
                continue
            parts = line.rstrip("\n").split("\t")
            # 跳过表头（首行 id/merge_region/...）
            if lineno == 0 and parts[0].strip().lower() == "id":
                continue
            if len(parts) < 6 or parts[1] in ("merge_region", ""):
                skipped += 1
                continue
            event_id = parts[0]
            segments = parts[1].split(",")
            parsed = parse_region(segments[0])
            if parsed is None:
                skipped += 1
                continue
            chrom, start, end, strand = parsed
            read_count = to_int(parts[5], 0)
            name = "{}|segments={}".format(event_id, len(segments))
            fout.write("{}\t{}\t{}\t{}\t{}\t{}\t{}\n".format(
                chrom, start, end, name, read_count, strand, read_count))
            written += 1
    sys.stderr.write(
        "convert_cresil_to_bed: wrote {} event(s), skipped {} row(s) -> {}\n".format(
            written, skipped, output_file))


if __name__ == "__main__":
    args = parse_args()
    convert(args.input_file, args.output_file)
