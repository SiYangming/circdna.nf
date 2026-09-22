process ECC_FINDER_ONT_ASM {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ecc_finder_slim:1.0.0--0' :
        'quay.io/bioinfortools/ecc_finder_slim:1.0.0' }"

    input:
    tuple val(meta), path(cluster_fa)
    tuple val(meta2), path(clstr)

    output:
    tuple val(meta), path("${prefix}.fasta"), emit: fasta
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    ont_asm.py \\
        --cluster ${cluster_fa} \\
        --clstr ${clstr} \\
        --prefix ${prefix} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ecc_finder_slim: 1.0.0
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.fasta
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ecc_finder_slim: 1.0.0
    END_VERSIONS
    """
}
