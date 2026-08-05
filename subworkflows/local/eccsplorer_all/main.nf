//
// ECCsplorer all/comparative mode skeleton subworkflow
// Reuses the clu skeleton and annotates metadata with control availability.
//

include { ECCSPLORER_CLUSTER } from '../eccsplorer_cluster/main'

workflow ECCSPLORER_ALL {
    take:
    treatment_reads
    control_reads
    fasta_meta
    run_clu
    run_candidates_plot

    main:
    ch_versions = channel.empty()

    ch_control_ids = control_reads
        .map { control_meta, _reads -> control_meta.id }
        .collect()
        .map { ids -> ids.join(',') }

    ch_all_reads = treatment_reads
        .combine(ch_control_ids)
        .map { meta, reads, control_id_string ->
            def comparative_meta = meta + [
                eccsplorer_mode               : 'all',
                eccsplorer_comparative_stub   : true,
                eccsplorer_control_available  : control_id_string ? true : false,
                eccsplorer_control_ids        : control_id_string
            ]
            [comparative_meta, reads]
        }

    ECCSPLORER_CLUSTER (
        ch_all_reads,
        fasta_meta,
        run_clu,
        run_clu,
        run_candidates_plot
    )
    ch_versions = ch_versions.mix(ECCSPLORER_CLUSTER.out.versions)

    emit:
    prepare_dir = ECCSPLORER_CLUSTER.out.prepare_dir
    reads_manifest = ECCSPLORER_CLUSTER.out.reads_manifest
    candidates = ECCSPLORER_CLUSTER.out.candidates
    cluster_results = ECCSPLORER_CLUSTER.out.cluster_results
    plot_pdf = ECCSPLORER_CLUSTER.out.plot_pdf
    plot_tsv = ECCSPLORER_CLUSTER.out.plot_tsv
    versions = ch_versions
}
