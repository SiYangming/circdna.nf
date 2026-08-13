#!/usr/bin/env python3
"""
Count paired-end reads where both mates meet the minimum length threshold.

Equivalent to eccPrepare.get_max_read_count().

Usage: eccsplorer_prepare_read_count.py <R1_fasta> <R2_fasta> <best_read_length>
Output: integer paired_read_count to stdout
"""

import gzip
import sys

from Bio import SeqIO


def get_max_read_count(r1_path, r2_path, best_read_length):
    """Count PE pairs where both reads >= best_read_length."""
    count = 0
    with (gzip.open(r1_path, 'rt') if r1_path.endswith('.gz') else open(r1_path, 'r')) as f1, (gzip.open(r2_path, 'rt') if r2_path.endswith('.gz') else open(r2_path, 'r')) as f2:
        for rec1, rec2 in zip(SeqIO.parse(f1, 'fasta'), SeqIO.parse(f2, 'fasta')):
            if len(rec1.seq) >= best_read_length and len(rec2.seq) >= best_read_length:
                count += 1
    return count


def main():
    if len(sys.argv) != 4:
        print("Usage: eccsplorer_prepare_read_count.py <R1_fasta> <R2_fasta> <best_read_length>",
              file=sys.stderr)
        sys.exit(1)

    r1_path = sys.argv[1]
    r2_path = sys.argv[2]
    best_read_length = int(sys.argv[3])

    count = get_max_read_count(r1_path, r2_path, best_read_length)
    print(count)


if __name__ == '__main__':
    main()
