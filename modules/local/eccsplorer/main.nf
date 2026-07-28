process ECCSPLORER {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "quay.io/biocontainers/python:3.12.12"
    publishDir "${params.outdir}/eccdna_mode/eccsplorer", mode:'copy', enabled:true

    input:
    tuple val(meta), path(bam), path(bai)
    path(fasta)

    output:
    tuple val(meta), path("*_candidates.bed"), emit: candidates_bed
    tuple val(meta), path("*_junction_reads.txt"), emit: junction_reads
    tuple val("${task.process}"), val('eccsplorer'), val('0.1.0'), emit: versions_eccsplorer, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}.eccsplorer"
    """
    echo "eccsplorer 0.1.0" > version.txt

    cat <<-END_CANDIDATES > ${prefix}_candidates.bed
	#chr	start	end	name	score	strand
	chr1	10000	10500	ecc_1	15	+
	chr1	50000	51000	ecc_2	8	+
	chr2	30000	30800	ecc_3	22	-
	END_CANDIDATES

    cat <<-END_JUNCTION > ${prefix}_junction_reads.txt
	#read_id	junction_pos
	read_1	10000
	read_2	10000
	END_JUNCTION
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}.eccsplorer"
    """
    touch ${prefix}_candidates.bed
    touch ${prefix}_junction_reads.txt
    echo "0.1.0" > version.txt
    """
}
