process FLED_JUNCTION_TO_BED {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "quay.io/biocontainers/python:3.12.12"

    input:
    tuple val(meta), path(junctions)

    output:
    tuple val(meta), path("${prefix}.fled.bed"), emit: bed
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    fled_to_bed.py \\
        ${junctions} \\
        ${prefix}.fled.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fled_to_bed: 1.0.0
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.fled.bed
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fled_to_bed: 1.0.0
    END_VERSIONS
    """
}
