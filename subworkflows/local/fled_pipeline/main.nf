include { FLED } from '../../../modules/local/fled/main'
include { FLED_JUNCTION_TO_BED } from '../../../modules/local/fled_junction_to_bed/main'

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
