include { FLYE } from '../../../modules/local/flye/main'

workflow FLYE_PIPELINE {
    take:
    reads   // channel: [ val(meta), fastq ]

    main:
    def flye_args = params.protocol == "pacbio" ? "--pacbio-hifi" : "--nano-hq"
    
    FLYE ( reads.map { meta, fastq -> [ meta, fastq ] } )
        .ext.args = flye_args
        .assembly
        .set { contigs }

    emit:
    contigs    // channel: [ val(meta), assembly.fasta ]
}