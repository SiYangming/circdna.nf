process BEDTOOLS_INTERSECT {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bedtools:2.30.0--h7d7f7ad_0' :
        'quay.io/biocontainers/bedtools:2.30.0--h7d7f7ad_0' }"

    input:
    tuple val(meta), path(a_bed)
    path b_bed

    output:
    path "${meta.id}.intersect.bed", emit: intersect_bed
    path "${meta.id}.non_overlapping.bed", emit: non_overlapping_bed
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    bedtools intersect \\
        -a $a_bed \\
        -b $b_bed \\
        -wa \\
        > ${meta.id}.intersect.bed

    bedtools intersect \\
        -a $a_bed \\
        -b $b_bed \\
        -v \\
        > ${meta.id}.non_overlapping.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bedtools: \$(bedtools --version 2>&1 | grep -oP 'v[\\d.]+')
    END_VERSIONS
    """
}