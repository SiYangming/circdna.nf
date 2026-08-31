//
// ECC_FINDER_PIPELINE Subworkflow
// Routes eccDNA detection to the correct ecc_finder process based on platform/method.
// - platform 'sr' (short-read / Illumina): map + asm via BWA index
// - platform 'ont'/'pacbio' (long-read): map (minimap2 built internally) + asm
//

include { ECC_FINDER_MAP_SR  } from '../../../modules/local/ecc_finder/map_sr/main'
include { ECC_FINDER_ASM_SR  } from '../../../modules/local/ecc_finder/asm_sr/main'
include { ECC_FINDER_MAP_ONT } from '../../../modules/local/ecc_finder/map_ont/main'
include { ECC_FINDER_ASM_ONT } from '../../../modules/local/ecc_finder/asm_ont/main'

workflow ECC_FINDER_PIPELINE {
    take:
    reads           // channel: [meta, reads] — PE short reads or SE long reads
    bwa_index       // channel: [meta, idx_dir] — SR only (ignored for long-read)
    fasta_meta      // channel: [meta, ref_fasta] — reference genome (SR and long-read)
    run_map         // boolean
    run_asm         // boolean
    platform        // val: 'sr' | 'ont' | 'pacbio'

    main:
    ch_versions    = channel.empty()
    all_candidates = channel.empty()

    // Normalize the reference channel to [ meta, fasta ] — workflows/circdna.nf
    // passes a bare file channel.
    ch_ref = fasta_meta.map { it ->
        (it instanceof List && it.size() == 2 && it[0] instanceof Map)
            ? it
            : [ [id: 'genome'], it instanceof List ? it[0] : it ]
    }

    if (platform in ['ont', 'pacbio']) {
        // --- Long-read branch (single-end FASTQ) ---
        ch_query = reads.map { meta, r -> [meta, r instanceof List ? r[0] : r] }

        if (run_map) {
            // map-ont builds the minimap2 index internally from the reference fasta.
            ECC_FINDER_MAP_ONT ( ch_ref, ch_query, ch_ref )
            all_candidates = all_candidates.mix(ECC_FINDER_MAP_ONT.out.csv)
            ch_versions    = ch_versions.mix(ECC_FINDER_MAP_ONT.out.versions_ecc_finder)
        }

        if (run_asm) {
            ECC_FINDER_ASM_ONT ( ch_query )
            all_candidates = all_candidates.mix(ECC_FINDER_ASM_ONT.out.fasta)
            ch_versions    = ch_versions.mix(ECC_FINDER_ASM_ONT.out.versions_ecc_finder)
        }

    } else {
        // --- Illumina short-read branch ---
        ch_r1 = reads.map { meta, r -> [meta, r instanceof List ? r[0] : r] }
        ch_r2 = reads.map { meta, r -> [meta, r instanceof List ? r[1] : r[0]] }

        if (run_map) {
            ECC_FINDER_MAP_SR ( bwa_index, ch_r1, ch_r2, ch_ref )
            all_candidates = all_candidates.mix(ECC_FINDER_MAP_SR.out.csv)
            ch_versions    = ch_versions.mix(ECC_FINDER_MAP_SR.out.versions_ecc_finder)
        }

        if (run_asm) {
            ECC_FINDER_ASM_SR ( ch_r1, ch_r2 )
            all_candidates = all_candidates.mix(ECC_FINDER_ASM_SR.out.fasta)
            ch_versions    = ch_versions.mix(ECC_FINDER_ASM_SR.out.versions_ecc_finder)
        }
    }

    emit:
    eccdna_candidates = all_candidates    // channel: [ val(meta), file ] — CSV (map) and/or FASTA (asm)
    versions          = ch_versions       // topic channel
}
