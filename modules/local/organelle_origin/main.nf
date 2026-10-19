process ORGANELLE_ORIGIN {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "quay.io/biocontainers/python:3.12.12"

    input:
    tuple val(meta), path(candidates)
    tuple val(meta2), path(organelle_bed)

    output:
    tuple val(meta), path("${prefix}.organelle.bed"), emit: tagged
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # 1) label organelle contigs by name: mito/chloro/plastid keywords
    awk '{
        name = \$4; label = "ambiguous";
        if (name ~ /mito|Mt|MT/) label = "mt";
        else if (name ~ /chloro|pltd|plast|Pt|PT|ChrC/) label = "pt";
        print \$1"\t"\$2"\t"\$3"\t"label
    }' ${organelle_bed} > organelle.labeled.bed

    # 2) annotate candidates with origin
    tag_organelle_origin.py \\
        --candidates ${candidates} \\
        --organelle organelle.labeled.bed \\
        --out ${prefix}.organelle.bed \\
        --min-overlap ${params.organelle_min_overlap}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tag_organelle_origin: 1.0.0
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.organelle.bed
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tag_organelle_origin: 1.0.0
    END_VERSIONS
    """
}
