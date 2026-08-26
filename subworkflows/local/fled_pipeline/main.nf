include { FLED } from '../../../modules/local/fled/main'

workflow FLED_PIPELINE {
    take:
    reads           // channel: [ val(meta), fastq ]
    genome_fasta    // channel: reference genome file

    main:
    reads
        .combine(genome_fasta)
        .set { fled_input }

    FLED (
        fled_input.map { meta, fastq, _fasta -> [ meta, fastq ] },
        fled_input.map { _meta, _fastq, fasta -> fasta }
    )
    ch_versions = FLED.out.versions

    // 统一 BED 契约：junctions → BED6+read_count（§4.6）
    FLED_JUNCTION_TO_BED ( FLED.out.junctions )
    ch_versions = ch_versions.mix(FLED_JUNCTION_TO_BED.out.versions)

    emit:
    junctions = FLED.out.junctions      // channel: [ val(meta), <prefix>.fled_junctions.txt ]
    bed       = FLED_JUNCTION_TO_BED.out.bed   // channel: [ val(meta), <prefix>.fled.bed ] (BED6+read_count)
    versions  = ch_versions
}

process FLED_JUNCTION_TO_BED {
    tag "$meta.id"
    label 'process_low'

    conda "${projectDir}/modules/local/ecc_finder_slim/environment.yml"
    container "quay.io/biocontainers/python:3.12.12"

    input:
    tuple val(meta), path(junctions)

    output:
    tuple val(meta), path("${prefix}.fled.bed"), emit: bed
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    fled_to_bed.py \\
        ${junctions} \\
        ${prefix}.fled.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fled_to_bed: 1.0.0
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.fled.bed
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fled_to_bed: 1.0.0
    END_VERSIONS
    """
}
