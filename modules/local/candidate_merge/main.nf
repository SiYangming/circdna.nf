process CANDIDATE_MERGE {
    tag "${meta.id}"
    label 'process_single'

    container "quay.io/biocontainers/python:3.12.12"
    publishDir "${params.outdir}/eccdna_mode/candidate_merge", mode:'copy', enabled:true

    input:
    tuple val(meta), path(eccsplorer_bed), path(circle_map_bed)

    output:
    tuple val(meta), path("*_merged_candidates.bed"), emit: merged_bed
    tuple val("${task.process}"), val('candidate_merge'), val('1.0'), emit: versions_merge, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def max_dist = task.ext.max_distance ?: 100
    """
    echo "candidate_merge 1.0" > version.txt

    python ${projectDir}/bin/merge_candidates.py \\
        --eccsplorer "${eccsplorer_bed}" \\
        --circle_map "${circle_map_bed}" \\
        --output ${prefix}_merged_candidates.bed \\
        --max-distance ${max_dist}
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_merged_candidates.bed
    echo "1.0" > version.txt
    """
}
