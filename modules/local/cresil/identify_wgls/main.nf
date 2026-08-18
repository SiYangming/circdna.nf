process CRESIL_IDENTIFY_WGLS {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/cresil:1.2.0--hdfd78af_0' :
        'quay.io/bioinfortools/cresil:1.2.1' }"

    input:
    tuple val(meta), path(mmi)
    tuple val(meta2), path(fasta)
    tuple val(meta3), path(fai)
    tuple val(meta4), path(reads)
    tuple val(meta5), path(trim)

    output:
    tuple val(meta), path("${prefix}.eccDNA_final.txt"), emit: identify_wgls
    tuple val("${task.process}"), val('cresil'), eval("cresil --version | sed 's/cresil //'"), topic: versions, emit: versions_cresil

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def trim_arg = trim ? "-trim ${trim}" : ''
    """
    # CRESIL determines input types by file extension and does not handle .gz,
    # so decompress gzipped reference/reads to plain files when needed.
    if [[ "${fasta}" == *.gz ]]; then
        zcat "${fasta}" > reference_wgls.fa
        FASTA_IN="reference_wgls.fa"
    else
        FASTA_IN="${fasta}"
    fi
    if [[ "${fai}" == *.gz ]]; then
        zcat "${fai}" > reference_wgls.fa.fai
        FAI_IN="reference_wgls.fa.fai"
    else
        FAI_IN="${fai}"
    fi
    if [[ "${reads}" == *.gz ]]; then
        zcat "${reads}" > reads_input_wgls.fastq
        READS_IN="reads_input_wgls.fastq"
    else
        READS_IN="${reads}"
    fi

    # Patch: identify_wgls compares strand to '+'/'-' but trim.txt stores
    # numeric -1/1 (mappy convention), so the breakpoint split finds 0 reads
    # and genomecov returns empty. Copy the module into a writable dir and
    # shadow it via PYTHONPATH instead of patching read-only site-packages.
    mkdir -p cresil_patch/cresil/cli
    cp \$(python -c "import cresil.cli.identify_wgls as m; print(m.__file__)") cresil_patch/cresil/cli/identify_wgls.py
    sed -i "s/trim_sup\['strand'\] == '+'/trim_sup['strand'] == 1/g; s/trim_sup\['strand'\] == '-'/trim_sup['strand'] == -1/g" cresil_patch/cresil/cli/identify_wgls.py
    export PYTHONPATH=\$PWD/cresil_patch:\$PYTHONPATH

    cresil identify_wgls \\
        -t ${task.cpus} \\
        -r ${mmi} \\
        -fa \$FASTA_IN \\
        -fai \$FAI_IN \\
        -fq \$READS_IN \\
        ${trim_arg} \\
        $args

    # Output lands in the parent dir of the -trim input (here: the workdir).
    # Fall back to cresil_result if the layout differs between CRESIL versions.
    if [ -f eccDNA_final.txt ]; then
        mv eccDNA_final.txt ${prefix}.eccDNA_final.txt
    elif [ -f cresil_result/eccDNA_final.txt ]; then
        mv cresil_result/eccDNA_final.txt ${prefix}.eccDNA_final.txt
    else
        echo "CRESIL identify_wgls output not found" >&2 && exit 1
    fi
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch eccDNA_final.txt
    mv eccDNA_final.txt ${prefix}.eccDNA_final.txt
    """
}
