process FLED {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://quay.io/bioinfortools/fled:1.7.0' :
        'quay.io/bioinfortools/fled:1.7.0' }"

    input:
    tuple val(meta), path(fastq)
    path genome_fasta
    path genome_fai          // optional: pre-built .fai index to avoid rebuilding

    output:
    tuple val(meta), path("${prefix}.fled_junctions.txt"), emit: junctions
    tuple val(meta), path("${prefix}.DiGraph.*Junction.fa"), emit: sequences
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    # FLED requires an indexed reference genome (.fai) and plain fasta.
    # Gzipped inputs are decompressed since FLED detects format by extension.
    if [[ "${genome_fasta}" == *.gz ]]; then
        zcat "${genome_fasta}" > reference.fa
        GENOME="reference.fa"
    else
        GENOME="${genome_fasta}"
    fi

    # Reuse an externally-provided .fai when available (avoids rebuilding the
    # index already computed for e.g. cresil identify); otherwise build it.
    if [ -n "${genome_fai}" ] && [ -f "${genome_fai}" ]; then
        cp "${genome_fai}" "\${GENOME}.fai"
    elif [ ! -f "\${GENOME}.fai" ]; then
        samtools faidx "\${GENOME}"
    fi

    if [[ "${fastq}" == *.gz ]]; then
        zcat "${fastq}" > reads_input.fastq
        FQ="reads_input.fastq"
    else
        FQ="${fastq}"
    fi

    FLED Detection \\
        -ref \${GENOME} \\
        -fq \${FQ} \\
        -o ${prefix} \\
        -dir . \\
        -t ${task.cpus} \\
        $args

    # Combine both junction outputs into a single candidates file.
    cat ${prefix}.DiGraph.OnesegJunction.out ${prefix}.DiGraph.MulsegFullJunction.out > ${prefix}.fled_junctions.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fled: \$(FLED 2>&1 | grep -oP 'version=\\K[\\d.]+' || echo 'unknown')
        samtools: \$(samtools --version 2>&1 | grep -oP 'samtools \\K[\\d.]+')
    END_VERSIONS
    """
}
