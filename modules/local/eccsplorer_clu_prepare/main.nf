process ECCSPLORER_CLU_PREPARE {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "quay.io/bioinfortools/eccsplorer:2022.01.1.1"

    input:
    tuple val(meta), path(reads), path(fasta)

    output:
    tuple val(meta), path("*_clu_prepare"), emit: prepare_dir
    tuple val(meta), path("*_reads_manifest.tsv"), emit: reads_manifest
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: '--mode clu --skeleton-stage prepare'
    def reads_list = reads instanceof List ? reads : [reads]
    def manifest = reads_list.collectWithIndex { read_file, idx ->
        "${idx + 1}\t${read_file}"
    }.join('\n')
    """
    mkdir -p ${prefix}_clu_prepare

    cat <<-END_MANIFEST > ${prefix}_reads_manifest.tsv
    read_index\tread_path
    ${manifest}
    END_MANIFEST

    cat <<-END_PREPARE > ${prefix}_clu_prepare/README.txt
    ECCsplorer clu prepare skeleton
    sample_id\t${meta.id}
    stage\tprepare
    args\t${args}
    fasta\t${fasta}
    END_PREPARE

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer: "2022.01.1.1"
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}_clu_prepare
    touch ${prefix}_clu_prepare/README.txt
    printf "read_index\\tread_path\\n" > ${prefix}_reads_manifest.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer: "2022.01.1.1"
    END_VERSIONS
    """
}
