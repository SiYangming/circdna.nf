//
// ECCSPLORER_PREXER_SLIM — PRExer 模式：reads 质控裁剪 + FASTQ→FASTA
// replicates ECCsplorer PRExer (trimmomatic trim + seqtk convert)
//

include { TRIMMOMATIC } from '../../../modules/nf-core/trimmomatic/main'
include { SEQTK_SEQ as SEQTK_SEQ_PREXER } from '../../../modules/nf-core/seqtk/seq/main'

workflow ECCSPLORER_PREXER_SLIM {
    take:
    reads    // channel: [meta, [r1, r2]]

    main:
    ch_versions = channel.empty()

    TRIMMOMATIC ( reads )
    ch_versions = ch_versions.mix(TRIMMOMATIC.out.versions_trimmomatic)

    // convert trimmed paired reads to FASTA (original eccPrepare converting)
    def ch_trim_fa_in = TRIMMOMATIC.out.trimmed_reads
        .map { meta, trimmed_reads ->
            def rlist = trimmed_reads instanceof List ? trimmed_reads : [trimmed_reads]
            [ meta, rlist[0] ]
        }
    SEQTK_SEQ_PREXER ( ch_trim_fa_in )
    ch_versions = ch_versions.mix(SEQTK_SEQ_PREXER.out.versions_seqtk)

    emit:
    fasta_ready = SEQTK_SEQ_PREXER.out.fastx
    versions    = ch_versions
}
