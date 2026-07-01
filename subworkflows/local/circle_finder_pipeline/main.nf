//
// Circle-Finder Pipeline Subworkflow
// Contains: SAMTOOLS_SORT_QNAME, SAMBLASTER, BEDTOOLS_SPLITBAM2BED, BEDTOOLS_SORTEDBAM2BED, CIRCLEFINDER
//

include { SAMTOOLS_SORT as SAMTOOLS_SORT_QNAME_CF }   from '../../../modules/nf-core/samtools/sort/main'
include { SAMBLASTER                                }     from '../../../modules/nf-core/samblaster/main'
include { BEDTOOLS_SORTEDBAM2BED                    }     from '../../../modules/local/bedtools/sortedbam2bed/main'
include { BEDTOOLS_SPLITBAM2BED                     }     from '../../../modules/local/bedtools/splitbam2bed/main'
include { CIRCLEFINDER                              }     from '../../../modules/local/circlefinder/main'

workflow CIRCLE_FINDER_PIPELINE {
    take:
    _bam_sorted              // channel: [ val(meta), path(bam) ] (unused)
    _bam_sorted_bai          // channel: [ val(meta), path(bai) ] (unused)
    full_bam_sorted         // channel: [ val(meta), path(bam) ]
    full_bam_sorted_bai     // channel: [ val(meta), path(bai) ]

    main:
    ch_versions = channel.empty()

    SAMTOOLS_SORT_QNAME_CF (
        full_bam_sorted,
        channel.empty(),
        ''
    )
    ch_versions = ch_versions.mix(SAMTOOLS_SORT_QNAME_CF.out.versions_samtools)

    SAMBLASTER (
        SAMTOOLS_SORT_QNAME_CF.out.bam
    )
    ch_versions = ch_versions.mix(SAMBLASTER.out.versions)

    BEDTOOLS_SPLITBAM2BED (
        SAMBLASTER.out.bam
    )
    ch_versions = ch_versions.mix(BEDTOOLS_SPLITBAM2BED.out.versions)

    BEDTOOLS_SORTEDBAM2BED (
        full_bam_sorted.join(full_bam_sorted_bai)
    )
    ch_versions = ch_versions.mix(BEDTOOLS_SORTEDBAM2BED.out.versions)

    ch_b2b_sorted = BEDTOOLS_SORTEDBAM2BED.out.conc_txt
    ch_b2b_split = BEDTOOLS_SPLITBAM2BED.out.split_txt
    CIRCLEFINDER (
        ch_b2b_split.join(ch_b2b_sorted)
    )

    emit:
    versions = ch_versions
}
