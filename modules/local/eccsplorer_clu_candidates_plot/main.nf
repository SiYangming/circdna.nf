process ECCSPLORER_CLU_CANDIDATES_PLOT {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "quay.io/bioinfortools/eccsplorer:2022.01.1.1"

    input:
    tuple val(meta), path(candidates_tsv)

    output:
    tuple val(meta), path("*_cluster_candidates_plot.pdf"), emit: plot_pdf
    tuple val(meta), path("*_cluster_candidates_plot.tsv"), emit: plot_tsv
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_cluster_candidates_plot.pdf

    cat <<-END_PLOT > ${prefix}_cluster_candidates_plot.tsv
    sample_id\tplot_stage\tplot_note\tinput_candidates
    ${meta.id}\tcandidates_plot\tECCsplorer clu plotting skeleton placeholder\t${candidates_tsv}
    END_PLOT

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer: "2022.01.1.1"
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_cluster_candidates_plot.pdf
    printf "sample_id\\tplot_stage\\tplot_note\\tinput_candidates\\n" > ${prefix}_cluster_candidates_plot.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer: "2022.01.1.1"
    END_VERSIONS
    """
}
