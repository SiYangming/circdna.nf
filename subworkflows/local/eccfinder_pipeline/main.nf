//
// ecc_finder pipeline — fourth eccDNA detection engine
// Supports mapping-based (map) and assembly-based (asm) eccDNA detection
// for ONT and PacBio long-read data.
//

include { ECC_FINDER_MAP_ONT } from '../../../modules/local/ecc_finder/map_ont/main'
include { ECC_FINDER_MAP_SR  } from '../../../modules/local/ecc_finder/map_sr/main'
include { ECC_FINDER_ASM_ONT } from '../../../modules/local/ecc_finder/asm_ont/main'
include { ECC_FINDER_ASM_SR  } from '../../../modules/local/ecc_finder/asm_sr/main'

workflow ECCFINDER_PIPELINE {
    take:
    reads           // channel: [ val(meta), fastq ]
    genome_fasta    // channel: reference genome file

    main:
    def mode = params.eccfinder_mode   // map | asm | both

    // Reference genome channel with meta for ecc_finder map modules
    genome_fasta
        .map { fasta -> [[id: 'genome'], fasta] }
        .set { genome_meta }

    all_candidates = channel.empty()
    all_versions   = channel.empty()

    // mapping-based eccDNA detection
    if (mode == 'map' || mode == 'both') {
        // ecc_finder map-ont uses minimap2 internally; works for ONT and PacBio long reads.
        ECC_FINDER_MAP_ONT (
            genome_meta,   // idx: reference fasta (ecc_finder builds minimap2 index from it)
            reads,          // query: long reads
            genome_meta     // ref: reference fasta
        )
        all_candidates = all_candidates.mix(ECC_FINDER_MAP_ONT.out.csv)
        all_versions   = all_versions.mix(ECC_FINDER_MAP_ONT.out.versions_ecc_finder)
    }

    // assembly-based eccDNA detection
    if (mode == 'asm' || mode == 'both') {
        // ecc_finder asm-ont works for any long-read data (ONT or PacBio).
        ECC_FINDER_ASM_ONT ( reads )
        all_candidates = all_candidates.mix(ECC_FINDER_ASM_ONT.out.fasta)
        all_versions   = all_versions.mix(ECC_FINDER_ASM_ONT.out.versions_ecc_finder)
    }

    emit:
    eccdna_candidates = all_candidates    // channel: [ val(meta), file ] — CSV (map) and/or FASTA (asm)
    versions          = all_versions      // topic channel
}
