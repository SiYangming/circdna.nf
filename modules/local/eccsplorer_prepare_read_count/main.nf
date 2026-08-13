//
// ECCsplorer prepare read count: local module for eccdna pipeline
//

process ECCSPLORER_PREPARE_READ_COUNT {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "quay.io/biocontainers/biopython:1.84"

    input:
    tuple val(meta), path(fasta1), path(fasta2), val(best_read_length)

    output:
    tuple val(meta), stdout, emit: read_count
    path "versions.yml"       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    count=\$(eccsplorer_prepare_read_count.py $fasta1 $fasta2 $best_read_length)

    echo \$count > ${prefix}_read_count.txt
    echo \$count

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        biopython: "1.84"
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo 1000 > ${prefix}_read_count.txt
    echo 1000

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        biopython: "1.84"
    END_VERSIONS
    """
}
