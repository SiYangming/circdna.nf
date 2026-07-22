//
// Circle-Map Pipeline Subworkflow
// Contains: SAMTOOLS_SORT_QNAME, CIRCLEMAP_READEXTRACTOR, SAMTOOLS_SORT_RE, CIRCLEMAP_REALIGN, CIRCLEMAP_REPEATS
//

include { SAMTOOLS_SORT as SAMTOOLS_SORT_QNAME_CM }   from '../../../modules/nf-core/samtools/sort/main'
include { SAMTOOLS_SORT as SAMTOOLS_SORT_RE         }   from '../../../modules/nf-core/samtools/sort/main'
include { SAMTOOLS_INDEX as SAMTOOLS_INDEX_RE       }   from '../../../modules/nf-core/samtools/index/main'
include { CIRCLEMAP_READEXTRACTOR                   }   from '../../../modules/local/circlemap/readextractor/main'
include { CIRCLEMAP_REALIGN                         }   from '../../../modules/local/circlemap/realign/main'
include { CIRCLEMAP_REPEATS                         }   from '../../../modules/local/circlemap/repeats/main'

workflow CIRCLE_MAP_PIPELINE {
    take:
    bam_sorted              // channel: [ val(meta), path(bam) ]
    bam_sorted_bai          // channel: [ val(meta), path(bai) ]
    fasta_meta              // channel: [ val(meta), path(fasta) ]
    fai                     // channel: [ val(meta), path(fai) ]
    run_realign             // boolean: whether to run realign
    run_repeats             // boolean: whether to run repeats

    main:
    ch_versions = channel.empty()

    def ch_fasta_fai = fasta_meta.join(fai)

    SAMTOOLS_SORT_QNAME_CM (
        bam_sorted,
        ch_fasta_fai,
        'bai'
    )
    ch_versions = ch_versions.mix(SAMTOOLS_SORT_QNAME_CM.out.versions_samtools)

    CIRCLEMAP_READEXTRACTOR (
        SAMTOOLS_SORT_QNAME_CM.out.bam
    )
    ch_versions = ch_versions.mix(CIRCLEMAP_READEXTRACTOR.out.versions)

    SAMTOOLS_SORT_RE (
        CIRCLEMAP_READEXTRACTOR.out.bam,
        ch_fasta_fai,
        'bai'
    )
    ch_versions = ch_versions.mix(SAMTOOLS_SORT_RE.out.versions_samtools)

    ch_qname_sorted_bam = SAMTOOLS_SORT_QNAME_CM.out.bam
    ch_qname_sorted_bai = SAMTOOLS_SORT_QNAME_CM.out.index
    ch_re_sorted_bam = SAMTOOLS_SORT_RE.out.bam
    ch_re_sorted_bai = SAMTOOLS_SORT_RE.out.index

    if (run_repeats) {
        CIRCLEMAP_REPEATS (
            ch_re_sorted_bam.join(ch_re_sorted_bai)
        )
        ch_versions = ch_versions.mix(CIRCLEMAP_REPEATS.out.versions)
    }

    if (run_realign) {
        ch_cm_realign_in = ch_re_sorted_bam.join(ch_re_sorted_bai).join(ch_qname_sorted_bam).join(ch_qname_sorted_bai).join(bam_sorted).join(bam_sorted_bai)

        CIRCLEMAP_REALIGN (
            ch_cm_realign_in,
            fasta_meta.map { meta, fasta -> fasta }
        )
        ch_versions = ch_versions.mix(CIRCLEMAP_REALIGN.out.versions)
    }

    emit:
    versions = ch_versions
}
