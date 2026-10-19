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
include { ORGANELLE_ORIGIN } from '../../../modules/local/organelle_origin/main'

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
