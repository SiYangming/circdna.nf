//
// ORGANELLE_TAG — annotate candidate BED entries with origin=nuclear|pt|mt|ambiguous
//
// Opens only when params.filter_organelle=true AND params.organelle_genome is set.
// Default: tag only (params.drop_organelle_candidates=false) — organelle candidates
// are NOT removed, matching §4.7.
//
// Approach: map the organelle genome (FASTA) to the nuclear reference with minimap2,
// convert to BED, label contigs pt/mt by name, and annotate each candidate via
// bin/tag_organelle_origin.py (overlap-based).
//

include { MINIMAP2_ALIGN as MINIMAP2_ORG } from '../../../modules/nf-core/minimap2/align/main'
include { BEDTOOLS_BAMTOBED } from '../../../modules/nf-core/bedtools/bamtobed/main'

workflow ORGANELLE_TAG {
    take:
    candidates       // channel: [ val(meta), bed ] — unified eccDNA candidate BED
    reference        // channel: [ val(meta), path(fasta) ] — nuclear reference genome

    main:
    ch_versions = channel.empty()

    reference
        .map { meta, fa -> [ meta, fa ] }
        .set { ch_ref_meta }

    // organelle genome FASTA acts as the *query*; mapped onto the nuclear reference
    ch_organelle = channel.fromPath(params.organelle_genome)
        .map { fa -> [[ id: 'organelle' ], fa] }

    MINIMAP2_ORG (
        ch_organelle,
        ch_ref_meta,
        channel.value(true),
        channel.value('bai'),
        channel.value(false),
        channel.value(false)
    )
    ch_versions = ch_versions.mix(MINIMAP2_ORG.out.versions_minimap2)

    BEDTOOLS_BAMTOBED ( MINIMAP2_ORG.out.bam )
    ch_versions = ch_versions.mix(BEDTOOLS_BAMTOBED.out.versions_bedtools)

    ORGANELLE_ORIGIN ( candidates, BEDTOOLS_BAMTOBED.out.bed )
    ch_versions = ch_versions.mix(ORGANELLE_ORIGIN.out.versions)

    emit:
    tagged   = ORGANELLE_ORIGIN.out.tagged   // channel: [ val(meta), bed ] with origin column
    versions = ch_versions
}

process ORGANELLE_ORIGIN {
    tag "$meta.id"
    label 'process_low'

    conda "${projectDir}/modules/local/ecc_finder_slim/environment.yml"
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
