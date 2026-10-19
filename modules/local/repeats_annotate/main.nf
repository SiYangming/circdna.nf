process REPEATS_ANNOTATE {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "quay.io/biocontainers/python:3.12.12"

    input:
    tuple val(meta), path(bed), path(repeats)

    output:
    tuple val(meta), path("${prefix}.te_annotated.bed"), emit: annotated
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    annotate_te_overlap.py \\
        --candidates ${bed} \\
        --repeats ${repeats} \\
        --out ${prefix}.te_annotated.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        annotate_te_overlap: 1.0.0
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    cp ${bed} ${prefix}.te_annotated.bed
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        annotate_te_overlap: 1.0.0
    END_VERSIONS
    """
}
