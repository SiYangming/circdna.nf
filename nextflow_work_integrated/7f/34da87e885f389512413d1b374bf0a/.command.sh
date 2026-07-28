#!/usr/bin/env bash -C -e -u -o pipefail
touch circdna_1.circular_read_candidates.circular_read_candidates.bam
cat <<-END_VERSIONS > versions.yml
"NFCORE_CIRCDNA:CIRCDNA:ECCDNA_MODE:CIRCLE_MAP_PIPELINE:CIRCLEMAP_READEXTRACTOR":
    Circle-Map: 1.1.4
END_VERSIONS
