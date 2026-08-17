//
// Reference Mode Subworkflow (gDNA Background Analysis)
// Contains: BAM preprocessing + mosdepth depth analysis + repeat annotation
//

include { BAM_PREPROCESSING } from '../bam_preprocessing/main'
include { MOSDEPTH          } from '../../../modules/nf-core/mosdepth/main'

workflow REFERENCE_MODE {
    take:
    reads          // channel: [ val(meta), [ reads ] ]
    bwa_index      // channel: [ "bwa_index", index_dir ]
    fasta_meta     // channel: [ val(meta), path(fasta) ]
    _repeat_gff     // channel: [ path(repeat_gff) ] or channel.empty()

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

    ch_fai_only = BAM_PREPROCESSING.out.fai.map { _meta, fai -> fai }

    MOSDEPTH (
        ch_bam_bai,
        ch_fai_only.collect()
    )
    ch_versions = ch_versions.mix(MOSDEPTH.out.versions_mosdepth)

    emit:
    bam_sorted        = BAM_PREPROCESSING.out.bam_sorted
    bam_sorted_bai    = BAM_PREPROCESSING.out.bam_sorted_bai
    mosdepth_bed      = MOSDEPTH.out.regions_bed
    mosdepth_summary  = MOSDEPTH.out.summary
    mosdepth_dist     = MOSDEPTH.out.global_dist
    fasta_fai         = BAM_PREPROCESSING.out.fasta_fai
    versions          = ch_versions
}
