process ECCSPLORER_CLU_CANDIDATES {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/eccsplorer_slim:1.0.1--0' :
        'quay.io/bioinfortools/eccsplorer_slim:1.0.1' }"

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
    # v3: 显式调用 pipeline bin/ 版 clu_candidates.py（镜像内 /opt/eccsplorer_slim/bin 旧版
    #     优先于 PATH 中的 pipeline bin，需用 ${projectDir}/bin 绝对路径绕过）。
    #     修正版兼容真实 seqclust 输出：normalize []/引号、按 cluster id 对齐、
    #     CLUSTER_TABLE.csv 缺失时回退到 COMPARATIVE_ANALYSIS_COUNTS.csv。
    python3 ${projectDir}/bin/clu_candidates.py \\
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
