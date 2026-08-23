#!/usr/bin/env python
import sys
import argparse

def parse_args():
    parser = argparse.ArgumentParser(description='Convert CReSIL eccDNA output to BED format')
    parser.add_argument('input_file', help='CReSIL eccDNA_final.txt file')
    parser.add_argument('output_file', help='Output BED file')
    return parser.parse_args()

def convert_cresil_to_bed(input_file, output_file):
    with open(input_file, 'r') as fin, open(output_file, 'w') as fout:
        header = fin.readline()
        for line in fin:
            parts = line.strip().split('\t')
            if len(parts) >= 4:
                chrom = parts[0]
                start = parts[1]
                end = parts[2]
                name = f"eccDNA_{parts[0]}_{parts[1]}_{parts[2]}"
                score = parts[3] if len(parts) > 3 else '0'
                strand = '+' if len(parts) > 4 else '.'
                fout.write(f"{chrom}\t{start}\t{end}\t{name}\t{score}\t{strand}\n")

if __name__ == '__main__':
    args = parse_args()
    convert_cresil_to_bed(args.input_file, args.output_file)