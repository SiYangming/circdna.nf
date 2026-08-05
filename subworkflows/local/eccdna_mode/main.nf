//
// eccDNA Mode Subworkflow (Illumina eccDNA detection)
// Contains: BAM preprocessing + mosdepth + ECCsplorer + Circle-Map
//
// Supports both FASTQ and BAM input modes:
//   - FASTQ mode: ECCsplorer receives original FASTQ reads
//   - BAM mode: ECCsplorer receives pre-sorted BAM (auto-converts to FASTQ via samtools fastq)
//

include { BAM_PREPROCESSING  } from '../bam_preprocessing/main'
include { MOSDEPTH           } from '../../../modules/nf-core/mosdepth/main'
include { ECCSPLORER         } from '../../../modules/local/eccsplorer/main'
include { ECCSPLORER_WITH_CONTROL } from '../../../modules/local/eccsplorer/main'
include { CIRCLE_MAP_PIPELINE } from '../circle_map_pipeline/main'

workflow ECCDNA_MODE {
    take:
    reads
    bwa_index
    fasta_meta
    run_eccsplorer
    run_circle_map
    input_format
    control_reads

    main:
    ch_versions = channel.empty()

    BAM_PREPROCESSING (
        reads,
        bwa_index,
        fasta_meta,
        input_format == 'FASTQ'
    )
    ch_versions = ch_versions.mix(BAM_PREPROCESSING.out.versions)

    ch_bam_bai = BAM_PREPROCESSING.out.bam_sorted
        .join(BAM_PREPROCESSING.out.bam_sorted_bai)
        .map { meta, bam, bai -> [meta, bam, bai] }

    ch_fai_only = BAM_PREPROCESSING.out.fai.map { _meta, fai -> fai }

    MOSDEPTH (
        ch_bam_bai,
        ch_fai_only.collect()
    )
    ch_versions = ch_versions.mix(MOSDEPTH.out.versions_mosdepth)

    // ECCsplorer 接收 reads + 参考基因组 FASTA
    // FASTQ 模式: 传递原始 reads（[meta, [r1, r2]]）
    // BAM 模式: 传递 BAM_PREPROCESSING 产出的 sorted BAM（模块通过 samtools fastq 自动转换）
    ch_eccsplorer_fasta = fasta_meta.map { _meta, fasta -> fasta }

    if (run_eccsplorer) {
        // Prepare eccDNA reads for ECCsplorer: [meta, reads, fasta]
        if (input_format == 'BAM') {
            ch_eccdna_for_eccsplorer = BAM_PREPROCESSING.out.bam_sorted.combine(ch_eccsplorer_fasta)
        } else {
            ch_eccdna_for_eccsplorer = reads.combine(ch_eccsplorer_fasta)
        }

        // Key eccDNA by group for join: [group, meta, reads, fasta]
        ch_eccdna_keyed = ch_eccdna_for_eccsplorer
            .map { e_meta, e_reads, e_fasta -> [e_meta.group ?: '', e_meta, e_reads, e_fasta] }

        // Key gDNA by group for join: [group, reads]
        ch_gdna_keyed = control_reads
            .map { c_meta, c_reads -> [c_meta.group ?: '', c_reads] }

        // Join by group (remainder: true keeps unmatched eccDNA with null control)
        // Matched:   [group, e_meta, e_reads, e_fasta, c_reads] (5 elements, c_reads non-null)
        // Unmatched: [group, e_meta, e_reads, e_fasta, null]    (5 elements, c_reads is null)
        ch_eccdna_joined = ch_eccdna_keyed.join(ch_gdna_keyed, remainder: true)

        // With control: tuples where c_reads (5th element) is non-null
        ch_eccdna_with_control = ch_eccdna_joined
            .filter { row -> row.size() >= 5 && row[4] != null }
            .map { group, e_meta, e_reads, e_fasta, c_reads ->
                def r = c_reads instanceof List ? c_reads : [c_reads]
                def cr1 = r.size() > 0 ? r[0] : c_reads
                def cr2 = r.size() > 1 ? r[1] : cr1
                [e_meta, e_reads, cr1, cr2, e_fasta]
            }

        // Without control: tuples where c_reads is null or missing
        ch_eccdna_without_control = ch_eccdna_joined
            .filter { row -> row.size() < 5 || row[4] == null }
            .map { row -> [row[1], row[2], row[3]] }

        ECCSPLORER_WITH_CONTROL ( ch_eccdna_with_control )
        ECCSPLORER ( ch_eccdna_without_control )

        ch_versions = ch_versions.mix(ECCSPLORER.out.versions, ECCSPLORER_WITH_CONTROL.out.versions)
        ch_eccsplorer_bed = ECCSPLORER.out.candidates_bed.mix(ECCSPLORER_WITH_CONTROL.out.candidates_bed)
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
