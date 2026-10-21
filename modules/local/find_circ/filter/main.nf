process FIND_CIRC_FILTER {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/find_circ%3A1.2--hdfd78af_0':
        'quay.io/biocontainers/find_circ:1.2--hdfd78af_0' }"

    input:
    tuple val(meta), path(bed)

    output:
    tuple val(meta), path("${prefix}_find_circ.bed"), emit: bed
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '1.2'
    // Keep CIRCULAR junctions when present; otherwise keep non-LINEAR / non-comment rows.
    // Emit standard 6-column BED for downstream eccDNA collation.
    """
    if grep -q CIRCULAR ${bed} 2>/dev/null; then
        grep CIRCULAR ${bed} | grep -v '^#' | awk -v OFS='\\t' 'NF>=6 {print \$1,\$2,\$3,\$4,\$5,\$6}' > ${prefix}_find_circ.bed || true
    else
        grep -v '^#' ${bed} | grep -v LINEAR | awk -v OFS='\\t' 'NF>=6 {print \$1,\$2,\$3,\$4,\$5,\$6}' > ${prefix}_find_circ.bed || true
    fi
    [ -f ${prefix}_find_circ.bed ] || touch ${prefix}_find_circ.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        find_circ: $VERSION
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '1.2'
    """
    touch ${prefix}_find_circ.bed
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        find_circ: $VERSION
    END_VERSIONS
    """
}
