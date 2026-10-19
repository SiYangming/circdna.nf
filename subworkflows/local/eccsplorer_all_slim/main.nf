//
// ECCSPLORER_ALL_SLIM — all 模式编排：map + clu + comparative
// replicates ECCsplorer.py all mode (map/clu/comparative 串联)
//

include { ECCSPLORER_SLIM_PIPELINE  } from '../eccsplorer_slim_pipeline/main'
include { ECCSPLORER_CLU_SLIM       } from '../eccsplorer_clu_slim/main'
include { ECCSPLORER_COMPARATIVE_BLAST } from '../../../modules/local/eccsplorer_slim/comparative_blast/main'
include { ECCSPLORER_COMPARATIVE_PLOT } from '../../../modules/local/eccsplorer_slim/comparative_plot/main'
include { ECCSPLORER_CONTRACT_EXPORT } from '../../../modules/local/eccsplorer_slim/contract_export/main'
include { BEDTOOLS_GETFASTA as BEDTOOLS_GETFASTA_SEQ } from '../../../modules/nf-core/bedtools/getfasta/main'

workflow ECCSPLORER_ALL_SLIM {
    take:
    reads
    fasta_meta
    control
    taxon

    main:
    ch_versions = channel.empty()

    // map
    ECCSPLORER_SLIM_PIPELINE ( reads, fasta_meta, control )
    ch_versions = ch_versions.mix(ECCSPLORER_SLIM_PIPELINE.out.versions)

    // clu
    ECCSPLORER_CLU_SLIM ( reads, control, taxon )
    ch_versions = ch_versions.mix(ECCSPLORER_CLU_SLIM.out.versions)

    // comparative: mapper candidate sequences
    BEDTOOLS_GETFASTA_SEQ (
        ECCSPLORER_SLIM_PIPELINE.out.candidates_bed,
        fasta_meta.map { _meta, f -> f }
    )
    ch_versions = ch_versions.mix(BEDTOOLS_GETFASTA_SEQ.out.versions_bedtools)

    ECCSPLORER_COMPARATIVE_BLAST (
        BEDTOOLS_GETFASTA_SEQ.out.fasta,
        ECCSPLORER_CLU_SLIM.out.clu_dir.map { meta, dir -> [ meta, [ dir ] ] }
    )
    ch_versions = ch_versions.mix(ECCSPLORER_COMPARATIVE_BLAST.out.versions)

    ECCSPLORER_COMPARATIVE_PLOT (
        ECCSPLORER_COMPARATIVE_BLAST.out.blast_m6,
        ECCSPLORER_SLIM_PIPELINE.out.normalized
    )
    ch_versions = ch_versions.mix(ECCSPLORER_COMPARATIVE_PLOT.out.versions)

    // Output contract: rewrite to eccpipe_results tree (original naming)
    ECCSPLORER_CONTRACT_EXPORT (
        ECCSPLORER_SLIM_PIPELINE.out.hiconf_bed.map { _m, p -> p }.ifEmpty([]),
        ECCSPLORER_SLIM_PIPELINE.out.lowconf_bed.map { _m, p -> p }.ifEmpty([]),
        ECCSPLORER_SLIM_PIPELINE.out.candidates_bed.map { _m, p -> p }.ifEmpty([]),
        ECCSPLORER_SLIM_PIPELINE.out.normalized.map { _m, p -> p }.ifEmpty([]),
        BEDTOOLS_GETFASTA_SEQ.out.fasta.map { _m, p -> p }.ifEmpty([]),
        ECCSPLORER_SLIM_PIPELINE.out.blast_m6.map { _m, p -> p }.ifEmpty([]),
        ECCSPLORER_CLU_SLIM.out.cluster_candidates.map { _m, p -> p }.ifEmpty([]),
        ECCSPLORER_CLU_SLIM.out.comparative_table.map { _m, p -> p }.ifEmpty([]),
        ECCSPLORER_SLIM_PIPELINE.out.html_report.map { _m, p -> p }.ifEmpty([]),
        [].ifEmpty([]),
        ECCSPLORER_COMPARATIVE_PLOT.out.html.map { _m, p -> p }.ifEmpty([]),
        'TR'
    )
    ch_versions = ch_versions.mix(ECCSPLORER_CONTRACT_EXPORT.out.versions)

    emit:
    candidates_bed  = ECCSPLORER_SLIM_PIPELINE.out.candidates_bed
    normalized      = ECCSPLORER_SLIM_PIPELINE.out.normalized
    cluster_candidates = ECCSPLORER_CLU_SLIM.out.cluster_candidates
    comparative_m6  = ECCSPLORER_COMPARATIVE_BLAST.out.blast_m6
    comparative_html = ECCSPLORER_COMPARATIVE_PLOT.out.html
    versions        = ch_versions
}
