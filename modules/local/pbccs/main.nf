process PBCCS {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pbccs:6.4.0--h5f740d0_0' :
        'quay.io/biocontainers/pbccs:6.4.0--h5f740d0_0' }"

    input:
    val meta
    path subreads_bam
    path subreads_bai

    output:
    path "${meta.id}.hifi_reads.fastq.gz", emit: hifi_fastq
    path "${meta.id}.ccs_report.txt", emit: report
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    ccs \\
        $subreads_bam \\
        ${meta.id}.hifi_reads.fastq.gz \\
        --report-file ${meta.id}.ccs_report.txt \\
        --min-passes 3 \\
        --min-rq 0.9

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pbccs: \$(ccs --version 2>&1 | grep -oP 'version \\K[\\d.]+')
        samtools: \$(samtools --version 2>&1 | grep -oP 'samtools \\K[\\d.]+')
    END_VERSIONS
    """
}