include { FLYE } from '../../../modules/local/flye/main'

workflow FLYE_PIPELINE {
    take:
    reads   // channel: [ val(meta), fastq ]

    main:
    FLYE ( reads )
        .assembly
        .set { contigs }

    emit:
    contigs    // channel: [ val(meta), assembly.fasta ]
}