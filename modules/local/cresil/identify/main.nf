process CRESIL_IDENTIFY {
    tag "$meta3.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/cresil:1.2.0--hdfd78af_0' :
        'quay.io/bioinfortools/cresil:1.2.2' }"

    input:
    tuple val(meta), path(fasta)
    tuple val(meta2), path(fai)
    tuple val(meta3), path(reads), path(trim)

    output:
    tuple val(meta3), path("${prefix}.eccDNA_final.txt"), emit: identify
    tuple val("${task.process}"), val('cresil'), eval("cresil --version | sed 's/cresil //'"), topic: versions, emit: versions_cresil

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta3.id}"
    def trim_arg = trim ? "-trim ${trim}" : ''

    """
    # CRESIL determines input type by file extension and pysam cannot open
    # gzipped files. The -fq input must also be FASTA (identify opens it
    # with pysam.FastaFile), so convert FASTQ reads to FASTA.
    if [[ "${reads}" == *.gz ]]; then
        zcat "${reads}" > reads_input.fastq
        READS_IN="reads_input.fastq"
    else
        READS_IN="${reads}"
    fi
    if [[ "\${READS_IN}" == *.fastq || "\${READS_IN}" == *.fq ]]; then
        awk 'NR%4==1 {print ">" substr(\$0,2)} NR%4==2 {print}' "\${READS_IN}" > reads_input.fasta
        READS_IN="reads_input.fasta"
    fi
    # pysam.FastaFile requires a .fai index next to the reads file.
    samtools faidx "\${READS_IN}"

    if [[ "${fasta}" == *.gz ]]; then
        zcat "${fasta}" > reference.fa
        FASTAIN="reference.fa"
        samtools faidx \${FASTAIN}
        FAIIN="reference.fa.fai"
    else
        FASTAIN="${fasta}"
        FAIIN="${fai}"
    fi

    # CRESIL aborts (exit != 0) for valid empty results. Preserve real
    # crashes instead of turning every nonzero exit into an empty table.
    set +e
    cresil identify \\
        -t ${task.cpus} \\
        -fa \${FASTAIN} \\
        -fai \${FAIIN} \\
        -fq \${READS_IN} \\
        ${trim_arg} \\
        $args > cresil_identify.log 2>&1
    cresil_status=\$?
    set -e

    if [ \$cresil_status -ne 0 ] && [ ! -f eccDNA_final.txt ] && [ ! -f cresil_result/eccDNA_final.txt ]; then
        if grep -qE '\\[ABORT\\].*(no eccDNA|no (potential )?merge region|zero trimmed region)' cresil_identify.log; then
            echo "# no eccDNA detected by CRESIL identify" > ${prefix}.eccDNA_final.txt
            SKIP_MV=1
        else
            cat cresil_identify.log >&2
            exit \$cresil_status
        fi
    fi

    # Output lands in the parent dir of the -trim input (here: the workdir).
    # Fall back to cresil_result if the layout differs between CRESIL versions.
    if [ "\${SKIP_MV:-}" != "1" ]; then
        if [ -f eccDNA_final.txt ]; then
            mv eccDNA_final.txt ${prefix}.eccDNA_final.txt
        elif [ -f cresil_result/eccDNA_final.txt ]; then
            mv cresil_result/eccDNA_final.txt ${prefix}.eccDNA_final.txt
        else
            echo "CRESIL identify output not found" >&2 && exit 1
        fi
    fi
    """

    stub:
    prefix = task.ext.prefix ?: "${meta3.id}"
    """
    touch ${prefix}.eccDNA_final.txt
    """
}
