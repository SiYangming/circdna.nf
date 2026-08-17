include { BEDTOOLS_INTERSECT } from '../../../modules/local/bedtools/intersect/main'
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
        BEDTOOLS_INTERSECT ( support_filtered, file(params.blacklist_bed) )
            .non_overlapping_bed
            .set { filtered_candidates }
        ch_versions = ch_versions.mix(BEDTOOLS_INTERSECT.out.versions)
    } else {
        support_filtered
            .set { filtered_candidates }
    }

    // 3. Repeats filtering
    if ( params.repeats_bed ) {
        BEDTOOLS_INTERSECT ( filtered_candidates, file(params.repeats_bed) )
            .non_overlapping_bed
            .set { filtered_candidates }
        ch_versions = ch_versions.mix(BEDTOOLS_INTERSECT.out.versions)
    }

    emit:
    filtered_candidates = filtered_candidates    // channel: [ val(meta), filtered_bed ]
    versions            = ch_versions
}
