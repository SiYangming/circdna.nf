process ECC_FINDER_ASM_FILTER {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ecc_finder_slim:1.0.0--0' :
        'quay.io/bioinfortools/ecc_finder_slim:1.0.0' }"

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("${prefix}.fasta"), emit: fasta
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Decompress assembly if gzipped (unicycler outputs .fa.gz)
    if [[ "${assembly}" == *.gz ]]; then
        gzip -dc ${assembly} > ${prefix}_asm.fa
        ASSEMBLY_IN=${prefix}_asm.fa
    else
        ASSEMBLY_IN=${assembly}
    fi

    asm_filter.py \\
        --assembly \${ASSEMBLY_IN} \\
        --min-length ${params.eccfinder_asm_min_length} \\
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
    touch ${prefix}.fasta
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ecc_finder_slim: 1.0.0
    END_VERSIONS
    """
}
