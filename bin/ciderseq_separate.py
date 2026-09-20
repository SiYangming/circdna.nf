#!/usr/bin/env python
"""CIDER-Seq2 'separate' step wrapper: BLASTn-based read binning.

Calls cider.separate.separate() per read and joins the per-read outputs into
{prefix}.{genome}.fa files (one per BLAST hit genome, 'nohit' for non-hits),
mirroring the file_summary() behaviour of ciderseq.py.
"""
import argparse
import os
import sys

from Bio import SeqIO

import ciderseq_common as common


def main():
    ap = argparse.ArgumentParser(description='CIDER-Seq2 separate step (BLASTn read binning)')
    ap.add_argument('--config', required=True, help='ciderseq_config.json')
    ap.add_argument('--blastdb', required=True, help='directory (or db file) of the blastn database')
    ap.add_argument('--outdir', required=True, help='output directory')
    ap.add_argument('--prefix', required=True, help='output prefix (sample id)')
    ap.add_argument('input', help='input FASTQ/FASTA file')
    args = ap.parse_args()

    common.ensure_cider_importable()
    from cider.separate import separate

    os.makedirs(args.outdir, exist_ok=True)
    logger = common.get_logger()

    cfg = common.load_config(args.config)
    settings = cfg['separate']
    settings['outputdir'] = os.path.abspath(args.outdir)
    settings['blastndb'] = common.resolve_in_dir(settings['blastndb'], [args.blastdb])
    settings['blastndb'] = common.ensure_blastdb(settings, 'blastndb', 'nucl')

    genomes = {}   # genome -> list of per-read output file bases
    for record in SeqIO.parse(common.open_read(args.input), common.guess_format(args.input)):
        record = common.clean_id(record)
        genome, filebase = separate(settings, record, logger)
        genomes.setdefault(genome, []).append(filebase)

    # Join the per-read files into {prefix}.{genome}.fa (file_summary of ciderseq.py)
    for genome, bases in genomes.items():
        out = os.path.join(args.outdir, '%s.%s.fa' % (args.prefix, genome))
        with open(out, 'wt') as fout:
            for base in bases:
                fa = base + '.fa'
                if os.path.isfile(fa):
                    for r in SeqIO.parse(fa, 'fasta'):
                        SeqIO.write(r, fout, 'fasta')
                    os.remove(fa)
        sys.stderr.write('[ciderseq_separate] %s: %d read(s) -> %s\n' % (args.prefix, len(bases), out))


if __name__ == '__main__':
    main()
