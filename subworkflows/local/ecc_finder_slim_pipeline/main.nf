//
// ECC_FINDER_slim — 原子化 eccDNA 检测子工作流 (MAP_SR + ASM_SR)
// 复用 BAM_PREPROCESSING 产出的 sorted BAM，跳过 BWA 重复比对。
// vs 原版 ECC_FINDER_PIPELINE 的关键差异：
//   - MAP_SR: 不再从 FASTQ 做 BWA 比对，直接使用已比对好的 BAM
//   - ASM_SR: 使用 nf-core unicycler 替代 ecc_finder 内置的 unicycler
// 依赖的 bio.nf 模块：genrich, tidehunter, ecc_finder_slim/*
//

include { SAMTOOLS_SORT as SAMTOOLS_SORT_NAME } from '../../../modules/nf-core/samtools/sort/main'
include { GENRICH              } from '../../../modules/local/genrich/main'
include { ECC_FINDER_SPLIT_DETECT } from '../../../modules/local/ecc_finder_slim/split_detect/main'
include { ECC_FINDER_MERGE_SCORE } from '../../../modules/local/ecc_finder_slim/merge_score/main'
include { ECC_FINDER_DISTRIBUTION } from '../../../modules/local/ecc_finder_slim/distribution/main'
include { UNICYCLER            } from '../../../modules/nf-core/unicycler/main'
include { ECC_FINDER_ASM_FILTER } from '../../../modules/local/ecc_finder_slim/asm_filter/main'

workflow ECC_FINDER_SLIM_PIPELINE {
    take:
    bam_sorted                     // channel: [meta, bam] (from BAM_PREPROCESSING)
    bam_sorted_bai                 // channel: [meta, bai]
    fasta_meta                     // channel: [meta, ref_fasta]
    reads                          // channel: [meta, [r1, r2]] (ASM_SR needs FASTQ)
    run_map_sr                     // boolean: enable MAP_SR slim
    run_asm_sr                     // boolean: enable ASM_SR slim

    main:
    ch_versions = channel.empty()

    // ================================================================
    // MAP_SR: name-sort BAM → Genrich (peak calling) → TideHunter (split-read)
    //          → Merge + Score → eccDNA candidates (CSV + FASTA)
    // ================================================================
    if (run_map_sr) {
        // Name-sort for Genrich (requires name-sorted input, ext.args='-n' in modules.config)
        // NOTE: name-sorted BAM cannot be indexed (coordinate order required);
        //       neither Genrich nor TideHunter needs an index.
        SAMTOOLS_SORT_NAME (
            bam_sorted,
            fasta_meta.map { meta, fa -> [ meta, fa, [] ] },
            ''    // index_format: not needed
        )
        ch_versions = ch_versions.mix(SAMTOOLS_SORT_NAME.out.versions_samtools)

        def ch_name_sorted = SAMTOOLS_SORT_NAME.out.bam

        // Genrich: detect enrichment sites
        GENRICH ( ch_name_sorted )
        ch_versions = ch_versions.mix(GENRICH.out.versions)

        // Split/discordant-read detection (pybedtools, replicates map-sr.py run_split/run_disc)
        ECC_FINDER_SPLIT_DETECT ( ch_name_sorted )
        ch_versions = ch_versions.mix(ECC_FINDER_SPLIT_DETECT.out.versions)

        // Merge enrichment + split + discordant reads → eccDNA candidates
        ECC_FINDER_MERGE_SCORE (
            GENRICH.out.bed,
            ECC_FINDER_SPLIT_DETECT.out.split_bed,
            ECC_FINDER_SPLIT_DETECT.out.disc_bed,
            fasta_meta.map { _meta, f -> [ [id:'genome'], f ] }
        )
        ch_versions = ch_versions.mix(ECC_FINDER_MERGE_SCORE.out.versions)

        // Candidate size distribution (map-sr.py distribution.png)
        ECC_FINDER_DISTRIBUTION ( ECC_FINDER_MERGE_SCORE.out.csv )
        ch_versions = ch_versions.mix(ECC_FINDER_DISTRIBUTION.out.versions)
    }

    // ================================================================
    // ASM_SR: de novo assembly via nf-core unicycler → filter
    // ================================================================
    if (run_asm_sr) {
        ch_shortreads = reads.map { meta, r ->
            def rlist = r instanceof List ? r : [r]
            [meta, rlist, []]
        }
        UNICYCLER ( ch_shortreads )
        ch_versions = ch_versions.mix(UNICYCLER.out.versions)

        // Filter assembly for eccDNA candidates
        ECC_FINDER_ASM_FILTER ( UNICYCLER.out.scaffolds )
        ch_versions = ch_versions.mix(ECC_FINDER_ASM_FILTER.out.versions)
    }

    emit:
    map_csv         = run_map_sr ? ECC_FINDER_MERGE_SCORE.out.csv    : channel.empty()
    map_fasta       = run_map_sr ? ECC_FINDER_MERGE_SCORE.out.fasta  : channel.empty()
    genrich_bed     = run_map_sr ? GENRICH.out.bed                   : channel.empty()
    split_bed       = run_map_sr ? ECC_FINDER_SPLIT_DETECT.out.split_bed : channel.empty()
    asm_fasta       = run_asm_sr ? ECC_FINDER_ASM_FILTER.out.fasta   : channel.empty()
    unicycler_scaffolds = run_asm_sr ? UNICYCLER.out.scaffolds        : channel.empty()
    versions        = ch_versions
}
