process ECCSPLORER_CLU_CORE {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "quay.io/bioinfortools/eccsplorer:2022.01.1.1"

    input:
    tuple val(meta), path(prepare_dir)

    output:
    tuple val(meta), path("*_cluster_candidates.tsv"), emit: candidates
    tuple val(meta), path("*_clu_core"), emit: cluster_results
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: '--mode clu --skeleton-stage core'
    """
    mkdir -p ${prefix}_clu_core

    cat <<-END_CANDIDATES > ${prefix}_cluster_candidates.tsv
    candidate_id\tsample_id\tstage\tnote
    ${prefix}_candidate_001\t${meta.id}\tcore\tECCsplorer clu core skeleton placeholder
    END_CANDIDATES

    cat <<-END_CORE > ${prefix}_clu_core/README.txt
    ECCsplorer clu core skeleton
    sample_id\t${meta.id}
    stage\tcore
    args\t${args}
    prepare_dir\t${prepare_dir}
    END_CORE

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer: "2022.01.1.1"
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}_clu_core
    touch ${prefix}_clu_core/README.txt
    printf "candidate_id\\tsample_id\\tstage\\tnote\\n" > ${prefix}_cluster_candidates.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer: "2022.01.1.1"
    END_VERSIONS
    """
}
