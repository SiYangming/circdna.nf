#!/usr/bin/env python3
"""
Calculate optimal read length for minimal cumulative base loss.

Equivalent to eccPrepare.get_best_read_length(), using numpy grid search
instead of scipy.optimize.fmin.

Usage: eccsplorer_prepare_read_length.py <fasta_file>
Output: integer best_read_length to stdout
"""

import math
import gzip
import sys

import numpy as np
from Bio import SeqIO


def cumulative_bases(t, read_lengths):
    """Calculate total bases lost when reads are trimmed to length t."""
    lost = 0
    for rl in read_lengths:
        if rl < t:
            lost += rl
        elif rl > t:
            lost += rl - t
    return lost


def get_best_read_length(fasta_path):
    """Find the read length that minimizes cumulative base loss via grid search."""
    read_lengths = []
    with (gzip.open(fasta_path, 'rt') if fasta_path.endswith('.gz') else open(fasta_path, 'r')) as fh:
        for record in SeqIO.parse(fh, 'fasta'):
            read_lengths.append(len(record.seq))

    if not read_lengths:
        print("Error: no reads found in FASTA file.", file=sys.stderr)
        sys.exit(1)

    read_lengths = np.array(read_lengths, dtype=np.int64)
    min_len = int(read_lengths.min())
    max_len = int(read_lengths.max())

    if min_len >= max_len:
        return min_len

    # Grid search: ~20 candidate points (same low precision as original xtol=10000)
    candidates = np.linspace(min_len, max_len, 20)
    candidates = np.floor(candidates).astype(np.int64)
    candidates = np.unique(candidates)

    best_t = candidates[0]
    best_loss = cumulative_bases(best_t, read_lengths)

    for t in candidates[1:]:
        loss = cumulative_bases(t, read_lengths)
        if loss < best_loss:
            best_loss = loss
            best_t = t

    return best_t


def main():
    if len(sys.argv) != 2:
        print("Usage: eccsplorer_prepare_read_length.py <fasta_file>", file=sys.stderr)
        sys.exit(1)

    fasta_path = sys.argv[1]
    best = get_best_read_length(fasta_path)
    print(best)


if __name__ == '__main__':
    main()
