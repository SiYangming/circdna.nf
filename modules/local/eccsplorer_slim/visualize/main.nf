process ECCSPLORER_VISUALIZE {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/eccsplorer_slim:1.0.0--0' :
        'quay.io/bioinfortools/eccsplorer_slim:1.0.0' }"

    input:
    tuple val(meta), path(normalized_data)

    output:
    path "*_manhattan.png"                       , emit: manhattan_plot
    path "*_candidate_*"                         , emit: candidate_plots, optional: true
    path "versions.yml"                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # v2: --mode configurable (manhattan|line), line = per-candidate collage
    visualize.R \\
        --data ${normalized_data} \\
        --outdir . \\
        --prefix ${prefix} \\
        --mode ${params.eccsplorer_viz_mode} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer_slim: 1.0.0
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_manhattan.png

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer_slim: 1.0.0
    END_VERSIONS
    """
}
