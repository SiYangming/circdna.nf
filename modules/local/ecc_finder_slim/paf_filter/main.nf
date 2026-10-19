process ECC_FINDER_ONT_PAF_FILTER {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ecc_finder_slim:1.0.0--0' :
        'quay.io/bioinfortools/ecc_finder_slim:1.0.0' }"

    input:
    tuple val(meta), path(paf)

    output:
    tuple val(meta), path("${prefix}.paf.bed"), emit: paf_bed
    path "versions.yml"                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    paf_filter.py \\
        --paf ${paf} \\
        --out ${prefix}.paf.bed \\
        --min-query ${params.eccfinder_ont_min_query} \\
        --min-align ${params.eccfinder_ont_min_align} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ecc_finder_slim: 1.0.0
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.paf.bed
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ecc_finder_slim: 1.0.0
    END_VERSIONS
    """
}
