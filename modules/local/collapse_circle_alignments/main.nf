process COLLAPSE_CIRCLE_ALIGNMENTS {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "quay.io/biocontainers/python:3.12.12"

    input:
    tuple val(meta), path(bed)

    output:
    tuple val(meta), path("${prefix}.collapsed.bed"), emit: bed
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    collapse_circle_alignments.py \\
        --bed ${bed} \\
        --out ${prefix}.collapsed.bed \\
        --min-mapq ${params.remap_min_mapq} \\
        --max-gap ${params.remap_max_gap} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        collapse_circle_alignments: 1.0.0
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.collapsed.bed
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        collapse_circle_alignments: 1.0.0
    END_VERSIONS
    """
}
