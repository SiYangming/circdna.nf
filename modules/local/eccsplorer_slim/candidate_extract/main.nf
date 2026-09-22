process ECCSPLORER_CANDIDATE_EXTRACT {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/eccsplorer_slim:1.0.0--0' :
        'quay.io/bioinfortools/eccsplorer_slim:1.0.0' }"

    input:
    tuple val(meta), path(sr_bed)
    tuple val(meta2), path(peak_all_bed)
    tuple val(meta3), path(dr_bed)

    output:
    tuple val(meta), path("${prefix}_candidates.bed"), emit: candidates
    tuple val(meta), path("${prefix}_hiconf-ECC-REGIONS.bed"), emit: hiconf_bed
    tuple val(meta), path("${prefix}_lowconf-ECC-regions.bed"), emit: lowconf_bed
    path "versions.yml"                                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # v2: candidate_extract.py run_bedtools fixed to shell=True (pipe support)
    # haarz raw output → cleaned BED regions (replicates eccMapper.py run_splitread_detect)
    # haarz cols: chr left right n median_qual ...; keep chr/left/right, drop header,
    # filter n>0 and length<=35000, merge regions within 1000bp, re-filter length>=100
    sed '1d' ${sr_bed} | \\
        bedtools sort -i stdin | \\
        awk '(\$3-\$2)<=35000 && \$4>0' | \\
        bedtools merge -d 1000 -i stdin | \\
        awk '(\$3-\$2)<=35000 && (\$3-\$2)>=100' \\
        > ${prefix}_regions-SR.bed

    # v3: real discordant-read peak from dr_detect (no longer peak_all copy)
    cp ${dr_bed} ${prefix}_dr.bed

    candidate_extract.py \\
        --sr ${prefix}_regions-SR.bed \\
        --peak_all ${peak_all_bed} \\
        --peak_dr ${prefix}_dr.bed \\
        --output ${prefix}_candidates.bed \\
        --hiconf_out ${prefix}_hiconf-ECC-REGIONS.bed \\
        --lowconf_out ${prefix}_lowconf-ECC-regions.bed \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer_slim: 1.0.0
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_candidates.bed
    touch ${prefix}_hiconf-ECC-REGIONS.bed
    touch ${prefix}_lowconf-ECC-regions.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer_slim: 1.0.0
    END_VERSIONS
    """
}
