//
// find_circ Pipeline Subworkflow
// Extract unmapped reads → anchors → bowtie2+find_circ → filter to BED6
//

include { SAMTOOLS_VIEW as SAMTOOLS_VIEW_UNMAPPED_FC } from '../../../modules/nf-core/samtools/view/main'
include { BOWTIE2_BUILD                               } from '../../../modules/local/bowtie2/build/main'
include { FIND_CIRC_ANCHORS                           } from '../../../modules/local/find_circ/anchors/main'
include { FIND_CIRC                                   } from '../../../modules/local/find_circ/find_circ/main'
include { FIND_CIRC_FILTER                            } from '../../../modules/local/find_circ/filter/main'

workflow FIND_CIRC_PIPELINE {
    take:
    bam_sorted              // channel: [ val(meta), path(bam) ]
    bam_sorted_bai          // channel: [ val(meta), path(bai) ]
    fasta_fai               // channel (value): [ val(meta), path(fasta), path(fai) ]

    main:
    ch_versions = channel.empty()

    // Extract unmapped reads (SAM flag 4)
    SAMTOOLS_VIEW_UNMAPPED_FC (
        bam_sorted.join(bam_sorted_bai),
        fasta_fai,
        [[id: 'no_qname'], []],
        [[id: 'no_bed'], []],
        []
    )
    ch_versions = ch_versions.mix(SAMTOOLS_VIEW_UNMAPPED_FC.out.versions_samtools)

    FIND_CIRC_ANCHORS (
        SAMTOOLS_VIEW_UNMAPPED_FC.out.bam
    )
    ch_versions = ch_versions.mix(FIND_CIRC_ANCHORS.out.versions)

    // Build Bowtie2 index once from reference fasta
    BOWTIE2_BUILD (
        fasta_fai.map { meta, fasta, _fai -> [meta, fasta] }
    )
    ch_versions = ch_versions.mix(BOWTIE2_BUILD.out.versions)

    // Index is built once from a value-channel fasta; Nextflow broadcasts it to all samples
    FIND_CIRC (
        FIND_CIRC_ANCHORS.out.anchors,
        BOWTIE2_BUILD.out.index,
        fasta_fai.map { _meta, fasta, _fai -> fasta }
    )
    ch_versions = ch_versions.mix(FIND_CIRC.out.versions)

    FIND_CIRC_FILTER (
        FIND_CIRC.out.bed
    )
    ch_versions = ch_versions.mix(FIND_CIRC_FILTER.out.versions)

    emit:
    bed      = FIND_CIRC_FILTER.out.bed
    sites    = FIND_CIRC.out.bed
    versions = ch_versions
}
