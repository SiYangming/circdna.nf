process CHOPPER {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/chopper:0.7.0--py38h06a4308_0' :
        'quay.io/biocontainers/chopper:0.7.0--py38h06a4308_0' }"

    input:
    val meta
    path fastq

    output:
    path "${meta.id}.filtered.fastq.gz", emit: filtered_fastq
    path "${meta.id}.chopper.stats.txt", emit: stats
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    chopper \\
        --quality 7 \\
        --length 500 \\
        --headcrop 0 \\
        --tailcrop 0 \\
        --threads 4 \\
        $fastq \\
        > ${meta.id}.filtered.fastq

    gzip ${meta.id}.filtered.fastq

    echo "Filtered reads: \$(zcat ${meta.id}.filtered.fastq.gz | wc -l | awk '{print \$1/4}')" > ${meta.id}.chopper.stats.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chopper: \$(python -c "import chopper; print(chopper.__version__)" 2>/dev/null || echo 'unknown')
    END_VERSIONS
    """
}