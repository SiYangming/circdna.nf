#!/usr/bin/env python
"""CIDER-Seq2 'annotate' step wrapper: tBLASTn ORF annotation.

Calls cider.annotate.annotate() on a FASTA file and renames the resulting JSON
to {prefix}.json.
"""
import argparse
import os
import sys

import ciderseq_common as common


def main():
    ap = argparse.ArgumentParser(description='CIDER-Seq2 annotate step (tBLASTn ORF annotation)')
    ap.add_argument('--config', required=True, help='ciderseq_config.json')
    ap.add_argument('--protein_db', required=True, help='directory (or db file) of the tblastn protein database')
    ap.add_argument('--outdir', required=True, help='output directory')
    ap.add_argument('--prefix', required=True, help='output prefix (sample.genome)')
    ap.add_argument('input', help='input FASTA file (deconcatenated reads)')
    args = ap.parse_args()

    common.ensure_cider_importable()
    from cider.annotate import annotate

    os.makedirs(args.outdir, exist_ok=True)
    logger = common.get_logger()

    cfg = common.load_config(args.config)
    settings = cfg['annotate']
    settings['outputdir'] = os.path.abspath(args.outdir)
    settings['tblastndb'] = common.resolve_in_dir(settings['tblastndb'], [args.protein_db])
    settings['tblastndb'] = common.ensure_blastdb(settings, 'tblastndb', 'prot')

    # annotate() writes {outdir}/{input_basename}.json
    base = annotate(settings, os.path.abspath(args.input), logger)
    src = base + '.json'
    dst = os.path.join(args.outdir, '%s.json' % args.prefix)
    if not os.path.isfile(src):
        sys.exit('[ciderseq_annotate] expected output not found: %s' % src)
    os.rename(src, dst)
    sys.stderr.write('[ciderseq_annotate] %s -> %s\n' % (args.prefix, dst))


if __name__ == '__main__':
    main()
