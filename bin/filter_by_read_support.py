#!/usr/bin/env python
import sys
import argparse

def parse_args():
    parser = argparse.ArgumentParser(description='Filter eccDNA candidates by minimum read support')
    parser.add_argument('input_file', help='Input BED file')
    parser.add_argument('output_file', help='Output BED file')
    parser.add_argument('--min_support', type=int, default=2, help='Minimum read support')
    return parser.parse_args()

def filter_by_read_support(input_file, output_file, min_support):
    with open(input_file, 'r') as fin, open(output_file, 'w') as fout:
        for line in fin:
            if line.startswith('#'):
                fout.write(line)
                continue
            parts = line.strip().split('\t')
            if len(parts) >= 5:
                try:
                    support = int(parts[4])
                    if support >= min_support:
                        fout.write(line)
                except ValueError:
                    fout.write(line)

if __name__ == '__main__':
    args = parse_args()
    filter_by_read_support(args.input_file, args.output_file, args.min_support)