include { FLYE } from '../../../modules/nf-core/flye/main'

workflow FLYE_PIPELINE {
    take:
    reads   // channel: [ val(meta), fastq ]

    main:
    ch_versions = channel.empty()

    // nf-core FLYE 需要独立的 mode 输入（--pacbio-hifi / --pacbio-raw / --nano-hq）
    // mode 由 meta.read_type 决定（§8 / §6.3）
    ch_flye_mode = reads.map { meta, _reads ->
        meta.read_type == 'hifi' ? '--pacbio-hifi' :
        meta.read_type == 'clr'  ? '--pacbio-raw'  : '--nano-hq'
    }

    FLYE ( reads, ch_flye_mode )
    ch_versions = ch_versions.mix(FLYE.out.versions_flye)

    emit:
    assembly = FLYE.out.fasta    // channel: [ val(meta), *.assembly.fasta.gz ]
    versions = ch_versions
}
