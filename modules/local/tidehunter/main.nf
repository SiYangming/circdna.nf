process TIDEHUNTER {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/tidehunter:1.5.6--h7f5d12c_0' :
        'quay.io/biocontainers/tidehunter:1.5.6--h7f5d12c_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${prefix}.fasta"), emit: cons_fa
    path "versions.yml"                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # TideHunter: de novo tandem-repeat detection from long reads (no reference)
    TideHunter ${reads} $args > ${prefix}.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tidehunter: 1.5.6
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tidehunter: 1.5.6
    END_VERSIONS
    """
}
