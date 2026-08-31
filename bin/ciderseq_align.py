#!/usr/bin/env python
"""CIDER-Seq2 'align' step wrapper: MUSCLE-based end trimming.

Calls cider.align.align() for every read of a single target genome and writes
the trimmed reads (the function's return value, used downstream by ciderseq.py)
into {prefix}.fa.  The internal per-read files written by align() go to a
temporary directory and are cleaned up.
"""
import argparse
import os
import shutil
import sys
import tempfile

from Bio import SeqIO

import ciderseq_common as common


def main():
    ap = argparse.ArgumentParser(description='CIDER-Seq2 align step (MUSCLE end trimming)')
    ap.add_argument('--config', required=True, help='ciderseq_config.json')
    ap.add_argument('--targets', required=True, help='directory containing the align target fasta files')
    ap.add_argument('--genome', required=True, help='target genome name (key of align.targets)')
    ap.add_argument('--outdir', required=True, help='output directory')
    ap.add_argument('--prefix', required=True, help='output prefix (sample.genome)')
    ap.add_argument('input', help='input FASTA file (reads binned to --genome)')
    args = ap.parse_args()

    common.ensure_cider_importable()
    from cider.align import align

    os.makedirs(args.outdir, exist_ok=True)
    logger = common.get_logger()

    cfg = common.load_config(args.config)
    settings = cfg['align']
    common.rewrite_muscle(settings)

    if args.genome not in settings.get('targets', {}):
        sys.exit('[ciderseq_align] genome %s not found in config align.targets' % args.genome)
    settings['targets'][args.genome] = common.resolve_in_dir(
        settings['targets'][args.genome], [args.targets])

    # align() writes one per-read file into settings['outputdir'] (untrimmed
    # sequence); divert them to a temp dir and only keep the trimmed reads.
    tmpdir = tempfile.mkdtemp()
    settings['outputdir'] = tmpdir
    try:
        trimmed = []
        for record in SeqIO.parse(common.open_read(args.input), 'fasta'):
            record = common.clean_id(record)
            rec, _ = align(settings, record, args.genome, logger)
            trimmed.append(rec)
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)

    out = os.path.join(args.outdir, '%s.fa' % args.prefix)
    with open(out, 'wt') as fout:
        SeqIO.write(trimmed, fout, 'fasta')
    sys.stderr.write('[ciderseq_align] %s: %d trimmed read(s) -> %s\n' % (args.prefix, len(trimmed), out))


if __name__ == '__main__':
    main()
