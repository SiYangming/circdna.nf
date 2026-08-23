//
// ECCSPLORER_slim — 原子化 eccDNA 检测子工作流
// 使用 nf-core 标准模块 + 本地自建模块，替代原版 ECCsplorer 黑盒调用。
//
// Phase 1: segemehl index/align → haarz split-read detection
// Phase 2: SAM→BAM→BED → makewindows → coverage → eccDNA analysis chain
//

include { SEGEMEHL_INDEX    } from '../../../modules/nf-core/segemehl/index/main'
include { SEGEMEHL_ALIGN    } from '../../../modules/nf-core/segemehl/align/main'
include { SEGEMEHL_ALIGN as SEGEMEHL_ALIGN_CO } from '../../../modules/nf-core/segemehl/align/main'
include { HAARZ             } from '../../../modules/local/segemehl/haarz/main'

include { SAMTOOLS_VIEW as SAMTOOLS_VIEW_SAM2BAM } from '../../../modules/nf-core/samtools/view/main'
include { SAMTOOLS_VIEW as SAMTOOLS_VIEW_DR_F2   } from '../../../modules/nf-core/samtools/view/main'
include { SAMTOOLS_VIEW as SAMTOOLS_VIEW_DR_F83  } from '../../../modules/nf-core/samtools/view/main'
include { SAMTOOLS_VIEW as SAMTOOLS_VIEW_DR_F163 } from '../../../modules/nf-core/samtools/view/main'
include { SAMTOOLS_SORT    } from '../../../modules/nf-core/samtools/sort/main'
include { SAMTOOLS_FAIDX as SAMTOOLS_FAIDX_WIN  } from '../../../modules/nf-core/samtools/faidx/main'
include { BEDTOOLS_BAMTOBED } from '../../../modules/nf-core/bedtools/bamtobed/main'
include { BEDTOOLS_MAKEWINDOWS } from '../../../modules/nf-core/bedtools/makewindows/main'
include { BEDTOOLS_COVERAGE } from '../../../modules/nf-core/bedtools/coverage/main'

include { ECCSPLORER_PEAK_DETECT } from '../../../modules/local/eccsplorer_slim/peak_detect/main'
include { ECCSPLORER_DR_DETECT } from '../../../modules/local/eccsplorer_slim/dr_detect/main'
include { ECCSPLORER_CANDIDATE_EXTRACT } from '../../../modules/local/eccsplorer_slim/candidate_extract/main'
include { ECCSPLORER_COVERAGE_PROFILE } from '../../../modules/local/eccsplorer_slim/coverage_profile/main'
include { ECCSPLORER_NORMALIZE } from '../../../modules/local/eccsplorer_slim/normalize/main'
include { ECCSPLORER_VISUALIZE } from '../../../modules/local/eccsplorer_slim/visualize/main'
include { ECCSPLORER_HTML_REPORT } from '../../../modules/local/eccsplorer_slim/html_report/main'
include { ECCSPLORER_BLAST_COMBINEDDB as BLAST_COMBINEDDB } from '../../../modules/local/eccsplorer_slim/blast_combineddb/main'
include { ECCSPLORER_BLAST_ANNOTATE as BLAST_ANNOTATE } from '../../../modules/local/eccsplorer_slim/blast_annotate/main'
include { BEDTOOLS_GETFASTA as BEDTOOLS_GETFASTA_CAND } from '../../../modules/nf-core/bedtools/getfasta/main'

include { SAMTOOLS_STATS as SAMTOOLS_STATS_TR } from '../../../modules/nf-core/samtools/stats/main'
include { SAMTOOLS_STATS as SAMTOOLS_STATS_CO } from '../../../modules/nf-core/samtools/stats/main'
include { SAMTOOLS_VIEW as SAMTOOLS_VIEW_SAM2BAM_CO } from '../../../modules/nf-core/samtools/view/main'
include { SAMTOOLS_SORT as SAMTOOLS_SORT_CO } from '../../../modules/nf-core/samtools/sort/main'
include { BEDTOOLS_BAMTOBED as BEDTOOLS_BAMTOBED_CO } from '../../../modules/nf-core/bedtools/bamtobed/main'

