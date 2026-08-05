//
// ECCsplorer clu mode skeleton subworkflow
// Contains: ECCSPLORER_CLU_PREPARE, ECCSPLORER_CLU_CORE, ECCSPLORER_CLU_CANDIDATES_PLOT
//

include { ECCSPLORER_CLU_PREPARE }        from '../../../modules/local/eccsplorer_clu_prepare/main'
include { ECCSPLORER_CLU_CORE }           from '../../../modules/local/eccsplorer_clu_core/main'
include { ECCSPLORER_CLU_CANDIDATES_PLOT } from '../../../modules/local/eccsplorer_clu_candidates_plot/main'

workflow ECCSPLORER_CLUSTER {
    take:
    reads
    fasta_meta
    run_prepare
    run_core
    run_candidates_plot

    main:
    ch_versions = channel.empty()
    ch_prepare_dir = channel.empty()
    ch_reads_manifest = channel.empty()
    ch_candidates = channel.empty()
    ch_cluster_results = channel.empty()
    ch_plot_pdf = channel.empty()
    ch_plot_tsv = channel.empty()

    if (run_prepare) {
        ch_clu_fasta = fasta_meta.map { _meta, fasta -> fasta }
        ch_prepare_input = reads.combine(ch_clu_fasta)

        ECCSPLORER_CLU_PREPARE (
            ch_prepare_input
        )
        ch_versions = ch_versions.mix(ECCSPLORER_CLU_PREPARE.out.versions)
        ch_prepare_dir = ECCSPLORER_CLU_PREPARE.out.prepare_dir
        ch_reads_manifest = ECCSPLORER_CLU_PREPARE.out.reads_manifest
    }

    if (run_core) {
        ECCSPLORER_CLU_CORE (
            ch_prepare_dir
        )
        ch_versions = ch_versions.mix(ECCSPLORER_CLU_CORE.out.versions)
        ch_candidates = ECCSPLORER_CLU_CORE.out.candidates
        ch_cluster_results = ECCSPLORER_CLU_CORE.out.cluster_results
    }

    if (run_candidates_plot) {
        ECCSPLORER_CLU_CANDIDATES_PLOT (
            ch_candidates
        )
        ch_versions = ch_versions.mix(ECCSPLORER_CLU_CANDIDATES_PLOT.out.versions)
        ch_plot_pdf = ECCSPLORER_CLU_CANDIDATES_PLOT.out.plot_pdf
        ch_plot_tsv = ECCSPLORER_CLU_CANDIDATES_PLOT.out.plot_tsv
    }

    emit:
    prepare_dir = ch_prepare_dir
    reads_manifest = ch_reads_manifest
    candidates = ch_candidates
    cluster_results = ch_cluster_results
    plot_pdf = ch_plot_pdf
    plot_tsv = ch_plot_tsv
    versions = ch_versions
}
