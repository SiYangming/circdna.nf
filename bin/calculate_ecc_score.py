#!/usr/bin/env python
"""
ECC_SCORE v1.0 calculation
For each eccDNA candidate, compute a composite score:
ECC_SCORE = w1 * Junction_Reads + w2 * log2(Depth_eccDNA+1 / Depth_gDNA+1) - w3 * TE_Repeat_Penalty
"""
import argparse
import sys
import os
import math
import gzip


def load_repeat_regions(repeat_bed):
    """Load TE/repeat regions from BED file"""
    repeats = {}
    if not repeat_bed or not os.path.exists(repeat_bed):
        return repeats

    open_func = gzip.open if repeat_bed.endswith('.gz') else open
    with open_func(repeat_bed, 'rt') as f:
        for line in f:
            if line.startswith('#') or line.strip() == '':
                continue
            cols = line.strip().split('\t')
            if len(cols) < 3:
                continue
            chrom = cols[0]
            start = int(cols[1])
            end = int(cols[2])
            te_type = cols[3] if len(cols) > 3 else 'Unknown'
            if chrom not in repeats:
                repeats[chrom] = []
            repeats[chrom].append((start, end, te_type))
    return repeats


def calculate_te_overlap(cand_chrom, cand_start, cand_end, repeats):
    """Calculate TE overlap ratio for a candidate region"""
    if cand_chrom not in repeats:
        return 0.0, 'None'

    cand_length = cand_end - cand_start
    if cand_length <= 0:
        return 0.0, 'None'

    overlap_total = 0
    te_types = set()

    for te_start, te_end, te_type in repeats[cand_chrom]:
        overlap_start = max(cand_start, te_start)
        overlap_end = min(cand_end, te_end)
        if overlap_start < overlap_end:
            overlap_total += overlap_end - overlap_start
            te_types.add(te_type)

    overlap_ratio = overlap_total / cand_length
    return overlap_ratio, ','.join(sorted(te_types)) if te_types else 'None'


def load_depth_bed(depth_file):
    """Load mosdepth BED file into a list of (chrom, start, end, depth)"""
    regions = {}
    if not depth_file or not os.path.exists(depth_file):
        return regions

    open_func = gzip.open if depth_file.endswith('.gz') else open
    with open_func(depth_file, 'rt') as f:
        for line in f:
            if line.startswith('#') or line.strip() == '':
                continue
            cols = line.strip().split('\t')
            if len(cols) < 4:
                continue
            chrom = cols[0]
            start = int(cols[1])
            end = int(cols[2])
            try:
                depth = float(cols[3])
            except ValueError:
                continue
            if chrom not in regions:
                regions[chrom] = []
            regions[chrom].append((start, end, depth))
    return regions


def get_avg_depth(depth_regions, chrom, start, end):
    """Calculate average depth for a region"""
    if chrom not in depth_regions:
        return 0.0

    total_depth = 0.0
    total_bases = 0

    for d_start, d_end, depth in depth_regions[chrom]:
        if d_end <= start:
            continue
        if d_start >= end:
            break
        overlap_start = max(start, d_start)
        overlap_end = min(end, d_end)
        overlap_bases = overlap_end - overlap_start
        total_depth += depth * overlap_bases
        total_bases += overlap_bases

    return total_depth / total_bases if total_bases > 0 else 0.0


def main():
    parser = argparse.ArgumentParser(description='Calculate ECC_SCORE v1.0 for eccDNA candidates')
    parser.add_argument('--candidates', required=True, help='Merged candidates BED file')
    parser.add_argument('--eccdna-depth', required=True, help='eccDNA sample mosdepth BED')
    parser.add_argument('--gdna-depth', required=True, help='gDNA sample mosdepth BED')
    parser.add_argument('--repeat-bed', help='TE/Repeat BED file for penalty calculation')
    parser.add_argument('--output', required=True, help='Output scored BED file')
    parser.add_argument('--w1', type=float, default=1.0, help='Weight for junction reads (default: 1.0)')
    parser.add_argument('--w2', type=float, default=1.0, help='Weight for depth ratio (default: 1.0)')
    parser.add_argument('--w3', type=float, default=0.5, help='Weight for TE repeat penalty (default: 0.5)')
    args = parser.parse_args()

    repeats = load_repeat_regions(args.repeat_bed)
    eccdna_depths = load_depth_bed(args.eccdna_depth)
    gdna_depths = load_depth_bed(args.gdna_depth)

    with open(args.candidates) as fin, open(args.output, 'w') as fout:
        header_line = fin.readline()
        fout.write('#chrom\tstart\tend\tname\tecc_score\tstrand\tsources\tnum_tools\tjunction_reads\t'
                   'eccdna_depth\tgdna_depth\tlog2_depth_ratio\tte_overlap_ratio\tte_types\tgrade\n')

        for line in fin:
            if line.startswith('#') or line.strip() == '':
                continue
            cols = line.strip().split('\t')
            if len(cols) < 3:
                continue
            chrom = cols[0]
            start = int(cols[1])
            end = int(cols[2])
            name = cols[3] if len(cols) > 3 else 'unknown'
            strand = cols[5] if len(cols) > 5 else '.'
            sources = cols[6] if len(cols) > 6 else 'Unknown'
            num_tools = cols[7] if len(cols) > 7 else '1'
            junction_reads = int(cols[8]) if len(cols) > 8 and cols[8].isdigit() else 0

            ecc_depth = get_avg_depth(eccdna_depths, chrom, start, end)
            gdna_depth = get_avg_depth(gdna_depths, chrom, start, end)
            log2_ratio = math.log2((ecc_depth + 1) / (gdna_depth + 1))

            te_overlap, te_types = calculate_te_overlap(chrom, start, end, repeats)
            te_penalty = te_overlap * 10

            ecc_score = (args.w1 * junction_reads +
                        args.w2 * log2_ratio -
                        args.w3 * te_penalty)

            if ecc_score >= 10:
                grade = 'High'
            elif ecc_score >= 5:
                grade = 'Medium'
            else:
                grade = 'Low'

            fout.write(f"{chrom}\t{start}\t{end}\t{name}\t{ecc_score:.2f}\t{strand}\t"
                      f"{sources}\t{num_tools}\t{junction_reads}\t"
                      f"{ecc_depth:.2f}\t{gdna_depth:.2f}\t{log2_ratio:.4f}\t"
                      f"{te_overlap:.4f}\t{te_types}\t{grade}\n")


if __name__ == '__main__':
    main()
