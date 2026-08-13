process REPEATEXPLORER2 {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker.1ms.run/kavonrtep/repeatexplorer:2.3.8' :
        'docker.1ms.run/kavonrtep/repeatexplorer:2.3.8' }"

    input:
    tuple val(meta), path(reads_fa)
    val(taxon)

    output:
    tuple val(meta), path("seqclust/"), emit: clu_dir
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def taxon_map = taxon == 'met' ? 'METAZOA3.0' : 'VIRIDIPLANTAE3.0'
    """
    # RepeatExplorer2 (seqclust) clustering
    /repex_tarean/seqclust \\
        --paired \\
        --prefix_length 2 \\
        --output_dir seqclust \\
        --taxon ${taxon_map} \\
        --cpu ${task.cpus} \\
        ${reads_fa} \\
        --cleanup --keep_names --options ILLUMINA \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        repeatexplorer: 2.3.8
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p seqclust
    touch seqclust/CLUSTER_TABLE.csv
    touch seqclust/COMPARATIVE_ANALYSIS_COUNTS.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        repeatexplorer: 2.3.8
    END_VERSIONS
    """
}
