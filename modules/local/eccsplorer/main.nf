process ECCSPLORER {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "quay.io/siyangming/eccsplorer:2022.01.1.1"

    input:
    tuple val(meta), path(reads), path(fasta)

    output:
    tuple val(meta), path("*_candidates.bed"), emit: candidates_bed
    tuple val(meta), path("*_junction_reads.txt"), emit: junction_reads
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: ''
    // TRIMGALORE 输出 paired-end reads 为列表 [r1, r2]，需拆分为单独参数
    def reads_list = reads instanceof List ? reads : [reads]
    def r1 = reads_list[0]
    def r2 = reads_list.size() > 1 ? reads_list[1] : reads_list[0]
    """
    # 运行 ECCsplorer
    python \${ECCSPLORER_HOME:-/opt/eccsplorer}/ECCsplorer.py \\
        ${r1} \\
        ${r2} \\
        -ref ${fasta} \\
        -out_dir ${prefix}_output \\
        ${args}

    # 收集输出文件
    mv ${prefix}_output/*_candidates.bed ${prefix}_candidates.bed 2>/dev/null || touch ${prefix}_candidates.bed
    mv ${prefix}_output/*_junction_reads.txt ${prefix}_junction_reads.txt 2>/dev/null || touch ${prefix}_junction_reads.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer: "2022.01.1.1"
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_candidates.bed
    touch ${prefix}_junction_reads.txt
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer: "2022.01.1.1"
    END_VERSIONS
    """
}
