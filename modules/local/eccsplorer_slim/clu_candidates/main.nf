process ECCSPLORER_CLU_CANDIDATES {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/eccsplorer_slim:1.0.0--0' :
        'quay.io/bioinfortools/eccsplorer_slim:1.0.0' }"

    input:
    tuple val(meta), path(clu_dir)
    val(pre_a)
    val(pre_b)

    output:
    tuple val(meta), path("${prefix}_cluster_candidates.csv"), emit: cluster_candidates
    tuple val(meta), path("${prefix}_comparative_cluster_table.csv"), emit: comparative_table
    path "versions.yml"                                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # v2: clu_candidates.py reads seqclust outputs from clu_dir root (seqclust --output_dir layout)
    clu_candidates.py \\
        --clu_dir ${clu_dir} \\
        --pre_a ${pre_a} \\
        --pre_b ${pre_b} \\
        --out_candidates ${prefix}_cluster_candidates.csv \\
        --out_summary ${prefix}_comparative_cluster_table.csv \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer_slim: 1.0.0
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_cluster_candidates.csv
    touch ${prefix}_comparative_cluster_table.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer_slim: 1.0.0
    END_VERSIONS
    """
}
