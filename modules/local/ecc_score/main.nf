process ECC_SCORE {
    tag "${meta.id}"
    label 'process_single'

    container "quay.io/biocontainers/python:3.12.12"
    publishDir "${params.outdir}/integrated_mode/ecc_score", mode:'copy', enabled:true

    input:
    tuple val(meta), path(candidates_bed)
    path(gdna_depth_bed)
    path(eccdna_depth_bed)
    val(repeat_bed)
    val(w1)
    val(w2)
    val(w3)

    output:
    tuple val(meta), path("*_scored.bed"), emit: scored_bed
    tuple val("${task.process}"), val('ecc_score'), val('1.0'), emit: versions_score, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def repeat_arg = repeat_bed ? "--repeat-bed ${repeat_bed}" : ""
    """
    echo "ecc_score 1.0" > version.txt

    python ${projectDir}/bin/calculate_ecc_score.py \\
        --candidates "${candidates_bed}" \\
        --eccdna-depth "${eccdna_depth_bed}" \\
        --gdna-depth "${gdna_depth_bed}" \\
        ${repeat_arg} \\
        --output ${prefix}_scored.bed \\
        --w1 ${w1} \\
        --w2 ${w2} \\
        --w3 ${w3}
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_scored.bed
    echo "1.0" > version.txt
    """
}
