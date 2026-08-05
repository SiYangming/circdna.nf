process ECCSPLORER {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "quay.io/bioinfortools/eccsplorer:2022.01.1.1"

    input:
    tuple val(meta), path(reads), path(fasta)

    output:
    tuple val(meta), path("*_candidates.bed"), emit: candidates_bed
    tuple val(meta), path("*_junction_reads.txt"), emit: junction_reads
    tuple val(meta), path("*_lowconf_ecc_regions.bed"), emit: lowconf_ecc_regions
    path "*_alignment_stats.txt", emit: alignment_stats
    path "*_ecc_sequences.fasta", emit: ecc_sequences
    path "*_eccpipe_results", emit: eccpipe_results
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: ''
    def reads_list = reads instanceof List ? reads : [reads]
    def is_bam = reads_list[0].toString().toLowerCase().endsWith('.bam')

    if (is_bam) {
        // BAM mode: convert BAM to FASTQ using samtools fastq
        """
        samtools fastq -1 ${prefix}_r1.fq -2 ${prefix}_r2.fq ${reads_list[0]}

        ECCsplorer.py \\
            ${prefix}_r1.fq \\
            ${prefix}_r2.fq \\
            -ref ${fasta} \\
            -out ${prefix}_output \\
            ${args}

        cp ${prefix}_output/eccpipe_results/mapping_results/*_hiconf-ECC-REGIONS.bed ${prefix}_candidates.bed 2>/dev/null || touch ${prefix}_candidates.bed
        cp ${prefix}_output/eccpipe_results/mapping_results/*.trns.txt ${prefix}_junction_reads.txt 2>/dev/null || touch ${prefix}_junction_reads.txt
        cp ${prefix}_output/eccpipe_results/mapping_results/*_lowconf-ECC-regions.bed ${prefix}_lowconf_ecc_regions.bed 2>/dev/null || touch ${prefix}_lowconf_ecc_regions.bed
        cp ${prefix}_output/eccpipe_results/mapping_results/*_alignment-stats.txt ${prefix}_alignment_stats.txt 2>/dev/null || touch ${prefix}_alignment_stats.txt
        cp ${prefix}_output/eccpipe_results/mapping_results/*_ECC-SEQUENCES.fasta ${prefix}_ecc_sequences.fasta 2>/dev/null || touch ${prefix}_ecc_sequences.fasta
        cp -r ${prefix}_output/eccpipe_results ${prefix}_eccpipe_results

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            eccsplorer: "2022.01.1.1"
            samtools: \$(samtools --version | head -n 1 | awk '{print \$2}')
        END_VERSIONS
        """
    } else {
        // FASTQ mode: use reads directly
        def r1 = reads_list[0]
        def r2 = reads_list.size() > 1 ? reads_list[1] : reads_list[0]
        """
        ECCsplorer.py \\
            ${r1} \\
            ${r2} \\
            -ref ${fasta} \\
            -out ${prefix}_output \\
            ${args}

        cp ${prefix}_output/eccpipe_results/mapping_results/*_hiconf-ECC-REGIONS.bed ${prefix}_candidates.bed 2>/dev/null || touch ${prefix}_candidates.bed
        cp ${prefix}_output/eccpipe_results/mapping_results/*.trns.txt ${prefix}_junction_reads.txt 2>/dev/null || touch ${prefix}_junction_reads.txt
        cp ${prefix}_output/eccpipe_results/mapping_results/*_lowconf-ECC-regions.bed ${prefix}_lowconf_ecc_regions.bed 2>/dev/null || touch ${prefix}_lowconf_ecc_regions.bed
        cp ${prefix}_output/eccpipe_results/mapping_results/*_alignment-stats.txt ${prefix}_alignment_stats.txt 2>/dev/null || touch ${prefix}_alignment_stats.txt
        cp ${prefix}_output/eccpipe_results/mapping_results/*_ECC-SEQUENCES.fasta ${prefix}_ecc_sequences.fasta 2>/dev/null || touch ${prefix}_ecc_sequences.fasta
        cp -r ${prefix}_output/eccpipe_results ${prefix}_eccpipe_results

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            eccsplorer: "2022.01.1.1"
        END_VERSIONS
        """
    }

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_candidates.bed
    touch ${prefix}_junction_reads.txt
    touch ${prefix}_lowconf_ecc_regions.bed
    touch ${prefix}_alignment_stats.txt
    touch ${prefix}_ecc_sequences.fasta
    mkdir -p ${prefix}_eccpipe_results
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer: "2022.01.1.1"
    END_VERSIONS
    """
}

process ECCSPLORER_WITH_CONTROL {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "quay.io/bioinfortools/eccsplorer:2022.01.1.1"

    input:
    tuple val(meta), path(reads), path(control_r1), path(control_r2), path(fasta)

    output:
    tuple val(meta), path("*_candidates.bed"), emit: candidates_bed
    tuple val(meta), path("*_junction_reads.txt"), emit: junction_reads
    tuple val(meta), path("*_lowconf_ecc_regions.bed"), emit: lowconf_ecc_regions
    path "*_alignment_stats.txt", emit: alignment_stats
    path "*_ecc_sequences.fasta", emit: ecc_sequences
    path "*_eccpipe_results", emit: eccpipe_results
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: ''
    def reads_list = reads instanceof List ? reads : [reads]
    def is_bam = reads_list[0].toString().toLowerCase().endsWith('.bam')

    if (is_bam) {
        // BAM mode: convert BAM to FASTQ using samtools fastq
        """
        samtools fastq -1 ${prefix}_r1.fq -2 ${prefix}_r2.fq ${reads_list[0]}

        ECCsplorer.py \\
            ${prefix}_r1.fq \\
            ${prefix}_r2.fq \\
            ${control_r1} \\
            ${control_r2} \\
            -ref ${fasta} \\
            -out ${prefix}_output \\
            ${args} || true

        cp ${prefix}_output/eccpipe_results/mapping_results/*_hiconf-ECC-REGIONS.bed ${prefix}_candidates.bed 2>/dev/null || touch ${prefix}_candidates.bed
        cp ${prefix}_output/eccpipe_results/mapping_results/TR.trns.txt ${prefix}_junction_reads.txt 2>/dev/null || touch ${prefix}_junction_reads.txt
        cp ${prefix}_output/eccpipe_results/mapping_results/*_lowconf-ECC-regions.bed ${prefix}_lowconf_ecc_regions.bed 2>/dev/null || touch ${prefix}_lowconf_ecc_regions.bed
        cp ${prefix}_output/eccpipe_results/mapping_results/TR_alignment-stats.txt ${prefix}_alignment_stats.txt 2>/dev/null || touch ${prefix}_alignment_stats.txt
        cp ${prefix}_output/eccpipe_results/mapping_results/*_ECC-SEQUENCES.fasta ${prefix}_ecc_sequences.fasta 2>/dev/null || touch ${prefix}_ecc_sequences.fasta
        cp -r ${prefix}_output/eccpipe_results ${prefix}_eccpipe_results

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            eccsplorer: "2022.01.1.1"
            samtools: \$(samtools --version | head -n 1 | awk '{print \$2}')
        END_VERSIONS
        """
    } else {
        // FASTQ mode: use reads directly
        def r1 = reads_list[0]
        def r2 = reads_list.size() > 1 ? reads_list[1] : reads_list[0]
        """
        ECCsplorer.py \\
            ${r1} \\
            ${r2} \\
            ${control_r1} \\
            ${control_r2} \\
            -ref ${fasta} \\
            -out ${prefix}_output \\
            ${args} || true

        cp ${prefix}_output/eccpipe_results/mapping_results/*_hiconf-ECC-REGIONS.bed ${prefix}_candidates.bed 2>/dev/null || touch ${prefix}_candidates.bed
        cp ${prefix}_output/eccpipe_results/mapping_results/TR.trns.txt ${prefix}_junction_reads.txt 2>/dev/null || touch ${prefix}_junction_reads.txt
        cp ${prefix}_output/eccpipe_results/mapping_results/*_lowconf-ECC-regions.bed ${prefix}_lowconf_ecc_regions.bed 2>/dev/null || touch ${prefix}_lowconf_ecc_regions.bed
        cp ${prefix}_output/eccpipe_results/mapping_results/TR_alignment-stats.txt ${prefix}_alignment_stats.txt 2>/dev/null || touch ${prefix}_alignment_stats.txt
        cp ${prefix}_output/eccpipe_results/mapping_results/*_ECC-SEQUENCES.fasta ${prefix}_ecc_sequences.fasta 2>/dev/null || touch ${prefix}_ecc_sequences.fasta
        cp -r ${prefix}_output/eccpipe_results ${prefix}_eccpipe_results

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            eccsplorer: "2022.01.1.1"
        END_VERSIONS
        """
    }

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_candidates.bed
    touch ${prefix}_junction_reads.txt
    touch ${prefix}_lowconf_ecc_regions.bed
    touch ${prefix}_alignment_stats.txt
    touch ${prefix}_ecc_sequences.fasta
    mkdir -p ${prefix}_eccpipe_results
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer: "2022.01.1.1"
    END_VERSIONS
    """
}
