#!/usr/bin/env python
"""Shared helpers for the CIDER-Seq2 slim wrapper scripts.

CIDER-Seq2's five steps (separate / align / deconcatenate / annotate / phase)
are only exposed by `ciderseq.py` inside one monolithic run.  These wrappers
call the individual `cider.<step>` functions directly so that each step can be
run as its own Nextflow process (enabling per-step resume / parallelisation)
without modifying the upstream CIDER-Seq2 source code.
"""
import json
import logging
import os
import shutil
import sys


def find_cider_home():
    """Locate the directory that contains the `cider` python package."""
    candidates = []
    # The published container sets CIDERSEQ_HOME=/opt/ciderseq2; also honour
    # an explicit CIDERSEQ2_HOME override.
    for var in ('CIDERSEQ2_HOME', 'CIDERSEQ_HOME'):
        env = os.environ.get(var)
        if env:
            candidates.append(env)
    exe = shutil.which('ciderseq.py')
    if exe:
        # conda layout: <prefix>/bin/ciderseq.py -> <prefix>/libexec/ciderseq2
        # (realpath resolves the /usr/local/bin symlink used in the container)
        real = os.path.realpath(exe)
        candidates.append(os.path.join(os.path.dirname(os.path.dirname(real)), 'libexec', 'ciderseq2'))
    # source checkout layout: <repo>/ciderseq2 (sibling of circdna.nf)
    candidates.append(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'ciderseq2'))
    for cand in candidates:
        if cand and os.path.isdir(os.path.join(cand, 'cider')):
            return cand
    return None


def ensure_cider_importable():
    """Add the CIDER-Seq2 home directory to sys.path (required for `import cider`)."""
    home = find_cider_home()
    if home is None:
        raise RuntimeError(
            'Could not locate the CIDER-Seq2 `cider` package. '
            'Set $CIDERSEQ2_HOME or install the ciderseq2 conda package.'
        )
    if home not in sys.path:
        sys.path.insert(0, home)
    return home


def load_config(config_file):
    """Read the ciderseq_config.json file."""
    with open(config_file) as fh:
        return json.load(fh)


def get_logger(name='ciderseq'):
    """Return a logger that writes to stderr (the cider.* functions log at debug level)."""
    logger = logging.getLogger(name)
    if not logger.handlers:
        logger.setLevel(logging.DEBUG)
        handler = logging.StreamHandler(sys.stderr)
        handler.setFormatter(logging.Formatter('%(asctime)s %(levelname)s %(message)s'))
        logger.addHandler(handler)
    return logger


def clean_id(record):
    """Mimic ciderseq.py: '/' is not allowed in sequence ids, replace with '_'."""
    record.id = str(record.id).replace('/', '_')
    return record


def open_read(path):
    """Open a (possibly gzip-compressed) file for text reading.

    Biopython < 1.79 does not transparently decompress '.gz' files, so the
    wrappers must hand SeqIO.parse a gzip handle for compressed inputs.
    """
    import gzip
    if str(path).endswith('.gz'):
        return gzip.open(path, 'rt')
    return open(path, 'rt')


def guess_format(path):
    """Guess Biopython sequence format from the first non-empty line ('>' or '@').

    Handles gzip-compressed files transparently.
    """
    with open_read(path) as fh:
        for line in fh:
            line = line.strip()
            if line:
                if line.startswith('>'):
                    return 'fasta'
                if line.startswith('@'):
                    return 'fastq'
                break
    return 'fasta'


def rewrite_muscle(settings):
    """Use the configured muscle executable if present, else fall back to $PATH."""
    muscleexe = str(settings.get('muscleexe', '') or '')
    if not muscleexe or not os.path.isfile(muscleexe):
        muscleexe = shutil.which('muscle') or 'muscle'
    settings['muscleexe'] = muscleexe
    return settings


def resolve_in_dir(config_path, search_paths):
    """Rewrite a config file path to the staged file with the same basename.

    Nextflow stages input files under arbitrary paths, so the paths baked into
    ciderseq_config.json (absolute or relative) need to be mapped onto the
    staged copies.  Matching is done by basename.
    """
    if not config_path:
        return config_path
    base = os.path.basename(config_path)
    for sp in search_paths or []:
        if not sp:
            continue
        if os.path.isdir(sp):
            cand = os.path.join(sp, base)
            if os.path.isfile(cand):
                return cand
        elif os.path.isfile(sp) and os.path.basename(sp) == base:
            return sp
    return config_path


def ensure_blastdb(settings, key, dbtype):
    """Create a BLAST database if the index files are missing.

    `key` is the settings field holding the db fasta path (e.g. 'blastndb' /
    'tblastndb').  dbtype is 'nucl' or 'prot'.  Returns the db path.
    """
    db = settings.get(key, '')
    if not db:
        return db
    marker = db + ('.nhr' if dbtype == 'nucl' else '.phr')
    if os.path.isfile(marker):
        return db
    if not shutil.which('makeblastdb'):
        raise RuntimeError('BLAST database index missing and makeblastdb not found: %s' % db)
    subprocess_args = ['makeblastdb', '-in', db, '-dbtype', dbtype]
    import subprocess
    sys.stderr.write('Building BLAST database: %s\n' % ' '.join(subprocess_args))
    subprocess.run(subprocess_args, check=True)
    return db
