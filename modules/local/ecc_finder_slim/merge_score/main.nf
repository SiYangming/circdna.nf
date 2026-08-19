process ECC_FINDER_MERGE_SCORE {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ecc_finder_slim:1.0.0--0' :
        'quay.io/bioinfortools/ecc_finder_slim:1.0.0' }"

    input:
    tuple val(meta), path(enrichment_bed)
    tuple val(meta2), path(splitreads_bed)
    tuple val(meta3), path(discordant_bed)
    tuple val(meta4), path(ref)

    output:
    tuple val(meta), path("${prefix}.csv"), emit: csv
    tuple val(meta), path("${prefix}.fasta"), emit: fasta
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # v2: dual-evidence (split ∩ disc) inner merge, header-less 6-col CSV (map-sr.py contract)
    merge_score.py \\
        --enrichment ${enrichment_bed} \\
        --splitreads ${splitreads_bed} \\
        --discordant ${discordant_bed} \\
        --ref ${ref} \\
        --prefix ${prefix} \\
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
