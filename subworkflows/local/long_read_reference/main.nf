//
// LONG_READ_REFERENCE — long-read WGS background (gdna)
// LONG_READ_PREPROCESSING → MINIMAP2_ALIGN (preset=read_type) → SAMTOOLS_SORT/INDEX
//   → MOSDEPTH
//
// No eccDNA identifier is ever run on these samples.
// Corresponds to: Oryza PacBio WGS, Amaranthus HiFi WGS, Wheat / Arabidopsis ONT WGS.
//

include { MINIMAP2_ALIGN as MINIMAP2_REFERENCE } from '../../../modules/nf-core/minimap2/align/main'
include { SAMTOOLS_SORT as SAMTOOLS_SORT_REFERENCE } from '../../../modules/nf-core/samtools/sort/main'
include { SAMTOOLS_INDEX as SAMTOOLS_INDEX_REFERENCE } from '../../../modules/nf-core/samtools/index/main'
include { SAMTOOLS_FAIDX } from '../../../modules/nf-core/samtools/faidx/main'
include { MOSDEPTH } from '../../../modules/nf-core/mosdepth/main'

workflow LONG_READ_REFERENCE {
    take:
    reads        // channel: [ val(meta), fastq ] — preprocessed long reads (datatype=gdna)
    fasta        // channel: [ val(meta), path(fasta) ] — reference genome

    main:
    ch_versions = channel.empty()

    fasta
        .map { meta, fa -> [ meta, fa ] }
        .set { ch_fasta_meta }

    // fai for SAMTOOLS_SORT / MOSDEPTH — 由 reads 触发（空输入不建索引）
    def ch_faidx_trigger = reads.map { meta, _fq -> meta }.first()
    SAMTOOLS_FAIDX (
        ch_faidx_trigger
            .combine(ch_fasta_meta)
            .map { _m_trigger, m_fasta, fa -> [ m_fasta, fa, [] ] },
        channel.value(false)
    )
    ch_versions = ch_versions.mix(SAMTOOLS_FAIDX.out.versions_samtools)

    ch_fasta_fai = ch_fasta_meta
        .join(SAMTOOLS_FAIDX.out.fai, by: [0])
        .map { meta, fa, fai -> [ meta, fa, fai ] }

    MINIMAP2_REFERENCE (
        reads,
        ch_fasta_meta,
        channel.value(true),   // bam output
        channel.value('bai'),
        channel.value(false),
        channel.value(false)
    )
    ch_versions = ch_versions.mix(MINIMAP2_REFERENCE.out.versions_minimap2)

    SAMTOOLS_SORT_REFERENCE ( MINIMAP2_REFERENCE.out.bam, ch_fasta_fai, channel.value('bai') )
    ch_versions = ch_versions.mix(SAMTOOLS_SORT_REFERENCE.out.versions_samtools)

    SAMTOOLS_INDEX_REFERENCE ( SAMTOOLS_SORT_REFERENCE.out.bam )
    ch_versions = ch_versions.mix(SAMTOOLS_INDEX_REFERENCE.out.versions_samtools)

    ch_bam_bai = SAMTOOLS_SORT_REFERENCE.out.bam
        .join(SAMTOOLS_INDEX_REFERENCE.out.index, by: [0])
        .map { meta, bam, bai -> [ meta, bam, bai ] }

    MOSDEPTH ( ch_bam_bai, SAMTOOLS_FAIDX.out.fai.map { _meta, fai -> fai }.collect() )
    ch_versions = ch_versions.mix(MOSDEPTH.out.versions_mosdepth)

    emit:
    bam_sorted       = SAMTOOLS_SORT_REFERENCE.out.bam
    bam_sorted_bai   = SAMTOOLS_INDEX_REFERENCE.out.index
    mosdepth_bed     = MOSDEPTH.out.regions_bed
    mosdepth_summary = MOSDEPTH.out.summary
    mosdepth_dist    = MOSDEPTH.out.global_dist
    versions         = ch_versions
}
