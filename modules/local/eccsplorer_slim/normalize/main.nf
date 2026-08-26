process ECCSPLORER_NORMALIZE {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/eccsplorer_slim:1.0.0--0' :
        'quay.io/bioinfortools/eccsplorer_slim:1.0.0' }"

    input:
    tuple val(meta), path(coverage_csv)
    path(stats)

    output:
    tuple val(meta), path("${prefix}_normalized.csv"), emit: normalized
    path "versions.yml"                               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def stats_args = stats ? stats.collect { s -> "-stats ${s}" }.join(' ') : ''
    """
    # v2: mapped bases parsed from samtools stats (no hardcoded 1e6)
    normalize.R \\
        --coverage ${coverage_csv} \\
        --output ${prefix}_normalized.csv \\
        --mode region \\
        ${stats_args} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer_slim: 1.0.0
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_normalized.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer_slim: 1.0.0
    END_VERSIONS
    """
}
