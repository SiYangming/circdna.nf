process ECCSPLORER_HTML_REPORT {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/eccsplorer_slim:1.0.0--0' :
        'quay.io/bioinfortools/eccsplorer_slim:1.0.0' }"

    input:
    tuple val(meta), path(candidate_data)
    path blast_results

    output:
    path "*.html"      , emit: html
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    html_report.py \
        --candidates ${candidate_data} \\
        ${blast_results ? '--blast ' + blast_results : '--blast .'} \\
        --outdir . \\
        --output ${prefix}_report.html \\
        --prefix ${prefix} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer_slim: 1.0.0
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo '<html><body>ECCsplorer Report Stub</body></html>' > ${prefix}_report.html

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer_slim: 1.0.0
    END_VERSIONS
    """
}
