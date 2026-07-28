#!/usr/bin/env bash -C -e -u -o pipefail
mkdir multiqc_data
mkdir multiqc_plots
touch multiqc_report.html

cat <<-END_VERSIONS > versions.yml
"NFCORE_CIRCDNA:CIRCDNA:MULTIQC":
    multiqc: $( multiqc --version | sed -e "s/multiqc, version //g" )
END_VERSIONS
