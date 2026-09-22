process ECCSPLORER_DR_DETECT {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bedtools:2.31.1--hf5e1c6e_0' :
        'quay.io/biocontainers/bedtools:2.31.1--hf5e1c6e_0' }"

    input:
    tuple val(meta), path(bam_f2)
    tuple val(meta2), path(bam_f83)
    tuple val(meta3), path(bam_f163)
    tuple val(meta4), path(ref_sizes)

    output:
    tuple val(meta), path("${prefix}_aligned-DR.bed"), emit: dr_bed
    tuple val(meta), path("${prefix}_regions-DR.bed"), emit: dr_regions
    path "versions.yml"                              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # discordant-read detection (replicates eccMapper.py run_discordantread_detect)
    # SAMFLAGS: -G 2 (not proper pair), -f 83 / -f 163 (reverse-forward orientation)
    bedtools bamtobed -i ${bam_f2} > ${prefix}_aligned-DR-nF2.bed
    bedtools bamtobed -i ${bam_f83} > ${prefix}_aligned-DR-F83.bed
    bedtools bamtobed -i ${bam_f163} > ${prefix}_aligned-DR-F163.bed
    cat ${prefix}_aligned-DR-nF2.bed ${prefix}_aligned-DR-F83.bed ${prefix}_aligned-DR-F163.bed \\
        | bedtools groupby -g 1,2,3,4,5,6 -c 4 -o count_distinct \\
        | sort -k1,1 -k2,2n > ${prefix}_aligned-DR.bed

    # DR regions via coverage threshold (replicates eccMapper.run_discordantread_detect:
    # genomecov -bga → filter cov > max_cov * BACKGROUND_PERC(0.05) → merge -d 1000 → length filter)
    bedtools genomecov -bga -i ${prefix}_aligned-DR.bed -g ${ref_sizes} > ${prefix}_aligned-DR_graph.bed
    max_cov=\$(awk -v max=0 '{if(\$4>max){max=\$4}}END{print max}' ${prefix}_aligned-DR_graph.bed)
    min_cov=\$(awk -v m=\${max_cov} 'BEGIN{print m*0.05}')
    awk -v c=\${min_cov} '\$4>c' ${prefix}_aligned-DR_graph.bed | \\
        bedtools merge -d 1000 -i stdin | \\
        awk '(\$3-\$2)<=35000 && (\$3-\$2)>=100' \\
        > ${prefix}_regions-DR.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bedtools: 2.31.1
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_aligned-DR.bed
    touch ${prefix}_regions-DR.bed
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bedtools: 2.31.1
    END_VERSIONS
    """
}
