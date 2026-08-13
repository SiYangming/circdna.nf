//
// ECC_FINDER_PIPELINE Subworkflow
// Routes eccDNA detection to the correct ecc_finder process based on platform/method.
// Currently only platform=sr is activated. platform=ont is reserved for circdnalr.
//

include { ECC_FINDER_MAP_SR  } from '../../../modules/local/ecc_finder/map_sr/main'
include { ECC_FINDER_ASM_SR  } from '../../../modules/local/ecc_finder/asm_sr/main'
include { ECC_FINDER_MAP_ONT } from '../../../modules/local/ecc_finder/map_ont/main'
include { ECC_FINDER_ASM_ONT } from '../../../modules/local/ecc_finder/asm_ont/main'

workflow ECC_FINDER_PIPELINE {
    take:
    reads           // channel: [meta, [r1, r2]]
    bwa_index       // channel: [meta, idx_dir]
    fasta_meta      // channel: [meta, ref_fasta]
    run_map         // boolean
    run_asm         // boolean
    platform        // val: 'sr' (default) or 'ont' (reserved)

    main:
    ch_versions = channel.empty()

    if (platform == 'sr') {
        // --- Illumina short-read branch ---
        ch_r1 = reads.map { meta, r -> [meta, r instanceof List ? r[0] : r] }
        ch_r2 = reads.map { meta, r -> [meta, r instanceof List ? r[1] : r[0]] }

        if (run_map) {
            ECC_FINDER_MAP_SR ( bwa_index, ch_r1, ch_r2, fasta_meta )
            ch_versions = ch_versions.mix(ECC_FINDER_MAP_SR.out.versions_ecc_finder)
        }

        if (run_asm) {
            ECC_FINDER_ASM_SR ( ch_r1, ch_r2 )
            ch_versions = ch_versions.mix(ECC_FINDER_ASM_SR.out.versions_ecc_finder)
        }

    } else if (platform == 'ont') {
        // --- ONT long-read branch (reserved for circdnalr) ---
        // Requires minimap2 index (not BWA) and single-end FASTQ
        // ch_query = reads.map { meta, r -> [meta, r instanceof List ? r[0] : r] }
        // if (run_map) { ECC_FINDER_MAP_ONT ( ont_index, ch_query, fasta_meta ) }
        // if (run_asm) { ECC_FINDER_ASM_ONT ( ch_query ) }
    }

    emit:
    versions = ch_versions
}
