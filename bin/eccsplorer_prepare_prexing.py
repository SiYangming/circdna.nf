#!/usr/bin/env python3
"""
Subsample, truncate, and interlace paired-end reads with prefixed/suffixed IDs.

Equivalent to eccPrepare.prexing_reads().

Usage:
    eccsplorer_prepare_prexing.py <R1_fasta> <R2_fasta> <best_read_length> <read_count> <output_file>

Output file: interlaced FASTA (one ID line + one seq line per read)
Progress printed to stderr every 3%.
"""

import os
import gzip
import sys

import numpy as np
from Bio import SeqIO
from Bio.SeqRecord import SeqRecord
from Bio.Seq import Seq

SEED = 12


def prexing_reads(r1_path, r2_path, best_read_length, read_count, output_file):
    """Subsample PE reads, truncate, add prefix/suffix, write interlaced FASTA."""
    np.random.seed(SEED)

    file_basename = os.path.splitext(os.path.basename(r1_path))[0]

    # First pass: count available reads (both ends >= best_read_length)
    available_indices = []
    i = 0
    with (gzip.open(r1_path, 'rt') if r1_path.endswith('.gz') else open(r1_path, 'r')) as f1, (gzip.open(r2_path, 'rt') if r2_path.endswith('.gz') else open(r2_path, 'r')) as f2:
        for rec1, rec2 in zip(SeqIO.parse(f1, 'fasta'), SeqIO.parse(f2, 'fasta')):
            if len(rec1.seq) >= best_read_length and len(rec2.seq) >= best_read_length:
                available_indices.append(i)
            i += 1

    total_available = len(available_indices)
    if total_available == 0:
        print("Error: no usable read pairs found.", file=sys.stderr)
        sys.exit(1)

    # Cap read_count at total available
    actual_count = min(read_count, total_available)
    if actual_count < read_count:
        print("Warning: requested {} pairs but only {} available, using {}.".format(
            read_count, total_available, actual_count), file=sys.stderr)

    # Randomly select indices
    chosen = np.random.choice(available_indices, actual_count, replace=False)
    chosen_set = set(chosen)

    # Progress tracking: ~34 points = every 3%
    progress_points = set(np.around(np.linspace(0, actual_count, 34), 0).astype(int))

    # Second pass: write selected reads
    selected_count = 0

    with (gzip.open(r1_path, 'rt') if r1_path.endswith('.gz') else open(r1_path, 'r')) as f1, (gzip.open(r2_path, 'rt') if r2_path.endswith('.gz') else open(r2_path, 'r')) as f2, open(output_file, 'w') as out_fh:
        for idx, (rec1, rec2) in enumerate(zip(SeqIO.parse(f1, 'fasta'), SeqIO.parse(f2, 'fasta'))):
            if idx not in chosen_set:
                continue

            # Truncate to best_read_length
            seq1 = str(rec1.seq)[:best_read_length]
            seq2 = str(rec2.seq)[:best_read_length]

            # Build IDs
            id1 = file_basename + '_' + rec1.id + '_#0/1'
            id2 = file_basename + '_' + rec2.id + '_#0/2'

            # Write interlaced (R1 then R2)
            out_fh.write('>' + id1 + '\n')
            out_fh.write(seq1 + '\n')
            out_fh.write('>' + id2 + '\n')
            out_fh.write(seq2 + '\n')

            selected_count += 1

            if selected_count in progress_points:
                pct = int(selected_count / actual_count * 100)
                print("{}: {}%".format(file_basename, pct), file=sys.stderr)

        print("{}: 100%".format(file_basename), file=sys.stderr)


def main():
    if len(sys.argv) != 6:
        print("Usage: eccsplorer_prepare_prexing.py <R1_fasta> <R2_fasta> <best_read_length> "
              "<read_count> <output_file>", file=sys.stderr)
        sys.exit(1)

    r1_path = sys.argv[1]
    r2_path = sys.argv[2]
    best_read_length = int(sys.argv[3])
    read_count = int(sys.argv[4])
    output_file = sys.argv[5]

    prexing_reads(r1_path, r2_path, best_read_length, read_count, output_file)


if __name__ == '__main__':
    main()
