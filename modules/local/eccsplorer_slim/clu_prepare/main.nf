process ECCSPLORER_CLU_PREPARE {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/eccsplorer_slim:1.0.0--0' :
        'quay.io/bioinfortools/eccsplorer_slim:1.0.0' }"

    input:
    tuple val(meta), path(r1), path(r2)
    tuple val(meta2), path(c1), path(c2)
    val(taxon)

    output:
    tuple val(meta), path("${prefix}_REPEATEXPLORER_READY.fa"), emit: ready_fa
    path "versions.yml"                                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # v2: clu_prepare.py best-length integer search (150bp) — fixes empty output
    clu_prepare.py \\
        --r1 ${r1} \\
        --r2 ${r2} \\
        --c1 ${c1} \\
        --c2 ${c2} \\
        --pre_a TR \\
        --pre_b CO \\
        --out ${prefix}_REPEATEXPLORER_READY.fa \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer_slim: 1.0.0
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_REPEATEXPLORER_READY.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer_slim: 1.0.0
    END_VERSIONS
    """
}
