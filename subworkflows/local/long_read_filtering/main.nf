include { BEDTOOLS_INTERSECT } from '../../../modules/local/bedtools/intersect/main'

workflow LONG_READ_FILTERING {
    take:
    eccdna_candidates    // channel: [ val(meta), bed_file ]

    main:
    if ( params.blacklist_bed ) {
        BEDTOOLS_INTERSECT ( eccdna_candidates, file(params.blacklist_bed) )
            .non_overlapping_bed
            .set { filtered_candidates }
    } else {
        eccdna_candidates
            .set { filtered_candidates }
    }

    if ( params.repeats_bed ) {
        BEDTOOLS_INTERSECT ( filtered_candidates, file(params.repeats_bed) )
            .non_overlapping_bed
            .set { filtered_candidates }
    }

    emit:
    filtered_candidates    // channel: [ val(meta), filtered_bed ]
}