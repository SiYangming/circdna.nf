process CRESIL_IDENTIFY_WGLS {
    tag "$meta4.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/cresil:1.2.0--hdfd78af_0' :
        'quay.io/bioinfortools/cresil:1.2.1' }"

    input:
    tuple val(meta), path(mmi)
    tuple val(meta2), path(fasta)
    tuple val(meta3), path(fai)
    tuple val(meta4), path(reads), path(trim)

    output:
    tuple val(meta4), path("${prefix}.eccDNA_final.txt"), emit: identify_wgls
    tuple val("${task.process}"), val('cresil'), eval("cresil --version | sed 's/cresil //'"), topic: versions, emit: versions_cresil

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta4.id}"
    def trim_arg = trim ? "-trim ${trim}" : ''
    """
    # CRESIL determines input types by extension and pysam cannot open
    # gzipped/FASTQ inputs. identify_wgls later uses pysam.FastaFile from
    # parallel workers, so build plain FASTA files and pre-create .fai indexes.
    if [[ "${fasta}" == *.gz ]]; then
        zcat "${fasta}" > reference_wgls.fa
        FASTA_IN="reference_wgls.fa"
    else
        FASTA_IN="${fasta}"
    fi
    samtools faidx "\${FASTA_IN}"
    FAI_IN="\${FASTA_IN}.fai"

    if [[ "${reads}" == *.fastq.gz || "${reads}" == *.fq.gz ]]; then
        zcat "${reads}" > reads_input_wgls.fastq
        READS_IN="reads_input_wgls.fastq"
    elif [[ "${reads}" == *.gz ]]; then
        zcat "${reads}" > reads_input_wgls.fasta
        READS_IN="reads_input_wgls.fasta"
    else
        READS_IN="${reads}"
    fi
    if [[ "\${READS_IN}" == *.fastq || "\${READS_IN}" == *.fq ]]; then
        awk 'NR%4==1 {print ">" substr(\$0,2)} NR%4==2 {print}' "\${READS_IN}" > reads_input_wgls.fasta
        READS_IN="reads_input_wgls.fasta"
    fi
    samtools faidx "\${READS_IN}"

    # Strand/contig/empty-abort/CSI fixes are baked into cresil:1.2.1.
    # CRESIL aborts (exit != 0) for valid empty results. Preserve real
    # crashes instead of turning every nonzero exit into an empty table.
    set +e
    cresil identify_wgls \\
        -t ${task.cpus} \\
        -r ${mmi} \\
        -fa \$FASTA_IN \\
        -fai \$FAI_IN \\
        -fq \$READS_IN \\
        ${trim_arg} \\
        $args > cresil_identify_wgls.log 2>&1
    cresil_status=\$?
    set -e

    if [ \$cresil_status -ne 0 ] && [ ! -f eccDNA_final.txt ] && [ ! -f cresil_result/eccDNA_final.txt ]; then
        if grep -qE '\\[ABORT\\].*(no eccDNA|no (potential )?merge region|zero trimmed region)' cresil_identify_wgls.log; then
            echo "# no eccDNA detected by CRESIL identify_wgls" > ${prefix}.eccDNA_final.txt
            SKIP_MV=1
        else
            cat cresil_identify_wgls.log >&2
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
            echo "CRESIL identify_wgls output not found" >&2 && exit 1
        fi
    fi
    """

    stub:
    prefix = task.ext.prefix ?: "${meta4.id}"
    """
    touch eccDNA_final.txt
    mv eccDNA_final.txt ${prefix}.eccDNA_final.txt
    """
}
