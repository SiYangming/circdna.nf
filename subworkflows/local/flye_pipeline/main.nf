include { FLYE } from '../../../modules/nf-core/flye/main'

workflow FLYE_PIPELINE {
    take:
    reads   // channel: [ val(meta), fastq ]

    main:
    ch_versions = channel.empty()

    // nf-core FLYE 需要独立的 mode 输入（--pacbio-hifi / --nano-hq）
    ch_flye_mode = reads.map { meta, _reads -> meta.platform == "pacbio" ? "--pacbio-hifi" : "--nano-hq" }

    FLYE ( reads, ch_flye_mode )
    ch_versions = ch_versions.mix(FLYE.out.versions_flye)

    emit:
    assembly = FLYE.out.fasta    // channel: [ val(meta), *.assembly.fasta.gz ]
    versions = ch_versions
}
