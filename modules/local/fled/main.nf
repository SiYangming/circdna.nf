process FLED {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://quay.io/siyangming/fled:1.0.0' :
        'quay.io/siyangming/fled:1.0.0' }"

    input:
    val meta
    path bam
    path bai
    path genome_fasta

    output:
    path "${meta.id}.fled_circles.bed", emit: circles_bed
    path "${meta.id}.fled_report.txt", emit: report
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    mkdir -p fled_output

    python -m fled \\
        --bam $bam \\
        --ref $genome_fasta \\
        --out fled_output \\
        --threads 8

    cp fled_output/circles.bed ${meta.id}.fled_circles.bed
    cp fled_output/report.txt ${meta.id}.fled_report.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fled: \$(python -c "import fled; print(getattr(fled, '__version__', 'unknown'))" 2>/dev/null || echo 'unknown')
        samtools: \$(samtools --version 2>&1 | grep -oP 'samtools \\K[\\d.]+')
        bedtools: \$(bedtools --version 2>&1 | grep -oP 'v[\\d.]+')
    END_VERSIONS
    """
}