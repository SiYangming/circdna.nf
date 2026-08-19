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

    emit:
    junctions = FLED.out.junctions    // channel: [ val(meta), <prefix>.fled_junctions.txt ]
    versions  = ch_versions
}
