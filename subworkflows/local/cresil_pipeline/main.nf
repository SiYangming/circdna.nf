include { CRESIL_TRIM }      from '../../../modules/local/cresil/trim/main'
include { CRESIL_IDENTIFY }  from '../../../modules/local/cresil/identify/main'
include { CRESIL_IDENTIFY_WGLS } from '../../../modules/local/cresil/identify_wgls/main'
include { CRESIL_ANNOTATE }  from '../../../modules/local/cresil/annotate/main'
include { CRESIL_VISUALIZE } from '../../../modules/local/cresil/visualize/main'
include { SAMTOOLS_FAIDX }   from '../../../modules/nf-core/samtools/faidx/main'
include { MINIMAP2_INDEX }   from '../../../modules/nf-core/minimap2/index/main'

workflow CRESIL_PIPELINE {
    take:
    reads           // channel: [ val(meta), fastq ]
    genome_fasta    // channel: reference genome file

    main:
    ch_versions = channel.empty()

    genome_fasta
        .map { fasta -> [[id: 'genome'], fasta] }
        .set { genome_fasta_meta }

    // 索引由 reads 触发（空输入不建索引；Nextflow 26 中 if(ch) 恒 true，
    // 纯短读/空调用时不能让无条件进程执行）
    def ch_idx_trigger = reads.map { meta, _fq -> meta }.first()
    def ch_faidx_input = ch_idx_trigger
        .combine(genome_fasta_meta)
        .map { _m_trigger, m_fasta, fa -> [m_fasta, fa, []] }
    def ch_mmi_input = ch_idx_trigger
        .combine(genome_fasta_meta)
        .map { _m_trigger, m_fasta, fa -> [m_fasta, fa] }

    SAMTOOLS_FAIDX ( ch_faidx_input, false )
    ch_versions = ch_versions.mix(SAMTOOLS_FAIDX.out.versions_samtools)
    ch_fai = SAMTOOLS_FAIDX.out.fai
        .map { meta, fai -> [ meta, fai ] }

    // Build minimap2 .mmi index (cresil identify_wgls needs it; trim uses it too).
    MINIMAP2_INDEX ( ch_mmi_input )
    ch_versions = ch_versions.mix(MINIMAP2_INDEX.out.versions_minimap2)
    ch_mmi = MINIMAP2_INDEX.out.index
        .map { meta, mmi -> [ meta, mmi ] }

    // Pass the reference genome (gz is fine: mappy and pysam handle it) to
    // cresil trim; the module decompresses gzipped reads to .fastq itself.
    CRESIL_TRIM ( reads, genome_fasta_meta )
        .trim
        .set { trimmed_reads }
    ch_versions = ch_versions.mix(CRESIL_TRIM.out.versions_cresil)

    CRESIL_IDENTIFY ( genome_fasta_meta, ch_fai, reads, trimmed_reads )
        .identify
        .set { eccdna_candidates }
    ch_versions = ch_versions.mix(CRESIL_IDENTIFY.out.versions_cresil)

    // Whole-genome long-read (WGLS) identification: takes the .mmi index.
    CRESIL_IDENTIFY_WGLS ( ch_mmi, genome_fasta_meta, ch_fai, reads, trimmed_reads )
        .identify_wgls
        .set { eccdna_candidates_wgls }
    ch_versions = ch_versions.mix(CRESIL_IDENTIFY_WGLS.out.versions_cresil)

    // Annotate the standard identify output (gene/CpG/repeat/variant).
    // Optional annotation beds default to an empty tuple so the process
    // still runs even when no annotation files are provided.
    ch_empty_bed = Channel.of([[:], []])
    CRESIL_ANNOTATE ( eccdna_candidates, ch_empty_bed, ch_empty_bed, ch_empty_bed )
    ch_versions = ch_versions.mix(CRESIL_ANNOTATE.out.versions_cresil)

    // Visualize the first eccDNA in the identify table (Circos config files).
    eccdna_candidates
        .map { meta, table ->
            def id = 'ec1'
            [ meta, table, id ]
        }
        .set { ch_visualize_input }

    CRESIL_VISUALIZE (
        eccdna_candidates,
        CRESIL_ANNOTATE.out.gene_annot,
        CRESIL_ANNOTATE.out.cpg_annot,
        CRESIL_ANNOTATE.out.repeat_annot,
        CRESIL_ANNOTATE.out.variant_annot,
        ch_visualize_input.map { meta, table, id -> id }
    )
    ch_versions = ch_versions.mix(CRESIL_VISUALIZE.out.versions_cresil)

    emit:
    eccdna_candidates      = eccdna_candidates         // channel: [ val(meta), eccdna_final.txt ]
    eccdna_candidates_wgls = eccdna_candidates_wgls    // channel: [ val(meta), eccdna_final.txt ] (WGLS)
    circos_config          = CRESIL_VISUALIZE.out.circos_config
    versions               = ch_versions
}
