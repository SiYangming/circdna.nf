//
// ECC_FINDER: eccDNA detection via de novo assembly or reference-guided mapping
// Supports 4 modes: MAP_SR / ASM_SR (Illumina) + MAP_ONT / ASM_ONT (Nanopore)
// All modes share the same Docker image and conda environment.
//
// MAP modes: require index + reference, output csv + fasta
// ASM modes: de novo assembly, output fasta only (no reference needed)
//

process ECC_FINDER_MAP_SR {
    tag "$meta2.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/bioinfortools/ecc_finder:1.0.0' :
        'quay.io/bioinfortools/ecc_finder:1.0.0' }"

    input:
    tuple val(meta), path(idx)       // BWA index (meta from index, idx = bwa index dir)
    tuple val(meta2), path(query1)    // R1 FASTQ (meta2 = sample meta with id)
    tuple val(meta3), path(query2)    // R2 FASTQ
    tuple val(meta4), path(ref)       // Reference genome FASTA

    output:
    tuple val(meta2), path("${prefix}.csv"),  emit: csv
    tuple val(meta2), path("${prefix}.fasta"), emit: fasta
    tuple val("${task.process}"), val('ecc_finder'), eval("ecc_finder.py --version"), topic: versions, emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta2.id}"

    """
    ECC_FINDER_DIR=/opt/conda/envs/ecc_finder/bin

    python \$ECC_FINDER_DIR/map-sr.py \\
        ${idx} \\
        ${query1} \\
        ${query2} \\
        -r ${ref} \\
        -t ${task.cpus} \\
        -o . \\
        -x ${prefix} \\
        $args

    mv eccFinder_output/${prefix}.csv ${prefix}.csv
    mv eccFinder_output/${prefix}.fasta ${prefix}.fasta
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = "ecc.sr"
    """
    touch ${prefix}.csv
    touch ${prefix}.fasta
    """
}

process ECC_FINDER_ASM_SR {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/bioinfortools/ecc_finder:1.0.0' :
        'quay.io/bioinfortools/ecc_finder:1.0.0' }"

    input:
    tuple val(meta), path(query1)     // R1 FASTQ
    tuple val(meta2), path(query2)    // R2 FASTQ

    output:
    tuple val(meta), path("${prefix}.fasta"), emit: fasta
    tuple val("${task.process}"), val('ecc_finder'), eval("ecc_finder.py --version"), topic: versions, emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "ecc.asm.sr"

    """
    python /opt/conda/envs/ecc_finder/bin/asm-sr.py \\
        ${query1} \\
        ${query2} \\
        -t ${task.cpus} \\
        -o . \\
        -x ${prefix} \\
        $args

    mv eccFinder_asm_output/${prefix}.fasta ${prefix}.fasta
    """

    stub:
    prefix = task.ext.prefix ?: "ecc.asm.sr"
    """
    touch ${prefix}.fasta
    """
}

//
// ONT long-read modes (reserved for circdnalr branch)
// These processes are ready but require minimap2 index + ONT FASTQ input
//

process ECC_FINDER_MAP_ONT {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/bioinfortools/ecc_finder:1.0.0' :
        'quay.io/bioinfortools/ecc_finder:1.0.0' }"

    input:
    tuple val(meta), path(idx)       // minimap2 index (.mmi)
    tuple val(meta2), path(query)     // ONT FASTQ (single-end)
    tuple val(meta3), path(ref)       // Reference genome FASTA

    output:
    tuple val(meta), path("${prefix}.csv"),  emit: csv
    tuple val(meta), path("${prefix}.fasta"), emit: fasta
    tuple val("${task.process}"), val('ecc_finder'), eval("ecc_finder.py --version"), topic: versions, emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "ecc.ont"

    """
    python /opt/conda/envs/ecc_finder/bin/map-ont.py \\
        ${idx} \\
        ${query} \\
        -r ${ref} \\
        -t ${task.cpus} \\
        -o . \\
        -x ${prefix} \\
        $args

    mv eccFinder_output/${prefix}.csv ${prefix}.csv
    mv eccFinder_output/${prefix}.fasta ${prefix}.fasta
    """

    stub:
    prefix = task.ext.prefix ?: "ecc.ont"
    """
    touch ${prefix}.csv
    touch ${prefix}.fasta
    """
}

process ECC_FINDER_ASM_ONT {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/bioinfortools/ecc_finder:1.0.0' :
        'quay.io/bioinfortools/ecc_finder:1.0.0' }"

    input:
    tuple val(meta), path(query)      // ONT FASTQ (single-end)

    output:
    tuple val(meta), path("${prefix}.fasta"), emit: fasta
    tuple val("${task.process}"), val('ecc_finder'), eval("ecc_finder.py --version"), topic: versions, emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "ecc.asm.ont"

    """
    python /opt/conda/envs/ecc_finder/bin/asm-ont.py \\
        ${query} \\
        -t ${task.cpus} \\
        -o . \\
        -x ${prefix} \\
        $args

    mv eccFinder_asm_output/${prefix}.fasta ${prefix}.fasta
    """

    stub:
    prefix = task.ext.prefix ?: "ecc.asm.ont"
    """
    touch ${prefix}.fasta
    """
}
