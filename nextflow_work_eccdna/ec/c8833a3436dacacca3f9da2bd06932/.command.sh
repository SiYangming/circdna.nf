#!/usr/bin/env bash -C -e -u -o pipefail
touch circdna_3_circularDNA_coordinates.bed
cat <<-END_VERSIONS > versions.yml
"NFCORE_CIRCDNA:CIRCDNA:ECCDNA_MODE:CIRCLE_MAP_PIPELINE:CIRCLEMAP_REALIGN":
    Circle-Map: 1.1.4
END_VERSIONS