workflow ECCSPLORER_SLIM_PIPELINE {
    take:
    reads                    // channel: [meta, [r1, r2]]
    fasta_meta               // channel: [meta, ref_fasta]
    control                  // channel: [meta, [r1, r2]] (optional, may be empty)

    main:
    ch_versions = channel.empty()

    // ================================================================
    // Phase 1: segemehl split-read alignment
    // ================================================================
    def ch_fasta_path = fasta_meta.map { _meta, fasta -> fasta }

    SEGEMEHL_INDEX ( ch_fasta_path )
    SEGEMEHL_ALIGN (
        reads,
        ch_fasta_path,
        SEGEMEHL_INDEX.out.index
    )
    ch_versions = ch_versions.mix(
        SEGEMEHL_INDEX.out.versions,
        SEGEMEHL_ALIGN.out.versions
    )

    // Split-read detection via haarz
    HAARZ ( SEGEMEHL_ALIGN.out.single_bed )
    ch_versions = ch_versions.mix(HAARZ.out.versions)

    // ================================================================
    // Phase 2: SAM → BAM → BED → coverage → analysis chain
    // All tools use nf-core standard containers (not slim images)
    // ================================================================

    // SAM → sorted BAM
    SAMTOOLS_VIEW_SAM2BAM (
        SEGEMEHL_ALIGN.out.alignment.map { meta, sam -> [ meta, sam, [] ] },
        fasta_meta.map { meta, fa -> [ meta, fa, [] ] },
        [[id:'no_qname'], []],
        [[id:'no_bed'], []],
        []
    )
    SAMTOOLS_SORT (
        SAMTOOLS_VIEW_SAM2BAM.out.bam,
        fasta_meta.map { meta, fa -> [ meta, fa, [] ] },
        ''    // index_format: not needed, BEDTOOLS_BAMTOBED consumes BAM directly
    )
    ch_versions = ch_versions.mix(
        SAMTOOLS_VIEW_SAM2BAM.out.versions_samtools,
        SAMTOOLS_SORT.out.versions_samtools
    )

    // Discordant-read detection (replicates eccMapper run_discordantread_detect)
    // SAMFLAGS: -G 2 (not proper pair), -f 83 / -f 163 (reverse-forward)
    def ch_alignment = SEGEMEHL_ALIGN.out.alignment.map { meta, sam -> [ meta, sam, [] ] }
    SAMTOOLS_VIEW_DR_F2 ( ch_alignment, fasta_meta.map { meta, fa -> [ meta, fa, [] ] }, [[id:'no_qname'], []], [[id:'no_bed'], []], [] )
    SAMTOOLS_VIEW_DR_F83 ( ch_alignment, fasta_meta.map { meta, fa -> [ meta, fa, [] ] }, [[id:'no_qname'], []], [[id:'no_bed'], []], [] )
    SAMTOOLS_VIEW_DR_F163 ( ch_alignment, fasta_meta.map { meta, fa -> [ meta, fa, [] ] }, [[id:'no_qname'], []], [[id:'no_bed'], []], [] )

    // Genome sizes (needed by DR_DETECT genomecov -g and MAKEWINDOWS)
    SAMTOOLS_FAIDX_WIN ( fasta_meta.map { meta, fa -> [ meta, fa, [] ] }, true )

    ECCSPLORER_DR_DETECT (
        SAMTOOLS_VIEW_DR_F2.out.bam,
        SAMTOOLS_VIEW_DR_F83.out.bam,
        SAMTOOLS_VIEW_DR_F163.out.bam,
        SAMTOOLS_FAIDX_WIN.out.sizes
    )
    ch_versions = ch_versions.mix(
        SAMTOOLS_VIEW_DR_F2.out.versions_samtools,
        SAMTOOLS_VIEW_DR_F83.out.versions_samtools,
        SAMTOOLS_VIEW_DR_F163.out.versions_samtools,
        ECCSPLORER_DR_DETECT.out.versions,
        SAMTOOLS_FAIDX_WIN.out.versions_samtools
    )

    // BAM → BED (all alignments)
    BEDTOOLS_BAMTOBED ( SAMTOOLS_SORT.out.bam )
    ch_versions = ch_versions.mix(BEDTOOLS_BAMTOBED.out.versions_bedtools)

    // Alignment statistics (real mapped bases for RPM normalization)
    SAMTOOLS_STATS_TR (
        SAMTOOLS_VIEW_SAM2BAM.out.bam.map { meta, bam -> [ meta, bam, [] ] },
        fasta_meta.map { meta, fa -> [ meta, fa, [] ] }
    )
    ch_versions = ch_versions.mix(SAMTOOLS_STATS_TR.out.versions_samtools)

    // ---- Control (CO) chain: segemehl align → sorted BAM → all BED + stats ----
    def ch_co_bed = Channel.empty()
    def ch_co_stats = Channel.empty()
    if (control) {
        SEGEMEHL_ALIGN_CO ( control, ch_fasta_path, SEGEMEHL_INDEX.out.index )
        ch_versions = ch_versions.mix(SEGEMEHL_ALIGN_CO.out.versions)
        SAMTOOLS_VIEW_SAM2BAM_CO (
            SEGEMEHL_ALIGN_CO.out.alignment.map { meta, sam -> [ meta, sam, [] ] },
            fasta_meta.map { meta, fa -> [ meta, fa, [] ] },
            [[id:'no_qname'], []],
            [[id:'no_bed'], []],
            []
        )
        SAMTOOLS_SORT_CO (
            SAMTOOLS_VIEW_SAM2BAM_CO.out.bam,
            fasta_meta.map { meta, fa -> [ meta, fa, [] ] },
            ''
        )
        BEDTOOLS_BAMTOBED_CO ( SAMTOOLS_SORT_CO.out.bam )
        ch_co_bed = BEDTOOLS_BAMTOBED_CO.out.bed
        SAMTOOLS_STATS_CO (
            SAMTOOLS_VIEW_SAM2BAM_CO.out.bam.map { meta, bam -> [ meta, bam, [] ] },
            fasta_meta.map { meta, fa -> [ meta, fa, [] ] }
        )
        ch_co_stats = SAMTOOLS_STATS_CO.out.stats
        ch_versions = ch_versions.mix(
            SAMTOOLS_VIEW_SAM2BAM_CO.out.versions_samtools,
            SAMTOOLS_SORT_CO.out.versions_samtools,
            BEDTOOLS_BAMTOBED_CO.out.versions_bedtools,
            SAMTOOLS_STATS_CO.out.versions_samtools
        )
    }

    // Genome windows (runs once per genome; FAIDX_WIN already run above for DR_DETECT)
    BEDTOOLS_MAKEWINDOWS ( SAMTOOLS_FAIDX_WIN.out.sizes )
    ch_versions = ch_versions.mix(BEDTOOLS_MAKEWINDOWS.out.versions_bedtools)

    // Per-base coverage: windows × all.bed
    // collect() makes windows a single-value channel → one coverage task per sample (no cartesian product)
    def ch_windows = BEDTOOLS_MAKEWINDOWS.out.bed.collect()
    def ch_coverage_input = BEDTOOLS_BAMTOBED.out.bed
        .combine(ch_windows)
        .map { meta_s, bed, meta_w, windows -> [ meta_s, windows, bed ] }
    BEDTOOLS_COVERAGE ( ch_coverage_input, [] )
    ch_versions = ch_versions.mix(BEDTOOLS_COVERAGE.out.versions_bedtools)

    // Peak detection from coverage data
    ECCSPLORER_PEAK_DETECT ( BEDTOOLS_COVERAGE.out.bed )
    ch_versions = ch_versions.mix(ECCSPLORER_PEAK_DETECT.out.versions)

    // Candidate extraction: SR ∩ peak_all ∩ peak_DR (3/3 hiconf, 2/3 lowconf)
    // Explicit join by sample id prevents channel meta mismatch (HAARZ vs PEAK_DETECT lineage)
    // DR uses regions-DR.bed (coverage-threshold regions) matching blackbox extract_candidate_regions
    def ch_cand_input = HAARZ.out.sr_bed
        .map { meta, bed -> [ meta.id, meta, bed ] }
        .join( ECCSPLORER_PEAK_DETECT.out.bed.map { meta, bed -> [ meta.id, meta, bed ] } )
        .join( ECCSPLORER_DR_DETECT.out.dr_regions.map { meta, bed -> [ meta.id, meta, bed ] } )
        .map { id, ms, sr, mp, peak, md, dr -> [ ms, sr, peak, dr ] }
    ECCSPLORER_CANDIDATE_EXTRACT (
        ch_cand_input.map { ms, sr, peak, dr -> [ ms, sr ] },
        ch_cand_input.map { ms, sr, peak, dr -> [ ms, peak ] },
        ch_cand_input.map { ms, sr, peak, dr -> [ ms, dr ] }
    )
    ch_versions = ch_versions.mix(ECCSPLORER_CANDIDATE_EXTRACT.out.versions)

    // Per-candidate coverage profiling (TR/CO × all/SR/DR multi-alignment)
    def ch_tr_all = BEDTOOLS_BAMTOBED.out.bed.map { meta, bed -> [ meta.id, meta, bed ] }
    def ch_tr_sr = SEGEMEHL_ALIGN.out.single_bed.map { meta, bed -> [ meta.id, meta, bed ] }
    def ch_tr_dr = ECCSPLORER_DR_DETECT.out.dr_bed.map { meta, bed -> [ meta.id, meta, bed ] }
    def ch_cov_in = ECCSPLORER_CANDIDATE_EXTRACT.out.candidates
        .map { meta, bed -> [ meta.id, meta, bed ] }
        .join(ch_tr_all)
        .join(ch_tr_sr)
        .join(ch_tr_dr)
    if (control) {
        ch_cov_in = ch_cov_in.join(ch_co_bed.map { meta, bed -> [ meta.id, meta, bed ] })
    }
    def ch_cov_arg = ch_cov_in.map { id, mc, cand, t, trall, s, trsr, d, trdr, c, coal ->
        def beds = [ trall, trsr, trdr ]
        if (coal) beds << coal
        [ mc, cand, beds, 'TR_all,TR_SR,TR_DR' + (coal ? ',CO_all' : '') ]
    }
    ECCSPLORER_COVERAGE_PROFILE (
        ch_cov_arg.map { mc, cand, beds, names -> [ mc, cand ] },
        ch_cov_arg.map { mc, cand, beds, names -> [ mc, beds ] },
        ch_cov_arg.map { mc, cand, beds, names -> names },
        fasta_meta
    )
    ch_versions = ch_versions.mix(ECCSPLORER_COVERAGE_PROFILE.out.versions)

    // Normalization (RPM with real mapped bases + fold enrichment, region mode)
    def ch_stats = control
        ? SAMTOOLS_STATS_TR.out.stats.mix(SAMTOOLS_STATS_CO.out.stats).collect()
        : SAMTOOLS_STATS_TR.out.stats.collect()
    ECCSPLORER_NORMALIZE (
        ECCSPLORER_COVERAGE_PROFILE.out.coverage,
        ch_stats
    )
    ch_versions = ch_versions.mix(ECCSPLORER_NORMALIZE.out.versions)

    // Visualization
    ECCSPLORER_VISUALIZE ( ECCSPLORER_NORMALIZE.out.normalized )
    ch_versions = ch_versions.mix(ECCSPLORER_VISUALIZE.out.versions)

    // BLAST annotation (replicates ECCsplorer basic_setup + analyze_candidate_region)
    def ch_blast_db = params.eccsplorer_database
        ? Channel.of([ [id:'combineddb'], file(params.eccsplorer_database) ])
        : Channel.empty()
    def ch_blast_out = Channel.empty()
    if (params.eccsplorer_database) {
        BLAST_COMBINEDDB ( ch_blast_db )
        // candidate sequences (BED → FASTA)
        BEDTOOLS_GETFASTA_CAND (
            ECCSPLORER_CANDIDATE_EXTRACT.out.candidates,
            fasta_meta.map { _meta, f -> f }
        )
        BLAST_ANNOTATE (
            BEDTOOLS_GETFASTA_CAND.out.fasta,
            BLAST_COMBINEDDB.out.combined_db,
            'combineddb_db'
        )
        ch_blast_out = BLAST_ANNOTATE.out.blast_m6
        ch_versions = ch_versions.mix(
            BLAST_COMBINEDDB.out.versions,
            BLAST_ANNOTATE.out.versions
        )
    }

    // HTML report (blast_results passed when annotation enabled)
    ECCSPLORER_HTML_REPORT (
        ECCSPLORER_NORMALIZE.out.normalized,
        ch_blast_out
    )
    ch_versions = ch_versions.mix(ECCSPLORER_HTML_REPORT.out.versions)

    emit:
    segemehl_index  = SEGEMEHL_INDEX.out.index
    haarz_sr        = HAARZ.out.sr_bed
    candidates_bed  = ECCSPLORER_CANDIDATE_EXTRACT.out.candidates
    hiconf_bed      = ECCSPLORER_CANDIDATE_EXTRACT.out.hiconf_bed
    lowconf_bed     = ECCSPLORER_CANDIDATE_EXTRACT.out.lowconf_bed
    normalized      = ECCSPLORER_NORMALIZE.out.normalized
    manhattan_plot  = ECCSPLORER_VISUALIZE.out.manhattan_plot
    html_report     = ECCSPLORER_HTML_REPORT.out.html
    blast_m6        = ch_blast_out
    versions        = ch_versions
}
