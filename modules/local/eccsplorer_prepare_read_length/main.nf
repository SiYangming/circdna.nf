//
// ECCsplorer prepare read length: local module for eccdna pipeline
//

process ECCSPLORER_PREPARE_READ_LENGTH {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "quay.io/biocontainers/biopython:1.84"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), stdout, emit: read_length
    path "versions.yml"       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    optimal_length=\$(eccsplorer_prepare_read_length.py $fasta)

    echo \$optimal_length > ${prefix}_optimal_length.txt
    echo \$optimal_length

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        biopython: "1.84"
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo 100 > ${prefix}_optimal_length.txt
    echo 100

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        biopython: "1.84"
    END_VERSIONS
    """
}
