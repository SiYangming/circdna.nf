# Image patches (historical)

These scripts used to rewrite CReSIL/FLED site-packages at process runtime.
As of circdna v4.7.3 the fixes live in the tool source repos and are baked into
the existing quay tags (in-place overwrite, no sidecar tags):

- cresil: https://github.com/SiYangming/cresil → `quay.io/bioinfortools/cresil:1.2.1`
- fled: https://github.com/SiYangming/FLED → `quay.io/bioinfortools/fled:1.7.0`

Keep these files only as a reference for what was applied; do not wire them
back into Nextflow modules.
