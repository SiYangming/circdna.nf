#!/usr/bin/env python
"""Filter eccDNA candidates by minimum read support.

Auto-detects the support column from header names, falling back to a
configurable column index (default 4, i.e. the 5th column).
"""
import sys
import argparse

SUPPORT_COL_NAMES = {
    'read_count', 'support', 'support_reads', 'reads', 'count',
    'num_reads', 'nreads', 'read_support', 'coverage', 'depth',
}


def parse_args():
    parser = argparse.ArgumentParser(description='Filter eccDNA candidates by minimum read support')
    parser.add_argument('input_file', help='Input TSV/BED file')
    parser.add_argument('output_file', help='Output TSV/BED file')
    parser.add_argument('--min_support', type=int, default=2, help='Minimum read support')
    parser.add_argument('--column', type=int, default=None,
                        help='Column index (0-based) for read support; auto-detect if not specified')
    return parser.parse_args()


def detect_support_column(fields):
    for i, field in enumerate(fields):
        if field.lower().lstrip('#') in SUPPORT_COL_NAMES:
            return i
    return None


def filter_by_read_support(input_file, output_file, min_support, column=None):
    detected_col = column
    with open(input_file, 'r') as fin, open(output_file, 'w') as fout:
        for line in fin:
            if line.startswith('#'):
                fout.write(line)
                continue
            parts = line.rstrip('\n').split('\t')
            # Auto-detect support column from header-like first data row
            if detected_col is None:
                col = detect_support_column(parts)
                if col is not None:
                    detected_col = col
                    fout.write(line)
                    continue
                # Fall back to default column 4
                detected_col = 4
            col = detected_col
            if len(parts) > col:
                try:
                    support = int(parts[col])
                    if support >= min_support:
                        fout.write(line)
                except ValueError:
                    fout.write(line)
            else:
                fout.write(line)


if __name__ == '__main__':
    args = parse_args()
    filter_by_read_support(args.input_file, args.output_file, args.min_support, args.column)
