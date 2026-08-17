include { FLYE } from '../../../modules/local/flye/main'

workflow FLYE_PIPELINE {
    take:
    reads   // channel: [ val(meta), fastq ]

    main:
    ch_versions = channel.empty()

    FLYE ( reads )
    ch_versions = ch_versions.mix(FLYE.out.versions)

    emit:
    assembly = FLYE.out.assembly    // channel: [ val(meta), assembly.fasta ]
    versions = ch_versions
}
