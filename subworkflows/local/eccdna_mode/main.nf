//
// eccDNA Mode Subworkflow (Illumina eccDNA detection)
// Contains: BAM preprocessing + mosdepth + ECCsplorer + Circle-Map
//
// Note: ECCsplorer 使用 FASTQ 作为输入（内部调用 segemehl 比对），
//       不接受预比对的 BAM，因此直接消费原始 reads 通道。
//

include { BAM_PREPROCESSING  } from '../bam_preprocessing/main'
include { MOSDEPTH           } from '../../../modules/nf-core/mosdepth/main'
include { ECCSPLORER         } from '../../../modules/local/eccsplorer/main'
include { CIRCLE_MAP_PIPELINE } from '../circle_map_pipeline/main'

workflow ECCDNA_MODE {
    take:
    reads
    bwa_index
    fasta_meta
    run_eccsplorer
    run_circle_map

    main:
    ch_versions = channel.empty()

    BAM_PREPROCESSING (
        reads,
        bwa_index,
        fasta_meta,
        true
    )
    ch_versions = ch_versions.mix(BAM_PREPROCESSING.out.versions)

    ch_bam_bai = BAM_PREPROCESSING.out.bam_sorted
        .join(BAM_PREPROCESSING.out.bam_sorted_bai)
        .map { meta, bam, bai -> [meta, bam, bai] }

    ch_fai_only = BAM_PREPROCESSING.out.fai.map { meta, fai -> fai }

    MOSDEPTH (
        ch_bam_bai,
        ch_fai_only.collect()
    )
    ch_versions = ch_versions.mix(MOSDEPTH.out.versions_mosdepth)

    // ECCsplorer 接收 FASTQ reads（非 BAM）+ 参考基因组 FASTA
    // 使用 reads 通道（与 BAM_PREPROCESSING 共享同一输入源）
    // reads 通道结构: [meta, [r1, r2]]，combine fasta 后形成 [meta, [r1, r2], fasta]
    ch_eccsplorer_fasta = fasta_meta.map { meta, fasta -> fasta }.first()

    if (run_eccsplorer) {
        ECCSPLORER (
            reads.combine(ch_eccsplorer_fasta)
        )
        ch_versions = ch_versions.mix(ECCSPLORER.out.versions)
        ch_eccsplorer_bed = ECCSPLORER.out.candidates_bed
    } else {
        ch_eccsplorer_bed = channel.empty()
    }

    if (run_circle_map) {
        CIRCLE_MAP_PIPELINE (
            BAM_PREPROCESSING.out.bam_sorted,
            BAM_PREPROCESSING.out.bam_sorted_bai,
            BAM_PREPROCESSING.out.fasta_fai,
            true,
            false
        )
        ch_versions = ch_versions.mix(CIRCLE_MAP_PIPELINE.out.versions)
        ch_circle_map_bed = CIRCLE_MAP_PIPELINE.out.bed
    } else {
        ch_circle_map_bed = channel.empty()
    }

    emit:
    bam_sorted        = BAM_PREPROCESSING.out.bam_sorted
    bam_sorted_bai    = BAM_PREPROCESSING.out.bam_sorted_bai
    mosdepth_bed      = MOSDEPTH.out.regions_bed
    mosdepth_summary  = MOSDEPTH.out.summary
    mosdepth_dist     = MOSDEPTH.out.global_dist
    eccsplorer_bed    = ch_eccsplorer_bed
    circle_map_bed    = ch_circle_map_bed
    fasta_fai         = BAM_PREPROCESSING.out.fasta_fai
    versions          = ch_versions
}
