//
// Unicycler Pipeline Subworkflow
// Contains: UNICYCLER, SEQTK_SEQ, GETCIRCULARREADS, MINIMAP2_ALIGN
//

include { UNICYCLER           }     from '../../../modules/nf-core/unicycler/main'
include { SEQTK_SEQ           }     from '../../../modules/nf-core/seqtk/seq/main'
include { GETCIRCULARREADS    }     from '../../../modules/local/getcircularreads/main'
include { MINIMAP2_ALIGN      }     from '../../../modules/nf-core/minimap2/align/main'

workflow UNICYCLER_PIPELINE {
    take:
    trimmed_reads          // channel: [ val(meta), [ reads ] ]
    fasta_meta             // channel: [ val(meta), path(fasta) ]

    main:
    ch_versions = channel.empty()

    UNICYCLER (
        trimmed_reads.map { meta, reads -> tuple(meta, reads, []) }
    )
    ch_versions = ch_versions.mix(UNICYCLER.out.versions)

    SEQTK_SEQ (
        UNICYCLER.out.scaffolds
    )
    ch_versions = ch_versions.mix(SEQTK_SEQ.out.versions_seqtk)

    GETCIRCULARREADS (
        SEQTK_SEQ.out.fastx
    )

    GETCIRCULARREADS.out.fastq
        .map { meta, fastq -> [ meta + [single_end: true], fastq ] }
        .set { ch_circular_fastq }

    MINIMAP2_ALIGN (
        ch_circular_fastq,
        fasta_meta,
        false,
        '',
        false,
        false
    )
    ch_versions = ch_versions.mix(MINIMAP2_ALIGN.out.versions_minimap2)

    emit:
    versions = ch_versions
}
