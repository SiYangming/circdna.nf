#!/usr/bin/env python
"""CIDER-Seq2 'phase' step wrapper: sequence phasing.

Calls cider.phase.phase() on a (deconcatenated FASTA, annotation JSON) pair for
one target genome and renames the outputs to {prefix}.{format}.
"""
import argparse
import os
import shutil
import sys

import ciderseq_common as common


def main():
    ap = argparse.ArgumentParser(description='CIDER-Seq2 phase step (sequence phasing)')
    ap.add_argument('--config', required=True, help='ciderseq_config.json')
    ap.add_argument('--genome', required=True, help='target genome name (key of phase.phasegenomes)')
    ap.add_argument('--outdir', required=True, help='output directory')
    ap.add_argument('--prefix', required=True, help='output prefix (sample.genome)')
    ap.add_argument('deconcat', help='input deconcatenated FASTA file')
    ap.add_argument('annotation', help='input annotation JSON file')
    args = ap.parse_args()

    common.ensure_cider_importable()
    from cider.phase import phase

    os.makedirs(args.outdir, exist_ok=True)
    logger = common.get_logger()

    cfg = common.load_config(args.config)
    settings = cfg['phase']
    settings['outputdir'] = os.path.abspath(args.outdir)

    if args.genome not in settings.get('phasegenomes', {}):
        sys.exit('[ciderseq_phase] genome %s not found in config phase.phasegenomes' % args.genome)

    # phase() derives output basenames from the input file names; stage the
    # inputs under fixed names so the outputs are {prefix}.deconcat.{format}.
    decon_stage = os.path.join(args.outdir, '%s.deconcat.fa' % args.prefix)
    annot_stage = os.path.join(args.outdir, '%s.annotate.json' % args.prefix)
    shutil.copy(args.deconcat, decon_stage)
    shutil.copy(args.annotation, annot_stage)

    phase(settings, args.genome, decon_stage, annot_stage, logger)

    # Rename {prefix}.deconcat.{format} -> {prefix}.{format}
    for fmt in settings.get('outputformat', []):
        src = os.path.join(args.outdir, '%s.deconcat.%s' % (args.prefix, fmt))
        dst = os.path.join(args.outdir, '%s.%s' % (args.prefix, fmt))
        if os.path.isfile(src):
            os.rename(src, dst)
            sys.stderr.write('[ciderseq_phase] %s -> %s\n' % (args.prefix, dst))


if __name__ == '__main__':
    main()
