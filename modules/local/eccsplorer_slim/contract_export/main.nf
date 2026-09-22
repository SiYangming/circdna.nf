process ECCSPLORER_CONTRACT_EXPORT {
    tag "contract_export"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/eccsplorer_slim:1.0.0--0' :
        'quay.io/bioinfortools/eccsplorer_slim:1.0.0' }"

    input:
    path(hiconf)
    path(lowconf)
    path(candidates)
    path(normalized)
    path(sequences)
    path(blast_m6)
    path(clu_candidates)
    path(clu_table)
    path(map_html)
    path(clu_html)
    path(comp_html)
    val(prefix)

    output:
    path("eccpipe_results/**"), emit: eccpipe_results
    path "versions.yml"        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    contract_export.py \\
        --hiconf ${hiconf ?: ''} \\
        --lowconf ${lowconf ?: ''} \\
        --candidates ${candidates ?: ''} \\
        --normalized ${normalized ?: ''} \\
        --sequences ${sequences ?: ''} \\
        --blast_m6 ${blast_m6 ?: ''} \\
        --clu_candidates ${clu_candidates ?: ''} \\
        --clu_table ${clu_table ?: ''} \\
        --map_html ${map_html ?: ''} \\
        --clu_html ${clu_html ?: ''} \\
        --comp_html ${comp_html ?: ''} \\
        --prefix ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer_slim: 1.0.0
    END_VERSIONS
    """

    stub:
    """
    mkdir -p eccpipe_results/mapping_results eccpipe_results/clustering_results
    touch eccpipe_results/mapping_results/placeholder
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer_slim: 1.0.0
    END_VERSIONS
    """
}
