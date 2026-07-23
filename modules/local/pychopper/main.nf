process PYCHOPPER {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pychopper:2.7.1--py38hdfd78af_1' :
        'quay.io/biocontainers/pychopper:2.7.1--py38hdfd78af_1' }"

    input:
    val meta
    path fastq
    path primers

    output:
    path "${meta.id}.full_length.fastq.gz", emit: full_length_fastq
    path "${meta.id}.pychopper.stats.txt", emit: stats
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    cdna_classifier.py \\
        --threads 4 \\
        --primer_file $primers \\
        --out_dir . \\
        $fastq \\
        ${meta.id}.full_length.fastq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pychopper: \$(python -c "import pychopper; print(pychopper.__version__)" 2>/dev/null || echo 'unknown')
    END_VERSIONS
    """
}