//
// Run SAMtools stats, flagstat and idxstats
//

include { SAMTOOLS_STATS    } from '../../../modules/nf-core/samtools/stats/main'
include { SAMTOOLS_IDXSTATS } from '../../../modules/nf-core/samtools/idxstats/main'
include { SAMTOOLS_FLAGSTAT } from '../../../modules/nf-core/samtools/flagstat/main'

workflow BAM_STATS_SAMTOOLS {
    take:
    ch_bam_bai // channel: [ val(meta), path(bam), path(bai) ]
    ch_fasta   // channel: [ val(meta), path(fasta) ]

    main:
    ch_versions = channel.empty()

    SAMTOOLS_STATS ( ch_bam_bai, ch_fasta )
    ch_versions = ch_versions.mix(SAMTOOLS_STATS.out.versions_samtools)

    SAMTOOLS_FLAGSTAT ( ch_bam_bai )
    ch_versions = ch_versions.mix(SAMTOOLS_FLAGSTAT.out.versions_samtools)

    SAMTOOLS_IDXSTATS ( ch_bam_bai )
    ch_versions = ch_versions.mix(SAMTOOLS_IDXSTATS.out.versions_samtools)

    ch_multiqc_files = channel.empty()
        .mix(SAMTOOLS_STATS.out.stats)
        .mix(SAMTOOLS_FLAGSTAT.out.flagstat)
        .mix(SAMTOOLS_IDXSTATS.out.idxstats)
        .transpose().map { row -> row[1] }

    emit:
    stats         = SAMTOOLS_STATS.out.stats       // channel: [ val(meta), path(stats) ]
    flagstat      = SAMTOOLS_FLAGSTAT.out.flagstat // channel: [ val(meta), path(flagstat) ]
    idxstats      = SAMTOOLS_IDXSTATS.out.idxstats // channel: [ val(meta), path(idxstats) ]
    multiqc_files = ch_multiqc_files               // channel: path
    versions      = ch_versions                    // channel: [ path(versions.yml) ]
}
