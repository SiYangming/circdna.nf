process ECC_FINDER_ONT_CSV_TO_BED {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "quay.io/biocontainers/python:3.12.12"

    input:
    tuple val(meta), path(csv)

    output:
    tuple val(meta), path("${prefix}.eccfinder_ont.bed"), emit: bed
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    eccfinder_ont_to_bed.py \\
        ${csv} \\
        ${prefix}.eccfinder_ont.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccfinder_ont_to_bed: 1.0.0
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.eccfinder_ont.bed
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccfinder_ont_to_bed: 1.0.0
    END_VERSIONS
    """
}
