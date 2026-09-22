process CRESIL_TO_BED {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "quay.io/biocontainers/python:3.12.12"

    input:
    tuple val(meta), path(table)

    output:
    tuple val(meta), path("${prefix}.cresil.bed"), emit: bed
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    convert_cresil_to_bed.py \\
        ${table} \\
        ${prefix}.cresil.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        convert_cresil_to_bed: 1.0.0
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.cresil.bed
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        convert_cresil_to_bed: 1.0.0
    END_VERSIONS
    """
}
