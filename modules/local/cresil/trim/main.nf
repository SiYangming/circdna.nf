process CRESIL_TRIM {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/cresil:1.2.0--hdfd78af_0' :
        'quay.io/bioinfortools/cresil:1.2.1' }"

    input:
    tuple val(meta), path(reads)
    tuple val(meta2), path(mmi)

    output:
    tuple val(meta), path("${prefix}.trim.txt"), emit: trim
    tuple val("${task.process}"), val('cresil'), eval("cresil --version | sed 's/cresil //'"), topic: versions, emit: versions_cresil

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    # CRESIL determines input type by file extension and does not handle .gz,
    # so decompress gzipped reads to a .fastq file when needed.
    if [[ "${reads}" == *.gz ]]; then
        zcat "${reads}" > reads_input.fastq
        READS_IN="reads_input.fastq"
    else
        READS_IN="${reads}"
    fi

    cresil trim \\
        -t ${task.cpus} \\
        -fq \$READS_IN \\
        -r ${mmi} \\
        -o . \\
        $args

    mv trim.txt ${prefix}.trim.txt
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.trim.txt
    """
}
