include { BEDTOOLS_INTERSECT } from '../../../modules/nf-core/bedtools/intersect/main'
include { FILTER_ECCDNA_BY_SUPPORT } from '../../../modules/local/filter_eccdna_by_support/main'

workflow LONG_READ_FILTERING {
    take:
    eccdna_candidates    // channel: [ val(meta), bed_file ] — unified BED contract

    main:
    ch_versions = channel.empty()

    // 1. Filter by minimum read support
    FILTER_ECCDNA_BY_SUPPORT ( eccdna_candidates, params.min_read_support )
        .filtered
        .set { support_filtered }
    ch_versions = ch_versions.mix(FILTER_ECCDNA_BY_SUPPORT.out.versions)

    // 2. Blacklist filtering (hard filter is still allowed, §4.6)
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

    // 3. Repeats → ANNOTATE (te_overlap column), never hard-deleted (§4.6)
    if ( params.repeats_bed ) {
        REPEATS_ANNOTATE (
            filtered_candidates.map { meta, bed -> [ meta, bed, file(params.repeats_bed) ] }
        )
            .annotated
            .set { filtered_candidates }
        ch_versions = ch_versions.mix(REPEATS_ANNOTATE.out.versions)
    }

    emit:
    filtered_candidates = filtered_candidates    // channel: [ val(meta), filtered_bed ]
    versions            = ch_versions
}

process REPEATS_ANNOTATE {
    tag "$meta.id"
    label 'process_low'

    conda "${projectDir}/modules/local/ecc_finder_slim/environment.yml"
    container "quay.io/biocontainers/python:3.12.12"

    input:
    tuple val(meta), path(bed), path(repeats)

    output:
    tuple val(meta), path("${prefix}.te_annotated.bed"), emit: annotated
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    annotate_te_overlap.py \\
        --candidates ${bed} \\
        --repeats ${repeats} \\
        --out ${prefix}.te_annotated.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        annotate_te_overlap: 1.0.0
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    cp ${bed} ${prefix}.te_annotated.bed
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        annotate_te_overlap: 1.0.0
    END_VERSIONS
    """
}
