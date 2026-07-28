//
// Integrated Mode Subworkflow (gDNA + eccDNA integrated analysis)
// Contains: ECC_SCORE calculation + candidate grading
//

include { ECC_SCORE } from '../../../modules/local/ecc_score/main'

workflow INTEGRATED_MODE {
    take:
    reference_mosdepth_bed   // gDNA depth (channel of [meta, bed])
    eccdna_mosdepth_bed      // eccDNA depth (channel of [meta, bed])
    eccdna_merged_bed        // merged candidates (channel of [meta, bed])
    repeat_bed               // repeat bed file path or null
    w1
    w2
    w3

    main:
    ch_versions = channel.empty()

    // Collect gDNA and eccDNA depth files as value channels (extract bed from [meta, bed] tuples)
    ch_gdna_depth = reference_mosdepth_bed.map { meta, bed -> bed }.collect()
    ch_ecc_depth = eccdna_mosdepth_bed.map { meta, bed -> bed }.collect()

    // Pass eccDNA merged candidates with both depth files
    ch_score_input = eccdna_merged_bed
        .map { meta, merged_bed -> [meta, merged_bed] }

    ECC_SCORE (
        ch_score_input,
        ch_gdna_depth,
        ch_ecc_depth,
        repeat_bed,
        w1,
        w2,
        w3
    )
    ch_versions = ch_versions.mix(ECC_SCORE.out.versions_score)

    emit:
    scored_bed    = ECC_SCORE.out.scored_bed
    versions      = ch_versions
}
