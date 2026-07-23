//
// BAM Preprocessing Subworkflow
// Contains: BWA_MEM, SAMTOOLS_INDEX, BAM_STATS_SAMTOOLS, BAM_MARKDUPLICATES_PICARD
//

include { BWA_MEM                                   }   from '../../../modules/nf-core/bwa/mem/main'
include { SAMTOOLS_INDEX as SAMTOOLS_INDEX_BAM      }   from '../../../modules/nf-core/samtools/index/main'
include { SAMTOOLS_FAIDX                            }   from '../../../modules/nf-core/samtools/faidx/main'
include { BAM_MARKDUPLICATES_PICARD                 }   from '../../../subworkflows/nf-core/bam_markduplicates_picard/main'
include { SAMTOOLS_VIEW as SAMTOOLS_VIEW_FILTER     }   from '../../../modules/nf-core/samtools/view/main'
include { SAMTOOLS_SORT as SAMTOOLS_SORT_FILTERED   }   from '../../../modules/nf-core/samtools/sort/main'
include { SAMTOOLS_INDEX as SAMTOOLS_INDEX_FILTERED }   from '../../../modules/nf-core/samtools/index/main'
include { BAM_STATS_SAMTOOLS                        }   from '../../../subworkflows/nf-core/bam_stats_samtools/main'

workflow BAM_PREPROCESSING {
    take:
    trimmed_reads          // channel: [ val(meta), [ reads ] ]
    bwa_index              // channel: [ "bwa_index", index_dir ]
    fasta_meta             // channel: [ val(meta), path(fasta) ]
    run_bwa                // boolean: whether to run BWA alignment

    main:
    ch_versions = channel.empty()

    // FAIDX
    SAMTOOLS_FAIDX (
        fasta_meta.map{ meta, fasta -> [meta, fasta, []] },
        channel.value(true)
    )
    ch_versions = ch_versions.mix(SAMTOOLS_FAIDX.out.versions_samtools)
    def ch_fasta_fai = fasta_meta.join(SAMTOOLS_FAIDX.out.fai).map { meta, fasta, fai ->
        [meta, fasta, fai]
    }.first()

    if (run_bwa) {
        // BWA MEM ALIGNMENT
        BWA_MEM (
            trimmed_reads,
            bwa_index,
            fasta_meta,
            channel.value(true)
        )
        ch_bam_sorted   = BWA_MEM.out.bam
        ch_full_bam_sorted   = BWA_MEM.out.bam
        ch_bwa_sorted   = BWA_MEM.out.bam
        ch_versions = ch_versions.mix(BWA_MEM.out.versions_bwa)
        ch_versions = ch_versions.mix(BWA_MEM.out.versions_samtools)

        // SAMTOOLS INDEX SORTED BAM
        SAMTOOLS_INDEX_BAM (
            ch_bam_sorted
        )
        ch_versions = ch_versions.mix(SAMTOOLS_INDEX_BAM.out.versions_samtools)
    } else {
        ch_bam_sorted = trimmed_reads
        ch_full_bam_sorted = trimmed_reads
        ch_bwa_sorted = trimmed_reads
    }

    ch_bam_sorted_bai       = SAMTOOLS_INDEX_BAM.out.index
    ch_full_bam_sorted_bai  = ch_bam_sorted_bai

    // BAM STATS
    if (!workflow.stubRun) {
        ch_bam_bai = ch_bam_sorted.join(ch_bam_sorted_bai).map { meta, bam, bai -> [meta, bam, bai] }
        BAM_STATS_SAMTOOLS (
            ch_bam_bai,
            ch_fasta_fai
        )
        ch_versions = ch_versions.mix(BAM_STATS_SAMTOOLS.out.versions)
        ch_samtools_stats               = BAM_STATS_SAMTOOLS.out.stats
        ch_samtools_flagstat            = BAM_STATS_SAMTOOLS.out.flagstat
        ch_samtools_idxstats            = BAM_STATS_SAMTOOLS.out.idxstats
    } else {
        ch_samtools_stats               = channel.empty()
        ch_samtools_flagstat            = channel.empty()
        ch_samtools_idxstats            = channel.empty()
    }

    // PICARD MARK_DUPLICATES
    if (!params.skip_markduplicates) {
        BAM_MARKDUPLICATES_PICARD (
            ch_bam_sorted,
            ch_fasta_fai
        )

        if (!params.keep_duplicates) {
            SAMTOOLS_VIEW_FILTER (
                ch_bam_sorted.join(ch_bam_sorted_bai),
                ch_fasta_fai,
                channel.empty(),
                channel.empty(),
                []
            )
            ch_versions = ch_versions.mix(SAMTOOLS_VIEW_FILTER.out.versions_samtools)

            SAMTOOLS_SORT_FILTERED (
                SAMTOOLS_VIEW_FILTER.out.bam,
                ch_fasta_fai,
                'bai'
            )
            ch_versions = ch_versions.mix(SAMTOOLS_SORT_FILTERED.out.versions_samtools)

            SAMTOOLS_INDEX_FILTERED (
                SAMTOOLS_SORT_FILTERED.out.bam
            )
            ch_versions = ch_versions.mix(SAMTOOLS_INDEX_FILTERED.out.versions_samtools)

            ch_bam_sorted = SAMTOOLS_SORT_FILTERED.out.bam
            ch_bam_sorted_bai = SAMTOOLS_INDEX_FILTERED.out.index
        } else {
            ch_bam_sorted               = BAM_MARKDUPLICATES_PICARD.out.bam
            ch_bam_sorted_bai           = BAM_MARKDUPLICATES_PICARD.out.index
            ch_markduplicates_stats     = BAM_MARKDUPLICATES_PICARD.out.stats
            ch_markduplicates_flagstat  = BAM_MARKDUPLICATES_PICARD.out.flagstat
            ch_markduplicates_idxstats  = BAM_MARKDUPLICATES_PICARD.out.idxstats
            ch_markduplicates_multiqc   = BAM_MARKDUPLICATES_PICARD.out.metrics
            ch_versions = ch_versions.mix(BAM_MARKDUPLICATES_PICARD.out.versions)
        }
    } else {
        ch_markduplicates_stats         = channel.empty()
        ch_markduplicates_flagstat      = channel.empty()
        ch_markduplicates_idxstats      = channel.empty()
        ch_markduplicates_multiqc       = channel.empty()
    }

    emit:
    bam_sorted               = ch_bam_sorted
    bam_sorted_bai           = ch_bam_sorted_bai
    full_bam_sorted          = ch_full_bam_sorted
    full_bam_sorted_bai      = ch_full_bam_sorted_bai
    samtools_stats           = ch_samtools_stats
    samtools_flagstat        = ch_samtools_flagstat
    samtools_idxstats        = ch_samtools_idxstats
    markduplicates_stats     = ch_markduplicates_stats
    markduplicates_flagstat  = ch_markduplicates_flagstat
    markduplicates_idxstats  = ch_markduplicates_idxstats
    markduplicates_multiqc   = ch_markduplicates_multiqc
    fai                      = SAMTOOLS_FAIDX.out.fai.first()
    fasta_fai                = ch_fasta_fai
    versions                 = ch_versions
}
