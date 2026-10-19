process GENRICH {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/genrich:0.6.1--h577a1d6_5' :
        'quay.io/biocontainers/genrich:0.6.1--h577a1d6_5' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${prefix}.bed"), emit: bed
    path "versions.yml"                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    Genrich -t ${bam} -o ${prefix}.site $args
    cut -f1-3 ${prefix}.site > ${prefix}.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        genrich: \$(Genrich 2>&1 | head -1 | sed 's/.*Genrich v//')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        genrich: 0.6.1
    END_VERSIONS
    """
}
