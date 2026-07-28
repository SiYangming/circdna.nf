#!/usr/bin/env bash -C -e -u -o pipefail
check_samplesheet.py \
    samplesheet_integrated.csv \
    samplesheet.valid.csv \
    FASTQ

cat <<-END_VERSIONS > versions.yml
"NFCORE_CIRCDNA:CIRCDNA:INPUT_CHECK:SAMPLESHEET_CHECK":
    python: $(python --version | sed 's/Python //g')
END_VERSIONS
