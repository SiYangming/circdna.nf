#!/usr/bin/env python
"""
Merge eccDNA candidates from multiple tools (ECCsplorer, Circle-Map, etc.)
Performs interval merging and overlap consolidation
"""
import argparse
import sys
import os


def parse_bed(bed_file, source_name):
    """Parse BED file, return list of candidate intervals"""
    candidates = []
    if not bed_file or not os.path.exists(bed_file):
        return candidates
    with open(bed_file) as f:
        for line in f:
            if line.startswith('#') or line.strip() == '':
                continue
            cols = line.strip().split('\t')
            if len(cols) < 3:
                continue
            chrom = cols[0]
            start = int(cols[1])
            end = int(cols[2])
            name = cols[3] if len(cols) > 3 else f"{source_name}_{len(candidates)+1}"
            score = cols[4] if len(cols) > 4 else '0'
            strand = cols[5] if len(cols) > 5 else '.'
            junction = 0
            if score.isdigit():
                junction = int(score)
            candidates.append({
                'chrom': chrom,
                'start': start,
                'end': end,
                'name': name,
                'score': score,
                'strand': strand,
                'source': source_name,
                'junction_reads': junction
            })
    return candidates


def merge_candidates(candidates_list, max_distance=100):
    """Merge overlapping or adjacent candidate intervals"""
    all_candidates = []
    for source, cands in candidates_list:
        for c in cands:
            c['source'] = source
            all_candidates.append(c)

    if not all_candidates:
        return []

    all_candidates.sort(key=lambda x: (x['chrom'], x['start']))

    merged = []
    current = None
    sources = set()
    total_junction = 0

    for cand in all_candidates:
        if current is None:
            current = cand.copy()
            sources = {cand['source']}
            total_junction = cand.get('junction_reads', 0)
        elif (cand['chrom'] == current['chrom'] and
              cand['start'] <= current['end'] + max_distance):
            current['end'] = max(current['end'], cand['end'])
            sources.add(cand['source'])
            total_junction += cand.get('junction_reads', 0)
        else:
            current['num_sources'] = len(sources)
            current['sources'] = ','.join(sorted(sources))
            current['junction_reads'] = total_junction
            merged.append(current)
            current = cand.copy()
            sources = {cand['source']}
            total_junction = cand.get('junction_reads', 0)

    if current is not None:
        current['num_sources'] = len(sources)
        current['sources'] = ','.join(sorted(sources))
        current['junction_reads'] = total_junction
        merged.append(current)

    return merged


def write_bed(merged, output_file):
    """Output merged BED file"""
    with open(output_file, 'w') as f:
        f.write('#chrom\tstart\tend\tname\tscore\tstrand\tsources\tnum_tools\tjunction_reads\n')
        for i, m in enumerate(merged):
            name = f"ecc_candidate_{i+1}"
            score = m['junction_reads']
            f.write(f"{m['chrom']}\t{m['start']}\t{m['end']}\t{name}\t{score}\t{m['strand']}\t{m['sources']}\t{m['num_sources']}\t{m['junction_reads']}\n")


def main():
    parser = argparse.ArgumentParser(description='Merge eccDNA candidates from multiple tools')
    parser.add_argument('--eccsplorer', help='ECCsplorer BED output')
    parser.add_argument('--circle_map', help='Circle-Map BED output')
    parser.add_argument('--output', required=True, help='Output merged BED file')
    parser.add_argument('--max-distance', type=int, default=100,
                       help='Maximum distance for merging adjacent candidates (default: 100)')
    args = parser.parse_args()

    candidates_list = []

    if args.eccsplorer and os.path.exists(args.eccsplorer):
        cands = parse_bed(args.eccsplorer, 'ECCsplorer')
        candidates_list.append(('ECCsplorer', cands))

    if args.circle_map and os.path.exists(args.circle_map):
        cands = parse_bed(args.circle_map, 'Circle-Map')
        candidates_list.append(('Circle-Map', cands))

    if not candidates_list:
        print("Warning: No input files found", file=sys.stderr)
        with open(args.output, 'w') as f:
            f.write('# No candidates\n')
        return

    merged = merge_candidates(candidates_list, args.max_distance)
    write_bed(merged, args.output)
    total_input = sum(len(c) for _, c in candidates_list)
    print(f"Merged {total_input} candidates into {len(merged)} consensus candidates")


if __name__ == '__main__':
    main()
