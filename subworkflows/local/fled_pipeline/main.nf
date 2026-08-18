include { FLED } from '../../../modules/local/fled/main'
include { SAMTOOLS_FAIDX } from '../../../modules/nf-core/samtools/faidx/main'

workflow FLED_PIPELINE {
    take:
    reads           // channel: [ val(meta), fastq ]
    genome_fasta    // channel: reference genome file

    main:
    // Build the reference .fai index here so FLED reuses it instead of
    // re-running `samtools faidx` per task. Nextflow's task cache dedupes
    // this against the identical index built by CRESIL_PIPELINE (same input
    // fasta, same get_sizes=false), so it only runs once per pipeline run.
    genome_fasta
        .map { fasta -> [ [id: 'genome'], fasta, [] ] }
        .set { ch_fasta_fai_input }

    SAMTOOLS_FAIDX ( ch_fasta_fai_input, false )
    ch_fai = SAMTOOLS_FAIDX.out.fai

    FLED (
        reads,
        genome_fasta,
        ch_fai.map { meta, fai -> fai }
    )
    ch_versions = FLED.out.versions.mix(SAMTOOLS_FAIDX.out.versions_samtools)

    emit:
    junctions = FLED.out.junctions    // channel: [ val(meta), <prefix>.fled_junctions.txt ]
    versions  = ch_versions
}
