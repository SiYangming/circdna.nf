include { BEDTOOLS_INTERSECT } from '../../../modules/nf-core/bedtools/intersect/main'
include { BEDTOOLS_INTERSECT as BEDTOOLS_INTERSECT_REPEATS } from '../../../modules/nf-core/bedtools/intersect/main'
include { FILTER_ECCDNA_BY_SUPPORT } from '../../../modules/local/filter_eccdna_by_support/main'

workflow LONG_READ_FILTERING {
    take:
    eccdna_candidates    // channel: [ val(meta), bed_file ]

    main:
    ch_versions = channel.empty()

    // 1. Filter by minimum read support
    FILTER_ECCDNA_BY_SUPPORT ( eccdna_candidates, params.min_read_support )
        .filtered
        .set { support_filtered }
    ch_versions = ch_versions.mix(FILTER_ECCDNA_BY_SUPPORT.out.versions)

    // 2. Blacklist filtering
    if ( params.blacklist_bed ) {
        BEDTOOLS_INTERSECT (
            support_filtered.map { meta, bed -> [ meta, bed, file(params.blacklist_bed) ] },
            [[:], []]
        )
            .intersect
            .set { filtered_candidates }
        ch_versions = ch_versions.mix(BEDTOOLS_INTERSECT.out.versions_bedtools)
    } else {
        support_filtered
            .set { filtered_candidates }
    }

    // 3. Repeats filtering
    if ( params.repeats_bed ) {
        BEDTOOLS_INTERSECT_REPEATS (
            filtered_candidates.map { meta, bed -> [ meta, bed, file(params.repeats_bed) ] },
            [[:], []]
        )
            .intersect
            .set { filtered_candidates }
        ch_versions = ch_versions.mix(BEDTOOLS_INTERSECT_REPEATS.out.versions_bedtools)
    }

    emit:
    filtered_candidates = filtered_candidates    // channel: [ val(meta), filtered_bed ]
    versions            = ch_versions
}
