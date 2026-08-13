//
// ECCsplorer prepare prexing: local module for eccdna pipeline
//

process ECCSPLORER_PREPARE_PREXING {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "quay.io/biocontainers/biopython:1.84"

    input:
    tuple val(meta), path(fasta1), path(fasta2), val(best_read_length), val(read_count)

    output:
    tuple val(meta), path("*.fa"), emit: temp_fasta
    path "versions.yml"          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    eccsplorer_prepare_prexing.py \\
        $fasta1 \\
        $fasta2 \\
        $best_read_length \\
        $read_count \\
        ${prefix}_temp.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        biopython: "1.84"
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_temp.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        biopython: "1.84"
    END_VERSIONS
    """
}
