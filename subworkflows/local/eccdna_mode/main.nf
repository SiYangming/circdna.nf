//
// eccDNA Mode Subworkflow (Illumina eccDNA detection)
// Contains: BAM preprocessing + mosdepth + Circle-Map
//

include { BAM_PREPROCESSING  } from '../bam_preprocessing/main'
include { MOSDEPTH           } from '../../../modules/nf-core/mosdepth/main'
include { CIRCLE_MAP_PIPELINE } from '../circle_map_pipeline/main'

workflow ECCDNA_MODE {
    take:
    reads
    bwa_index
    fasta_meta
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
    circle_map_bed    = ch_circle_map_bed
    fasta_fai         = BAM_PREPROCESSING.out.fasta_fai
    versions          = ch_versions
}
