process LIMA {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/lima:2.7.1--py310h11c0d3a_0' :
        'quay.io/biocontainers/lima:2.7.1--py310h11c0d3a_0' }"

    input:
    val meta
    path fastq
    path primers

    output:
    path "${meta.id}.primer_removed.fastq.gz", emit: trimmed_fastq
    path "${meta.id}.lima.report", emit: report
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    lima \\
        $fastq \\
        $primers \\
        ${meta.id}.primer_removed.fastq.gz \\
        --isoseq \\
        --dump-clips \\
        --no-pbi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        lima: \$(lima --version 2>&1 | grep -oP 'lima \\K[\\d.]+')
        samtools: \$(samtools --version 2>&1 | grep -oP 'samtools \\K[\\d.]+')
    END_VERSIONS
    """
}