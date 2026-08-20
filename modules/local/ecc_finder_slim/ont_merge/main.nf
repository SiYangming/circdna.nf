process ECC_FINDER_ONT_MERGE {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ecc_finder_slim:1.0.0--0' :
        'quay.io/bioinfortools/ecc_finder_slim:1.0.0' }"

    input:
    tuple val(meta), path(site_bed)
    tuple val(meta2), path(paf_bed)
    tuple val(meta3), path(ref)

    output:
    tuple val(meta), path("${prefix}.csv"), emit: csv
    tuple val(meta), path("${prefix}.fasta"), emit: fasta
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # site 兼容 10 列 narrowPeak（nf-core GENRICH）与 3 列 BED：统一取前 3 列
    cut -f1-3 ${site_bed} > enrich_sites.bed
    ont_merge.py \\
        --site enrich_sites.bed \\
        --paf-bed ${paf_bed} \\
        --ref ${ref} \\
        --prefix ${prefix} \\
        --min-bound ${params.eccfinder_ont_min_bound} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ecc_finder_slim: 1.0.0
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.csv
    touch ${prefix}.fasta
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ecc_finder_slim: 1.0.0
    END_VERSIONS
    """
}
