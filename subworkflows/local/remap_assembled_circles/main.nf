//
// REMAP_ASSEMBLED_CIRCLES — map assembly outputs without coordinates back to the
// reference and collapse per-query alignments into the unified eccDNA BED contract.
//
// Needed for: TideHunter consensus, ecc_finder asm FASTA, Flye contigs.
// Not needed for: CircleSeeker, CReSIL/FLED BED, CIDER-seq2 monomers, long-read WGS.
//
// MINIMAP2_ALIGN → SAMTOOLS_SORT/INDEX → BEDTOOLS_BAMTOBED → collapse_circle_alignments.py
//

include { MINIMAP2_ALIGN as MINIMAP2_REMAP } from '../../../modules/nf-core/minimap2/align/main'
include { SAMTOOLS_SORT as SAMTOOLS_SORT_REMAP } from '../../../modules/nf-core/samtools/sort/main'
include { SAMTOOLS_INDEX as SAMTOOLS_INDEX_REMAP } from '../../../modules/nf-core/samtools/index/main'
include { SAMTOOLS_FAIDX } from '../../../modules/nf-core/samtools/faidx/main'
include { BEDTOOLS_BAMTOBED } from '../../../modules/nf-core/bedtools/bamtobed/main'

workflow REMAP_ASSEMBLED_CIRCLES {
    take:
    assemblies   // channel: [ val(meta), path(fasta) ] — assembled circular FASTA
    fasta        // channel: [ val(meta), path(fasta) ] — reference genome

    main:
    ch_versions = channel.empty()

    fasta
        .map { meta, fa -> [ meta, fa ] }
        .set { ch_fasta_meta }

    SAMTOOLS_FAIDX ( ch_fasta_meta.map { meta, fa -> [ meta, fa, [] ] }, channel.value(false) )
    ch_versions = ch_versions.mix(SAMTOOLS_FAIDX.out.versions_samtools)

    ch_fasta_fai = ch_fasta_meta
        .join(SAMTOOLS_FAIDX.out.fai, by: [0])
        .map { meta, fa, fai -> [ meta, fa, fai ] }

    MINIMAP2_REMAP (
        assemblies,
        ch_fasta_meta,
        channel.value(true),   // bam output
        channel.value('bai'),
        channel.value(false),
        channel.value(false)
    )
    ch_versions = ch_versions.mix(MINIMAP2_REMAP.out.versions_minimap2)

    SAMTOOLS_SORT_REMAP ( MINIMAP2_REMAP.out.bam, ch_fasta_fai, channel.value('bai') )
    ch_versions = ch_versions.mix(SAMTOOLS_SORT_REMAP.out.versions_samtools)

    SAMTOOLS_INDEX_REMAP ( SAMTOOLS_SORT_REMAP.out.bam )
    ch_versions = ch_versions.mix(SAMTOOLS_INDEX_REMAP.out.versions_samtools)

    BEDTOOLS_BAMTOBED ( SAMTOOLS_SORT_REMAP.out.bam )
    ch_versions = ch_versions.mix(BEDTOOLS_BAMTOBED.out.versions_bedtools)

    COLLAPSE_CIRCLE_ALIGNMENTS ( BEDTOOLS_BAMTOBED.out.bed )
    ch_versions = ch_versions.mix(COLLAPSE_CIRCLE_ALIGNMENTS.out.versions)

    emit:
    bed      = COLLAPSE_CIRCLE_ALIGNMENTS.out.bed   // channel: [ val(meta), *.collapsed.bed ] (BED6+read_count)
    versions = ch_versions
}

process COLLAPSE_CIRCLE_ALIGNMENTS {
    tag "$meta.id"
    label 'process_low'

    conda "${projectDir}/modules/local/ecc_finder_slim/environment.yml"
    container "quay.io/biocontainers/python:3.12.12"

    input:
    tuple val(meta), path(bed)

    output:
    tuple val(meta), path("${prefix}.collapsed.bed"), emit: bed
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    collapse_circle_alignments.py \\
        --bed ${bed} \\
        --out ${prefix}.collapsed.bed \\
        --min-mapq ${params.remap_min_mapq} \\
        --max-gap ${params.remap_max_gap} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        collapse_circle_alignments: 1.0.0
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.collapsed.bed
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        collapse_circle_alignments: 1.0.0
    END_VERSIONS
    """
}
