process HAARZ {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/segemehl:0.3.4--hc2ea5fd_5' :
        'quay.io/biocontainers/segemehl:0.3.4--hc2ea5fd_5' }"

    input:
    tuple val(meta), path(sngl_bed)

    output:
    tuple val(meta), path("${prefix}_haarz-SR.bed"), emit: sr_bed
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '--minsplit 5 --minqual 1'
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Fix start>end rows in .sngl.bed (replicates eccMapper.py run_splitread_detect)
    awk '\$2 > \$3 { temp = \$3; \$3 = \$2; \$2 = temp } 1' OFS='\\t' ${sngl_bed} > ${prefix}_aligned-SR.bed

    haarz.x split --files ${prefix}_aligned-SR.bed $args > ${prefix}_haarz-SR.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        segemehl: 0.3.4
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_haarz-SR.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        segemehl: 0.3.4
    END_VERSIONS
    """
}
