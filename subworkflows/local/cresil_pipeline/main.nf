include { CRESIL_TRIM }      from '../../../modules/local/cresil/trim/main'
include { CRESIL_IDENTIFY }  from '../../../modules/local/cresil/identify/main'
include { CRESIL_ANNOTATE }  from '../../../modules/local/cresil/annotate/main'
include { SAMTOOLS_FAIDX }   from '../../../modules/nf-core/samtools/faidx/main'

workflow CRESIL_PIPELINE {
    take:
    reads           // channel: [ val(meta), fastq ]
    genome_fasta    // channel: reference genome file

    main:
    ch_versions = channel.empty()

    genome_fasta
        .map { fasta -> [[id: 'genome'], fasta] }
        .set { genome_fasta_meta }

    // Build .fai index for the reference genome (samtools faidx handles .gz).
    // cresil identify requires the -fai index to compute chromosome sizes.
    genome_fasta_meta
        .map { meta, fasta -> [ meta, fasta, [] ] }
        .set { ch_fasta_fai_input }

    SAMTOOLS_FAIDX ( ch_fasta_fai_input, false )
    ch_versions = ch_versions.mix(SAMTOOLS_FAIDX.out.versions)
    ch_fai = SAMTOOLS_FAIDX.out.fai
        .map { meta, fai -> [ meta, fai ] }

    // Pass the reference genome (gz is fine: mappy and pysam handle it) to
    // cresil trim; the module decompresses gzipped reads to .fastq itself.
    CRESIL_TRIM ( reads, genome_fasta_meta )
        .trim
        .set { trimmed_reads }
    ch_versions = ch_versions.mix(CRESIL_TRIM.out.versions_cresil)

    CRESIL_IDENTIFY ( genome_fasta_meta, ch_fai, reads, trimmed_reads )
        .identify
        .set { eccdna_candidates }
    ch_versions = ch_versions.mix(CRESIL_IDENTIFY.out.versions_cresil)

    CRESIL_ANNOTATE ( eccdna_candidates, channel.empty(), channel.empty(), channel.empty() )
    ch_versions = ch_versions.mix(CRESIL_ANNOTATE.out.versions_cresil)

    emit:
    eccdna_candidates = eccdna_candidates    // channel: [ val(meta), eccdna_final.txt ]
    versions          = ch_versions
}
