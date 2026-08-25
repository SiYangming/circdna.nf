#!/usr/bin/env python
"""CIDER-Seq2 'deconcat' step wrapper: DeConcat algorithm.

Calls cider.deconcatenate.deconcatenate() for every read and joins the
per-read .fa / .stat files into {prefix}.fa and {prefix}.stat, mirroring the
file_summary() behaviour of ciderseq.py.
"""
import argparse
import os
import shutil
import sys
import tempfile

from Bio import SeqIO

import ciderseq_common as common


def main():
    ap = argparse.ArgumentParser(description='CIDER-Seq2 deconcat step (DeConcat algorithm)')
    ap.add_argument('--config', required=True, help='ciderseq_config.json')
    ap.add_argument('--outdir', required=True, help='output directory')
    ap.add_argument('--prefix', required=True, help='output prefix (sample.genome)')
    ap.add_argument('input', help='input FASTA file (aligned reads)')
    args = ap.parse_args()

    common.ensure_cider_importable()
    from cider.deconcatenate import deconcatenate

    os.makedirs(args.outdir, exist_ok=True)
    logger = common.get_logger()

    cfg = common.load_config(args.config)
    settings = cfg['deconcat']
    common.rewrite_muscle(settings)

    # deconcatenate() writes per-read files into settings['outputdir']
    tmpdir = tempfile.mkdtemp()
    settings['outputdir'] = tmpdir
    try:
        bases = []
        for record in SeqIO.parse(common.open_read(args.input), 'fasta'):
            record = common.clean_id(record)
            bases.append(deconcatenate(settings, record, logger))
    finally:
        pass  # files inside tmpdir are joined below, then the dir is removed

    # Join per-read files (file_summary of ciderseq.py)
    outfa = os.path.join(args.outdir, '%s.fa' % args.prefix)
    with open(outfa, 'wt') as fout:
        for base in bases:
            fa = base + '.fa'
            if os.path.isfile(fa):
                for r in SeqIO.parse(fa, 'fasta'):
                    SeqIO.write(r, fout, 'fasta')
                os.remove(fa)
    sys.stderr.write('[ciderseq_deconcat] %s: %d record(s) -> %s\n' % (args.prefix, len(bases), outfa))

    if int(settings.get('statistics', 0)) == 1:
        outstat = os.path.join(args.outdir, '%s.stat' % args.prefix)
        with open(outstat, 'wt') as fout:
            for base in bases:
                stat = base + '.stat'
                if os.path.isfile(stat):
                    for line in open(stat):
                        fout.write(line)
                    os.remove(stat)
        sys.stderr.write('[ciderseq_deconcat] %s: stats -> %s\n' % (args.prefix, outstat))

    shutil.rmtree(tmpdir, ignore_errors=True)


if __name__ == '__main__':
    main()
